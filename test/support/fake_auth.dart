import 'dart:async';

import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/auth/web_auth_service.dart';
import 'package:mambatv/data/services/local/local_stores.dart';
import 'package:mambatv/domain/auth/auth.dart';
import 'package:mambatv/domain/entities/app_models.dart';

class MemoryCredentialStore implements CredentialStore {
  final values = <String, String>{};
  bool failRead = false, failWrite = false, failDelete = false;
  Completer<void>? writeGate;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('synthetic storage failure');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await writeGate?.future;
    if (failWrite) throw StateError('synthetic storage failure');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('synthetic storage failure');
    values.remove(key);
  }
}

WebCredential syntheticCredential([String tag = 'A']) => WebCredential({
  'SESSDATA': 'synthetic-$tag',
  'bili_jct': 'synthetic-csrf',
  'DedeUserID': tag == 'B' ? '202' : '101',
}, refreshToken: 'synthetic-refresh-$tag');

class FakeAuthGateway implements AuthGateway {
  int creates = 0,
      polls = 0,
      verifies = 0,
      infos = 0,
      refreshes = 0,
      confirms = 0,
      logouts = 0;
  bool refreshRequired = false;
  AppFailure? verifyFailure, confirmFailure;
  Completer<void>? verifyGate, refreshGate, pollGate;
  QrPollStatus pollStatus = QrPollStatus.waiting;
  WebCredential credential = syntheticCredential();
  void Function()? onConfirm;
  Duration lifetime = const Duration(seconds: 180);
  @override
  Future<QrChallenge> create(CancellationSignal signal) async {
    creates++;
    return QrChallenge(
      key: 'synthetic-$creates',
      url: 'https://example.invalid/synthetic-qr-$creates',
      expiresAt: DateTime.now().add(lifetime),
    );
  }

  @override
  Future<WebQrPoll> poll(
    QrChallenge challenge,
    CancellationSignal signal,
  ) async {
    polls++;
    await pollGate?.future;
    return WebQrPoll(
      pollStatus,
      pollStatus == QrPollStatus.completed ? credential : null,
    );
  }

  @override
  Future<VerifiedAccount> verify(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    verifies++;
    await verifyGate?.future;
    if (verifyFailure case final AppFailure error) throw error;
    final uid = int.parse(credential.cookies['DedeUserID']!);
    return VerifiedAccount(uid, '合成验收账号 $uid');
  }

  @override
  Future<bool> needsRefresh(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    infos++;
    return refreshRequired;
  }

  @override
  Future<WebCredential> refresh(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    refreshes++;
    await refreshGate?.future;
    refreshRequired = false;
    return WebCredential({
      ...credential.cookies,
      'SESSDATA': 'synthetic-rotated',
    }, refreshToken: 'synthetic-refresh-new');
  }

  @override
  Future<void> confirmRefresh(
    WebCredential credential,
    String oldToken,
    CancellationSignal signal,
  ) async {
    confirms++;
    onConfirm?.call();
    if (confirmFailure case final AppFailure error) throw error;
  }

  @override
  Future<void> logout(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    logouts++;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.sessions);
  final MemorySessionRepository sessions;
  int creates = 0, polls = 0, activePolls = 0, maximumPolls = 0;
  QrPollStatus status = QrPollStatus.waiting;
  Duration lifetime = const Duration(seconds: 180);
  Completer<void>? gate;
  CancellationSignal? lastSignal;
  AppFailure? failure;
  @override
  Future<Result<QrChallenge>> create(CancellationSignal signal) async =>
      Success(
        QrChallenge(
          key: 'synthetic-${++creates}',
          url: 'https://example.invalid/synthetic-qr',
          expiresAt: DateTime.now().add(lifetime),
        ),
      );
  @override
  Future<Result<QrPollStatus>> poll(
    QrChallenge challenge,
    CancellationSignal signal,
  ) async {
    polls++;
    activePolls++;
    lastSignal = signal;
    if (activePolls > maximumPolls) maximumPolls = activePolls;
    try {
      await gate?.future;
      if (failure case final AppFailure error) return ResultFailure(error);
      if (status == QrPollStatus.completed && !signal.isCancelled) {
        sessions.replace(
          Session(
            ownerKey: 'user:101',
            displayName: '合成验收账号',
            status: SessionStatus.authenticated,
            generation: sessions.current.generation + 1,
          ),
        );
      }
      return Success(status);
    } finally {
      activePolls--;
    }
  }
}
