import 'dart:async';
import 'dart:convert';

import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';
import '../services/auth/web_auth_service.dart';
import '../services/auth/request_identity.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import '../services/local/local_stores.dart';

final class SavedSession {
  const SavedSession(
    this.credential,
    this.ownerKey,
    this.name, {
    this.pendingOldToken,
  });
  final WebCredential credential;
  final String ownerKey, name;
  final String? pendingOldToken;
  String encode() => jsonEncode({
    'version': 1,
    'cookies': credential.cookies,
    'refreshToken': credential.refreshToken,
    'owner': ownerKey,
    'name': name,
    'pendingOldToken': pendingOldToken,
  });
  static SavedSession decode(String text) {
    final json = jsonObject(jsonDecode(text));
    if (json['version'] != 1) throw const FormatException('Credential version');
    return SavedSession(
      WebCredential(
        jsonObject(json['cookies']).map((k, v) => MapEntry(k, v! as String)),
        refreshToken: json['refreshToken'] as String?,
      ),
      json['owner']! as String,
      json['name']! as String,
      pendingOldToken: json['pendingOldToken'] as String?,
    );
  }

  @override
  String toString() => 'SavedSession(redacted)';
}

class PersistentSessionRepository implements SessionRepository {
  PersistentSessionRepository(this.gateway, this.secure, this.preferences);
  static const credentialKey = 'auth.web.session.v1';
  static const blockedKey = 'auth.web.blocked.v1';
  final AuthGateway gateway;
  final CredentialStore secure;
  final PreferencesStore preferences;
  final _events = StreamController<Session>.broadcast(sync: true);
  Session _current = const Session(status: SessionStatus.restoring);
  SavedSession? _saved;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();
  Future<void>? _validation;
  int? _validationRevision;
  CancellationSignal? _validationSignal;
  DateTime? _checkedAt, _automaticAt;
  int? _automaticGeneration;
  @override
  Session get current => _current;
  int get revision => _revision;
  RequestIdentity capture() =>
      RequestIdentity(_current, _saved?.credential.header);

  @override
  Stream<Session> watch() => Stream<Session>.multi((controller) {
    final subscription = _events.stream.listen(
      controller.addSync,
      onError: controller.addErrorSync,
      onDone: controller.closeSync,
    );
    controller.addSync(_current);
    controller.onCancel = subscription.cancel;
  });

  void _publish(Session next, {bool newCredential = false}) {
    if (_disposed) return;
    if (!newCredential &&
        next.ownerKey == _current.ownerKey &&
        next.status == _current.status &&
        next.displayName == _current.displayName &&
        next.notice == _current.notice) {
      return;
    }
    _current = next.copyWith(generation: _current.generation + 1);
    _events.add(_current);
  }

  void _check(int revision, CancellationSignal signal) {
    if (_disposed || signal.isCancelled || revision != _revision) {
      throw const AppFailure(FailureKind.cancelled, '操作已取消');
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<T> _storage<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (_) {
      throw const AppFailure(FailureKind.storage, '安全存储暂不可用，请重试');
    }
  }

  Future<void> _commit(
    SavedSession value,
    int epoch,
    CancellationSignal signal,
  ) => _serialize(() async {
    _check(epoch, signal);
    // Public tombstone contains no credential. It also prevents resurrecting a
    // session after failed secure deletion or an interrupted credential write.
    await _storage(() => preferences.write(blockedKey, 'true'));
    await _storage(() => secure.write(credentialKey, value.encode()));
    if (_disposed || epoch != _revision || signal.isCancelled) {
      await secure.delete(credentialKey);
      _check(epoch, signal);
    }
    await _storage(() => preferences.write(blockedKey, 'false'));
    if (_disposed || epoch != _revision || signal.isCancelled) {
      await preferences.write(blockedKey, 'true');
      await secure.delete(credentialKey);
      _check(epoch, signal);
    }
    _saved = value;
  });
  Future<void> _clear(int epoch) => _serialize(() async {
    if (epoch != _revision) return;
    await preferences.write(blockedKey, 'true');
    await secure.delete(credentialKey);
  });

  @override
  Future<void> restore() => revalidate(force: true);
  @override
  Future<void> revalidate({bool force = false}) {
    if (_validation != null && _validationRevision == _revision) {
      return _validation!;
    }
    if (!force &&
        _checkedAt != null &&
        DateTime.now().difference(_checkedAt!) < const Duration(minutes: 5)) {
      return Future<void>.value();
    }
    final epoch = _revision;
    _validationSignal?.cancel();
    final signal = _validationSignal = CancellationSignal();
    _validationRevision = epoch;
    late final Future<void> operation;
    operation = _validate(epoch, signal).whenComplete(() {
      if (identical(_validation, operation)) _validation = null;
    });
    return _validation = operation;
  }

  Future<void> authenticationFailed(int generation) {
    if (!_current.isAuthenticated || generation != _current.generation) {
      return Future<void>.value();
    }
    if (_automaticGeneration == generation &&
        _automaticAt != null &&
        DateTime.now().difference(_automaticAt!) <
            const Duration(seconds: 30)) {
      return _validation ?? Future<void>.value();
    }
    _automaticGeneration = generation;
    _automaticAt = DateTime.now();
    return revalidate(force: true);
  }

  Future<void> _validate(int epoch, CancellationSignal signal) async {
    try {
      if (_saved == null) {
        if (await _storage(() => preferences.read(blockedKey)) == 'true') {
          _check(epoch, signal);
          await _clear(epoch);
          _publish(const Session());
          return;
        }
        final raw = await _storage(() => secure.read(credentialKey));
        _check(epoch, signal);
        if (raw == null) {
          _publish(const Session());
          return;
        }
        _saved = SavedSession.decode(raw);
      }
      var saved = _saved!;
      var rotated = false;
      if (saved.pendingOldToken != null) {
        await gateway.confirmRefresh(
          saved.credential,
          saved.pendingOldToken!,
          signal,
        );
        saved = SavedSession(saved.credential, saved.ownerKey, saved.name);
        await _commit(saved, epoch, signal);
        rotated = true;
      }
      if (await gateway.needsRefresh(saved.credential, signal)) {
        final credential = await gateway.refresh(saved.credential, signal);
        final verified = await gateway.verify(credential, signal);
        if (verified.ownerKey != saved.ownerKey) {
          throw const AppFailure(FailureKind.authentication, '账号校验不一致，请重新扫码');
        }
        final pending = SavedSession(
          credential,
          verified.ownerKey,
          verified.name,
          pendingOldToken: saved.credential.refreshToken,
        );
        await _commit(pending, epoch, signal);
        await gateway.confirmRefresh(
          credential,
          saved.credential.refreshToken!,
          signal,
        );
        saved = SavedSession(credential, verified.ownerKey, verified.name);
        await _commit(saved, epoch, signal);
        rotated = true;
      }
      final verified = await gateway.verify(saved.credential, signal);
      _check(epoch, signal);
      if (verified.ownerKey != saved.ownerKey) {
        throw const AppFailure(FailureKind.authentication, '账号校验不一致，请重新扫码');
      }
      _checkedAt = DateTime.now();
      _publish(
        Session(
          ownerKey: verified.ownerKey,
          displayName: verified.name,
          status: SessionStatus.authenticated,
        ),
        newCredential: rotated,
      );
    } catch (error) {
      if (_disposed || epoch != _revision || signal.isCancelled) return;
      final failure = safeApiFailure(error);
      if (failure.kind == FailureKind.authentication ||
          failure.kind == FailureKind.contract) {
        _saved = null;
        _revision++;
        _publish(Session(status: SessionStatus.expired, notice: '登录已失效，请重新扫码'));
        try {
          await _clear(_revision);
        } catch (_) {
          _publish(
            const Session(
              status: SessionStatus.storageFailure,
              notice: '凭据清理未完成，请重试退出',
            ),
          );
        }
      } else if (failure.kind == FailureKind.network ||
          failure.kind == FailureKind.timeout ||
          failure.kind == FailureKind.rateLimited ||
          failure.kind == FailureKind.permission ||
          failure.kind == FailureKind.unavailable) {
        _publish(
          Session(
            ownerKey: _saved?.ownerKey ?? 'guest',
            displayName: _saved?.name,
            status: SessionStatus.offline,
            notice:
                failure.kind == FailureKind.network ||
                    failure.kind == FailureKind.timeout
                ? '网络暂不可用，账号已保留；可游客浏览或重新校验'
                : '账号服务暂不可用，凭据已保留；请稍后重新校验',
          ),
        );
      } else {
        _publish(
          const Session(
            status: SessionStatus.storageFailure,
            notice: '安全存储暂不可用，请重试或退出本机账号',
          ),
        );
      }
    }
  }

  Future<void> signIn(
    WebCredential credential,
    int expectedRevision,
    CancellationSignal signal,
  ) async {
    _check(expectedRevision, signal);
    final verified = await gateway.verify(credential, signal);
    _check(expectedRevision, signal);
    try {
      await _commit(
        SavedSession(credential, verified.ownerKey, verified.name),
        expectedRevision,
        signal,
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.storage, '安全存储失败，未保存登录；请修复后重新扫码');
    }
    _check(expectedRevision, signal);
    _revision++;
    _checkedAt = DateTime.now();
    _publish(
      Session(
        ownerKey: verified.ownerKey,
        displayName: verified.name,
        status: SessionStatus.authenticated,
      ),
      newCredential: true,
    );
  }

  @override
  Future<Result<void>> logout() async {
    final previous = _saved;
    final epoch = ++_revision;
    _validationSignal?.cancel();
    _saved = null;
    _publish(const Session(), newCredential: true);
    try {
      await _clear(epoch);
    } catch (_) {
      if (epoch == _revision) {
        _publish(
          const Session(
            status: SessionStatus.storageFailure,
            notice: '本机凭据清理未完成，请重试退出',
          ),
        );
      }
      return const ResultFailure(
        AppFailure(FailureKind.storage, '本机凭据清理未完成，请重试退出'),
      );
    }
    if (previous != null) {
      try {
        await gateway.logout(previous.credential, CancellationSignal());
      } catch (_) {
        if (epoch == _revision) {
          _publish(const Session(notice: '本机已退出；服务端退出未确认'));
        }
      }
    }
    return const Success(null);
  }

  Future<void> dispose() async {
    _disposed = true;
    _revision++;
    _validationSignal?.cancel();
    await _writes;
    await _events.close();
  }
}
