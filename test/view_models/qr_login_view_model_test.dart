import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/auth_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/auth/auth.dart';
import 'package:mambatv/ui/features/auth/view_models/qr_login_view_model.dart';

import '../support/fake_auth.dart';

Future<void> waitForAuth(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

void main() {
  late ProviderContainer container;
  late MemorySessionRepository sessions;
  late FakeAuthRepository auth;
  final provider = qrLoginViewModelProvider(pageId: 'login');
  setUp(() {
    sessions = MemorySessionRepository();
    auth = FakeAuthRepository(sessions);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        qrTimingProvider.overrideWithValue(
          const QrTiming(
            pollInterval: Duration(milliseconds: 10),
            tickInterval: Duration(milliseconds: 5),
          ),
        ),
      ],
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(() async {
      subscription.close();
      await container.pump();
      await sessions.close();
    });
  });
  test(
    'creation is explicit and disposal cancels the polling attempt',
    () async {
      expect(container.read(provider).phase, QrPhase.idle);
      expect(auth.creates, 0);
      await container.read(provider.notifier).start();
      expect(auth.creates, 1);
      expect(auth.maximumPolls, 1);
      container.invalidate(provider);
      await container.pump();
      expect(auth.lastSignal?.isCancelled, isTrue);
      expect(container.read(provider).phase, QrPhase.idle);
    },
  );
  test(
    'refresh cannot overlap polls or accept the canceled challenge',
    () async {
      auth.gate = Completer<void>();
      auth.status = QrPollStatus.completed;
      final vm = container.read(provider.notifier);
      final old = vm.start();
      await waitForAuth(() => auth.polls == 1);
      await vm.start();
      expect(auth.creates, 2);
      expect(auth.maximumPolls, 1);
      expect(sessions.current.isAuthenticated, isFalse);
      auth.gate!.complete();
      await old;
      await waitForAuth(
        () => container.read(provider).phase == QrPhase.completed,
      );
      expect(auth.maximumPolls, 1);
      expect(container.read(provider).effectId, 2);
    },
  );
  test('canceling discards a late successful poll', () async {
    auth.gate = Completer<void>();
    auth.status = QrPollStatus.completed;
    final vm = container.read(provider.notifier);
    final opening = vm.start();
    await waitForAuth(() => auth.polls == 1);
    vm.cancel();
    auth.gate!.complete();
    await opening;
    expect(container.read(provider).phase, QrPhase.idle);
    expect(sessions.current.isAuthenticated, isFalse);
  });
  test('background cancels and foreground creates a fresh challenge', () async {
    final vm = container.read(provider.notifier);
    await vm.start();
    vm.pause();
    final polls = auth.polls;
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(auth.polls, polls);
    expect(auth.lastSignal?.isCancelled, isTrue);
    await vm.resume();
    expect(auth.creates, 2);
    vm.cancel();
  });
  test('expired challenge is removed and requires explicit refresh', () async {
    auth.lifetime = const Duration(milliseconds: 45);
    await container.read(provider.notifier).start();
    await waitForAuth(() => container.read(provider).phase == QrPhase.expired);
    final count = auth.polls;
    expect(container.read(provider).challenge, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(auth.polls, count);
  });
  test(
    'network backoff is bounded and does not become an endless retry loop',
    () async {
      auth.failure = const AppFailure(FailureKind.timeout, '合成超时');
      await container.read(provider.notifier).start();
      await waitForAuth(() => container.read(provider).phase == QrPhase.failed);
      expect(auth.polls, 3);
      expect(auth.maximumPolls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(auth.polls, 3);
    },
  );
  test('return paths reject external URLs and never auto-open a player', () {
    expect(safeLoginReturn('https://example.invalid'), '/library');
    expect(safeLoginReturn('//example.invalid'), '/library');
    expect(safeLoginReturn('/home?credential=synthetic'), '/library');
    expect(safeLoginReturn('/player/BVsynthetic'), '/video/BVsynthetic');
    expect(safeLoginReturn('/settings'), '/settings');
  });
}
