import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

import '../support/fake_playback.dart';
import '../support/memory_preferences.dart';

void main() {
  late ProviderContainer container;
  late FakeEngineFactory factory;
  late FakePlaybackRepository resolver;
  late MemoryProgressRepository progress;
  final provider = playerViewModelProvider(pageId: 'player', ownerKey: 'guest');
  setUp(() {
    factory = FakeEngineFactory();
    resolver = FakePlaybackRepository();
    progress = MemoryProgressRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        playbackAdapterProvider.overrideWithValue(factory.adapter),
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(latency: Duration.zero),
        ),
        playbackRepositoryProvider.overrideWithValue(resolver),
        progressRepositoryProvider.overrideWithValue(progress),
        settingsRepositoryProvider.overrideWithValue(
          LocalSettingsRepository(MemoryPreferencesStore()),
        ),
      ],
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
  });

  test(
    'provider creation and invalidation never implicitly open media',
    () async {
      expect(container.read(provider).phase, PlayerPhase.idle);
      expect(factory.engines, isEmpty);
      container.invalidate(provider);
      await container.pump();
      expect(resolver.calls, 0);
      final vm = container.read(provider.notifier);
      await vm.start('demo-000');
      expect(factory.active, 1);
      container.invalidate(provider);
      await container.pump();
      expect(container.read(provider).phase, PlayerPhase.idle);
      expect(factory.engines, hasLength(1));
      expect(factory.active, 0);
    },
  );

  test(
    'pause, seek, save and reopen use the same valid resume point',
    () async {
      final vm = container.read(provider.notifier);
      await vm.start('demo-000');
      final engine = factory.engines.single;
      engine.emit(engine.value.copyWith(position: const Duration(seconds: 7)));
      await vm.togglePause();
      expect(container.read(provider).phase, PlayerPhase.paused);
      await vm.seekBy(const Duration(seconds: 10));
      expect(engine.snapshot.position.inSeconds, 17);
      await vm.close();
      expect(progress.writes.last.position.inSeconds, 17);
      await vm.start('demo-000');
      expect(factory.engines.last.openedAt?.inSeconds, 17);
      await vm.close();
      expect(
        progress.writes.last.position.inSeconds,
        17,
        reason: 'new opening zero must not overwrite old progress',
      );
    },
  );

  test(
    'closing while resolving cancels request and discards its late result',
    () async {
      resolver.gate = Completer<void>();
      final vm = container.read(provider.notifier);
      final opening = vm.start('demo-000');
      await Future<void>.delayed(Duration.zero);
      await vm.close();
      expect(resolver.signal?.isCancelled, isTrue);
      resolver.gate!.complete();
      await opening;
      expect(factory.engines, isEmpty);
      expect(container.read(provider).phase, PlayerPhase.closed);
    },
  );

  test(
    '20 video switches retain one engine and ignore old callbacks',
    () async {
      final vm = container.read(provider.notifier);
      for (var i = 0; i < 20; i++) {
        await vm.start('demo-${(i % 2).toString().padLeft(3, '0')}');
        expect(factory.active, 1);
        final current = container.read(provider);
        if (i > 0) {
          factory.engines[i - 1].emit(
            const EngineSnapshot(
              failure: AppFailure(FailureKind.unknown, 'stale'),
            ),
          );
          expect(container.read(provider), current);
        }
      }
      await vm.close();
      expect(factory.maxActive, 1);
      expect(factory.active, 0);
    },
  );

  test(
    'closing while opening releases immediately and cannot later play',
    () async {
      factory.openGate = Completer<void>();
      final vm = container.read(provider.notifier);
      final opening = vm.start('demo-000');
      while (factory.engines.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      await vm.close();
      factory.openGate!.complete();
      await opening;
      expect(factory.active, 0);
      expect(container.read(provider).phase, PlayerPhase.closed);
    },
  );

  test(
    'permission failure has no automatic retry and explicit retry succeeds',
    () async {
      resolver.failure = const AppFailure(FailureKind.permission, '需要权限');
      final vm = container.read(provider.notifier);
      await vm.start('demo-000');
      expect(container.read(provider).phase, PlayerPhase.failed);
      await container.pump();
      expect(resolver.calls, 1);
      resolver.failure = null;
      await vm.start('demo-000');
      expect(container.read(provider).phase, PlayerPhase.playing);
      await vm.close();
    },
  );

  test('completed playback can explicitly replay from the beginning', () async {
    final vm = container.read(provider.notifier);
    await vm.start('demo-000');
    final first = factory.engines.single;
    first.emit(
      first.snapshot.copyWith(
        position: const Duration(seconds: 120),
        completed: true,
        playing: false,
      ),
    );
    expect(container.read(provider).phase, PlayerPhase.completed);
    await vm.togglePause();
    expect(factory.engines, hasLength(2));
    expect(factory.engines.last.openedAt, Duration.zero);
    expect(container.read(provider).phase, PlayerPhase.playing);
    await vm.close();
    expect(factory.active, 0);
  });
}
