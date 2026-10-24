import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/m0/data/bilibili_probe_service.dart';
import 'package:mambatv/m0/domain/probe_models.dart';
import 'package:mambatv/m0/ui/probe_view_model.dart';

class ControlledService extends BilibiliProbeService {
  final challenge = Completer<QrChallenge>();
  final guest = Completer<List<ProbeCheck>>();
  CancelToken? challengeToken;
  int polls = 0;
  int guestCalls = 0;

  @override
  Future<QrChallenge> createQr(CancelToken token) {
    challengeToken = token;
    return challenge.future;
  }

  @override
  Future<QrPoll> pollQr(QrChallenge challenge, CancelToken token) async {
    polls++;
    return const QrPoll(86101);
  }

  @override
  Future<List<ProbeCheck>> probeGuest({CancelToken? cancelToken}) {
    guestCalls++;
    return guest.future;
  }
}

void main() {
  test(
    'cancellation clears loading and discards a late guest response',
    () async {
      final service = ControlledService();
      final container = ProviderContainer.test(
        overrides: [probeServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(service.close);
      final subscription = container.listen(probeViewModelProvider, (_, _) {});
      addTearDown(subscription.close);
      final vm = container.read(probeViewModelProvider.notifier);
      final pending = vm.runGuest();
      vm.cancelQr();
      expect(container.read(probeViewModelProvider).busy, isFalse);
      service.guest.complete(const [
        ProbeCheck(capability: 'late', passed: true, detail: 'synthetic'),
      ]);
      await pending;
      expect(container.read(probeViewModelProvider).checks, isEmpty);
    },
  );

  test(
    'page keeps its service alive while a command is awaiting network',
    () async {
      final service = ControlledService();
      var disposed = false;
      final container = ProviderContainer.test(
        overrides: [
          probeServiceProvider.overrideWith((ref) {
            ref.onDispose(() => disposed = true);
            return service;
          }),
        ],
      );
      addTearDown(service.close);
      final subscription = container.listen(probeViewModelProvider, (_, _) {});
      final pending = container
          .read(probeViewModelProvider.notifier)
          .runGuest();
      await container.pump();
      expect(disposed, isFalse);
      service.guest.complete(const []);
      await pending;
      subscription.close();
      await container.pump();
      expect(disposed, isTrue);
    },
  );

  test(
    'cancelled QR challenge cannot publish a late QR or start polling',
    () async {
      final service = ControlledService();
      final container = ProviderContainer.test(
        overrides: [probeServiceProvider.overrideWith((ref) => service)],
      );
      final subscription = container.listen(probeViewModelProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(service.close);
      final vm = container.read(probeViewModelProvider.notifier);
      final pending = vm.startQr();
      vm.cancelQr();
      service.challenge.complete(
        const QrChallenge('synthetic', 'https://example.invalid/qr'),
      );
      await pending;
      expect(service.challengeToken!.isCancelled, isTrue);
      expect(service.polls, 0);
      expect(container.read(probeViewModelProvider).qrUrl, isNull);
      expect(container.read(probeViewModelProvider).polling, isFalse);
    },
  );

  test('disposing page provider cancels an in-flight QR challenge', () async {
    final service = ControlledService();
    final container = ProviderContainer.test(
      overrides: [probeServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(service.close);
    final subscription = container.listen(probeViewModelProvider, (_, _) {});
    final pending = container.read(probeViewModelProvider.notifier).startQr();
    subscription.close();
    await container.pump();
    expect(service.challengeToken!.isCancelled, isTrue);
    service.challenge.complete(
      const QrChallenge('synthetic', 'https://example.invalid/qr'),
    );
    await pending;
    expect(service.polls, 0);
  });

  test('repeated guest command does not overlap network runs', () async {
    final service = ControlledService();
    final container = ProviderContainer.test(
      overrides: [probeServiceProvider.overrideWith((ref) => service)],
    );
    final subscription = container.listen(probeViewModelProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(service.close);
    final vm = container.read(probeViewModelProvider.notifier);
    final pending = vm.runGuest();
    await vm.runGuest();
    expect(service.guestCalls, 1);
    service.guest.complete(const [
      ProbeCheck(capability: 'fixture', passed: true, detail: 'synthetic'),
    ]);
    await pending;
    expect(container.read(probeViewModelProvider).busy, isFalse);
    expect(container.read(probeViewModelProvider).checks, hasLength(1));
  });
}
