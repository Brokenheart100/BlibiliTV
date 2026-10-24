import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/persistent_session_repository.dart';
import 'package:mambatv/data/repositories/web_auth_repository.dart';
import 'package:mambatv/domain/auth/auth.dart';
import 'package:mambatv/domain/entities/app_models.dart';

import '../support/fake_auth.dart';
import '../support/memory_preferences.dart';

void main() {
  late FakeAuthGateway gateway;
  late MemoryCredentialStore secure;
  late MemoryPreferencesStore preferences;
  late PersistentSessionRepository sessions;
  setUp(() {
    gateway = FakeAuthGateway();
    secure = MemoryCredentialStore();
    preferences = MemoryPreferencesStore();
    sessions = PersistentSessionRepository(gateway, secure, preferences);
    addTearDown(sessions.dispose);
  });
  Future<void> signIn() => sessions.signIn(
    syntheticCredential(),
    sessions.revision,
    CancellationSignal(),
  );

  test('QR completion validates, persists securely, and restores in a new repository', () async {
    await sessions.restore();
    final auth = WebAuthRepository(gateway, sessions);
    final signal = CancellationSignal();
    final challenge = (await auth.create(signal)).valueOrThrow;
    gateway.pollStatus = QrPollStatus.completed;
    expect(
      (await auth.poll(challenge, signal)).valueOrThrow,
      QrPollStatus.completed,
    );
    expect(sessions.current.isAuthenticated, isTrue);
    expect(preferences.values.values.join(), isNot(contains('synthetic-A')));
    final next = PersistentSessionRepository(gateway, secure, preferences);
    addTearDown(next.dispose);
    await next.restore();
    expect(next.current.ownerKey, 'user:101');
    expect(next.current.isAuthenticated, isTrue);
    expect(next.capture().toString(), isNot(contains('synthetic-A')));
    expect(challenge.toString(), isNot(contains(challenge.key)));
  });

  test('storage failure cannot publish a successful login', () async {
    secure.failWrite = true;
    final auth = WebAuthRepository(gateway, sessions);
    final signal = CancellationSignal();
    final challenge = (await auth.create(signal)).valueOrThrow;
    gateway.pollStatus = QrPollStatus.completed;
    final result = await auth.poll(challenge, signal);
    expect(
      (result as ResultFailure<QrPollStatus>).failure.kind,
      FailureKind.storage,
    );
    expect(sessions.current.isAuthenticated, isFalse);
    expect(preferences.values[PersistentSessionRepository.blockedKey], 'true');
  });

  test(
    'late restoration after logout cannot resurrect the old account',
    () async {
      await signIn();
      final next = PersistentSessionRepository(gateway, secure, preferences);
      addTearDown(next.dispose);
      gateway.verifyGate = Completer<void>();
      final restoring = next.restore();
      while (gateway.verifies < 2) {
        await Future<void>.delayed(Duration.zero);
      }
      await next.logout();
      gateway.verifyGate!.complete();
      await restoring;
      expect(next.current.isAuthenticated, isFalse);
      expect(secure.values, isEmpty);
    },
  );

  test('logout during a secure write rolls the late credential back', () async {
    secure.writeGate = Completer<void>();
    final signing = signIn();
    await Future<void>.delayed(Duration.zero);
    final expectation = expectLater(signing, throwsA(isA<AppFailure>()));
    final logout = sessions.logout();
    secure.writeGate!.complete();
    await expectation;
    await logout;
    expect(sessions.current.isAuthenticated, isFalse);
    expect(secure.values, isEmpty);
    expect(preferences.values[PersistentSessionRepository.blockedKey], 'true');
  });

  test(
    'failed secure deletion leaves a durable no-restore tombstone',
    () async {
      await signIn();
      secure.failDelete = true;
      await sessions.logout();
      final verifies = gateway.verifies;
      final next = PersistentSessionRepository(gateway, secure, preferences);
      addTearDown(next.dispose);
      await next.restore();
      expect(next.current.isAuthenticated, isFalse);
      expect(next.current.status, SessionStatus.storageFailure);
      expect(gateway.verifies, verifies);
      secure.failDelete = false;
      await next.logout();
      expect(secure.values, isEmpty);
    },
  );

  test(
    'timeout preserves credentials; explicit revalidation can recover',
    () async {
      await signIn();
      gateway.verifyFailure = const AppFailure(FailureKind.timeout, '合成超时');
      await sessions.revalidate(force: true);
      expect(sessions.current.status, SessionStatus.offline);
      expect(secure.values, isNotEmpty);
      expect(sessions.capture().cookie, isNull);
      gateway.verifyFailure = null;
      await sessions.revalidate(force: true);
      expect(sessions.current.isAuthenticated, isTrue);
    },
  );

  test(
    'invalid session becomes expired instead of silently retaining auth',
    () async {
      await signIn();
      gateway.verifyFailure = const AppFailure(
        FailureKind.authentication,
        '合成失效',
      );
      await sessions.revalidate(force: true);
      expect(sessions.current.status, SessionStatus.expired);
      expect(secure.values, isEmpty);
    },
  );

  test('concurrent failures rotate once and persist before confirming the old token', () async {
    await signIn();
    final generation = sessions.current.generation;
    gateway.refreshRequired = true;
    gateway.refreshGate = Completer<void>();
    gateway.onConfirm = () {
      final saved = SavedSession.decode(
        secure.values[PersistentSessionRepository.credentialKey]!,
      );
      expect(saved.credential.cookies['SESSDATA'], 'synthetic-rotated');
      expect(saved.pendingOldToken, 'synthetic-refresh-A');
    };
    final operations = List.generate(
      10,
      (_) => sessions.authenticationFailed(generation),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.refreshes, 1);
    gateway.refreshGate!.complete();
    await Future.wait(operations);
    expect(gateway.refreshes, 1);
    expect(gateway.confirms, 1);
    expect(sessions.current.generation, greaterThan(generation));
    expect(sessions.current.isAuthenticated, isTrue);
  });

  test(
    'failed refresh confirmation is recovered without rotating twice',
    () async {
      await signIn();
      gateway.refreshRequired = true;
      gateway.confirmFailure = const AppFailure(FailureKind.network, '合成网络故障');
      await sessions.revalidate(force: true);
      expect(sessions.current.status, SessionStatus.offline);
      expect(
        SavedSession.decode(
          secure.values[PersistentSessionRepository.credentialKey]!,
        ).pendingOldToken,
        isNotNull,
      );
      gateway.confirmFailure = null;
      await sessions.revalidate(force: true);
      expect(sessions.current.isAuthenticated, isTrue);
      expect(gateway.refreshes, 1);
    },
  );

  test(
    'secure read failure exposes storage recovery, not invalid-account logout',
    () async {
      secure.failRead = true;
      await sessions.restore();
      expect(sessions.current.status, SessionStatus.storageFailure);
      expect(preferences.values, isEmpty);
    },
  );
}
