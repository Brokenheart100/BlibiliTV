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

class TestFocus implements PlaybackFocus {
  bool granted = true;
  int acquired = 0, released = 0;
  final events = StreamController<void>.broadcast(sync: true);
  @override
  Stream<void> get interruptions => events.stream;
  @override
  Future<bool> acquire(Object owner) async {
    acquired++;
    return granted;
  }

  @override
  Future<void> release(Object owner) async {
    released++;
  }
}

void main() {
  late ProviderContainer container;
  late FakeEngineFactory factory;
  late FakePlaybackRepository resolver;
  late MemoryProgressRepository progress;
  late TestFocus focus;
  final provider = playerViewModelProvider(pageId: 'm5', ownerKey: 'guest');
  PlayerViewModel vm() => container.read(provider.notifier);
  PlayerState state() => container.read(provider);
  Future<void> until(bool Function() predicate) async {
    for (var i = 0; i < 100 && !predicate(); i++) {
      await Future<void>.delayed(Duration.zero);
      await container.pump();
    }
    expect(predicate(), isTrue);
  }

  setUp(() {
    focus = TestFocus();
    factory = FakeEngineFactory()..focus = focus;
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
    addTearDown(() async {
      await vm().close();
      subscription.close();
      container.dispose();
      await focus.events.close();
    });
  });
  test(
    'quality and audio replacement preserve pause, timeline, rate and volume',
    () async {
      await vm().start('demo-000');
      factory.engines.last.emit(
        factory.engines.last.snapshot.copyWith(
          position: const Duration(seconds: 42),
        ),
      );
      await vm().togglePause();
      await vm().setRate(1.5);
      await vm().setVolume(50);
      await vm().selectQuality(16);
      await vm().selectAudio(30280);
      expect(state().phase, PlayerPhase.paused);
      expect(factory.engines.last.openedAt, const Duration(seconds: 42));
      expect(factory.engines.last.snapshot.rate, 1.5);
      expect(factory.engines.last.snapshot.volume, 50);
      expect(state().quality, 16);
      expect(state().audioId, 30280);
      expect(factory.maxActive, 1);
    },
  );
  test(
    'latest quality wins during resolution without losing the pinned position',
    () async {
      await vm().start('demo-000');
      factory.engines.last.emit(
        factory.engines.last.snapshot.copyWith(
          position: const Duration(seconds: 42),
        ),
      );
      final gate = Completer<void>();
      resolver.gate = gate;
      final first = vm().selectQuality(16);
      await until(() => resolver.calls == 2);
      resolver.gate = null;
      final last = vm().selectQuality(32);
      await last;
      gate.complete();
      await first;
      expect(state().quality, 32);
      expect(factory.engines.last.openedAt, const Duration(seconds: 42));
      expect(factory.maxActive, 1);
    },
  );
  test('rapid part selection keeps only the last intent and saves the old part correctly', () async {
    await vm().start('demo-000');
    factory.engines.last.emit(
      factory.engines.last.snapshot.copyWith(
        position: const Duration(seconds: 25),
      ),
    );
    final ids = state().parts.map((p) => p.id).toList();
    await Future.wait([
      for (var i = 0; i < 20; i++) vm().selectPart(ids[i % 2]),
    ]);
    expect(state().partId, ids.last);
    expect(factory.maxActive, 1);
    expect(
      progress.writes
          .where((p) => p.position.inSeconds == 25)
          .every((p) => p.partId == ids.first),
      isTrue,
    );
  });
  test(
    'seek commands are serialized and backward seek is immediately saved',
    () async {
      await vm().start('demo-000');
      await Future.wait([
        vm().seekBy(const Duration(seconds: 10)),
        vm().seekBy(const Duration(seconds: 20)),
        vm().seekBy(const Duration(seconds: -5)),
      ]);
      expect(state().snapshot.position.inSeconds, 25);
      await vm().seekBy(const Duration(seconds: -20));
      await vm().close();
      expect(progress.writes.last.position.inSeconds, 5);
      await vm().start('demo-000');
      expect(factory.engines.last.openedAt?.inSeconds, 5);
    },
  );
  test(
    'disposing an explicitly closed player does not enqueue another save',
    () async {
      await vm().start('demo-000');
      await vm().seekBy(const Duration(seconds: 20));
      await vm().close();
      final writes = progress.writes.length;
      container.invalidate(provider);
      await container.pump();
      await Future<void>.delayed(Duration.zero);
      expect(progress.writes.length, writes);
    },
  );
  test(
    'rapid direction changes coalesce while the native decoder is seeking',
    () async {
      await vm().start('demo-000');
      final engine = factory.engines.last;
      engine.emit(
        engine.snapshot.copyWith(position: const Duration(seconds: 40)),
      );
      final gate = factory.seekGate = Completer<void>();
      final first = vm().seekBy(const Duration(seconds: 10));
      await until(() => engine.seeks.isNotEmpty);
      final rest = [
        vm().seekBy(const Duration(seconds: 10)),
        vm().seekBy(const Duration(seconds: 10)),
        vm().seekBy(const Duration(seconds: -10)),
      ];
      gate.complete();
      await Future.wait([first, ...rest]);
      expect(engine.seeks, [
        const Duration(seconds: 50),
        const Duration(seconds: 60),
      ]);
      expect(state().snapshot.position, const Duration(seconds: 60));
    },
  );
  test(
    'a stalled seek reloads at the requested position and retains pause',
    () async {
      await vm().start('demo-000');
      await vm().togglePause();
      factory.seekFailure = const AppFailure(
        FailureKind.timeout,
        'native seek stalled',
      );
      await vm().seekBy(const Duration(seconds: 30));
      await until(
        () =>
            factory.engines.length == 2 && state().phase == PlayerPhase.paused,
      );
      expect(factory.engines.last.openedAt, const Duration(seconds: 30));
      expect(factory.maxActive, 1);
    },
  );
  test(
    'changing part cancels the pending seek target from the old part',
    () async {
      await vm().start('demo-000');
      final old = factory.engines.last;
      final gate = factory.seekGate = Completer<void>();
      final seek = vm().seekBy(const Duration(seconds: 30));
      await until(() => old.seeks.isNotEmpty);
      final part = state().parts[1].id;
      final replacement = vm().selectPart(part);
      await vm().seekBy(const Duration(seconds: 10));
      gate.complete();
      await Future.wait([seek, replacement]);
      expect(state().partId, part);
      expect(factory.engines.last.openedAt, Duration.zero);
      expect(factory.engines.last.seeks, isEmpty);
      expect(old.seeks, [const Duration(seconds: 30)]);
      expect(factory.maxActive, 1);
    },
  );
  test(
    'an unsupported native seek exposes a retry state without automatic reload',
    () async {
      await vm().start('demo-000');
      factory.seekFailure = const AppFailure(
        FailureKind.unsupported,
        'native decoder failed',
      );
      await vm().seekBy(const Duration(seconds: 30));
      await until(() => factory.active == 0);
      expect(state().phase, PlayerPhase.failed);
      expect(state().failure?.kind, FailureKind.unsupported);
      expect(factory.engines, hasLength(1));
    },
  );
  test(
    'completion stops by default and last-part autoplay cannot wrap around',
    () async {
      await vm().start('demo-000');
      final engine = factory.engines.last;
      engine.emit(
        engine.snapshot.copyWith(
          completed: true,
          playing: false,
          position: const Duration(seconds: 120),
        ),
      );
      expect(state().phase, PlayerPhase.completed);
      expect(factory.engines.length, 1);
      await vm().nextPart();
      vm().setAutoNext(true);
      final last = factory.engines.last;
      last.emit(
        last.snapshot.copyWith(
          completed: true,
          playing: false,
          position: const Duration(seconds: 120),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(state().phase, PlayerPhase.completed);
      expect(factory.engines.length, 2);
    },
  );
  test('opt-in completion starts only the next part and never reuses old completion callbacks', () async {
    await vm().start('demo-000');
    vm().setAutoNext(true);
    final first = factory.engines.last;
    first.emit(
      first.snapshot.copyWith(
        completed: true,
        playing: false,
        position: const Duration(seconds: 120),
      ),
    );
    await until(
      () =>
          state().partId.endsWith('p2') && state().phase == PlayerPhase.playing,
    );
    expect(factory.engines.length, 2);
    expect(factory.engines.last.openedAt, Duration.zero);
    expect(
      progress.writes.any(
        (p) => p.partId.endsWith('p1') && p.position.inSeconds == 120,
      ),
      isTrue,
    );
  });
  test(
    'denied audio focus never opens an engine or retries automatically',
    () async {
      focus.granted = false;
      await vm().start('demo-000');
      expect(factory.engines, isEmpty);
      expect(state().phase, PlayerPhase.failed);
      expect(focus.acquired, 1);
    },
  );
  test('focus loss closes native audio and requires explicit confirmation to resume', () async {
    await vm().start('demo-000');
    factory.engines.last.emit(
      factory.engines.last.snapshot.copyWith(
        position: const Duration(seconds: 15),
      ),
    );
    focus.events.add(null);
    await until(() => factory.active == 0);
    expect(state().phase, PlayerPhase.paused);
    expect(state().snapshot.playing, isFalse);
    await vm().togglePause();
    expect(factory.active, 1);
    expect(factory.engines.last.openedAt?.inSeconds, 15);
  });
  test('ten background foreground cycles never autoplay or create overlapping engines', () async {
    await vm().start('demo-000');
    for (var i = 0; i < 10; i++) {
      factory.engines.last.emit(
        factory.engines.last.snapshot.copyWith(
          position: Duration(seconds: 10 + i),
        ),
      );
      vm().foregroundChanged(false);
      await until(() => factory.active == 0);
      vm().foregroundChanged(true);
      expect(factory.active, 0);
      await vm().togglePause();
      expect(factory.engines.last.openedAt?.inSeconds, 10 + i);
    }
    expect(factory.maxActive, 1);
  });
  test(
    'CDN recovery consumes one alternate and one fresh parse then stops',
    () async {
      factory.openFailures.addAll(
        List.filled(
          3,
          const AppFailure(FailureKind.cdn, 'synthetic CDN failure'),
        ),
      );
      await vm().start('demo-000');
      await until(
        () =>
            factory.engines.length == 3 &&
            factory.active == 0 &&
            state().phase == PlayerPhase.failed,
      );
      expect(resolver.calls, 2);
      expect(state().recoveryAttempts, 2);
      expect(factory.engines[1].source!.videoUrl, contains('backup.invalid'));
      expect(factory.maxActive, 1);
    },
  );
  test(
    'expired resource reparses only once and skips the old alternate',
    () async {
      factory.openFailures.addAll(
        List.filled(
          2,
          const AppFailure(FailureKind.resourceExpired, 'synthetic expiry'),
        ),
      );
      await vm().start('demo-000');
      await until(
        () =>
            factory.engines.length == 2 &&
            factory.active == 0 &&
            state().phase == PlayerPhase.failed,
      );
      expect(resolver.calls, 2);
      expect(state().recoveryAttempts, 1);
    },
  );
  test(
    'expiry during opening preserves a stored nonzero resume point',
    () async {
      await progress.save(
        const WatchProgress(
          ownerKey: 'guest',
          videoId: 'demo-000',
          partId: 'demo-000-p1',
          position: Duration(seconds: 35),
          duration: Duration(seconds: 120),
        ),
      );
      factory.openFailures.add(
        const AppFailure(FailureKind.resourceExpired, 'opening expiry'),
      );
      await vm().start('demo-000');
      await until(
        () =>
            state().phase == PlayerPhase.playing &&
            state().recoveryAttempts == 1,
      );
      expect(factory.engines.last.openedAt, const Duration(seconds: 35));
    },
  );
  test('live recovery honors an explicit seek to zero without overwriting stored progress with zero', () async {
    await vm().start('demo-000');
    final engine = factory.engines.last;
    engine.emit(
      engine.snapshot.copyWith(position: const Duration(seconds: 25)),
    );
    await vm().seekBy(const Duration(seconds: -25));
    engine.emit(
      engine.snapshot.copyWith(
        failure: const AppFailure(FailureKind.cdn, 'seek-zero failure'),
      ),
    );
    await until(
      () => factory.engines.length == 2 && state().phase == PlayerPhase.playing,
    );
    expect(factory.engines.last.openedAt, Duration.zero);
    expect(progress.writes.every((p) => p.position > Duration.zero), isTrue);
  });
  for (final kind in [
    FailureKind.authentication,
    FailureKind.permission,
    FailureKind.rateLimited,
    FailureKind.unsupported,
    FailureKind.contract,
  ]) {
    test('$kind permanently stops automatic recovery', () async {
      factory.openFailures.add(AppFailure(kind, 'permanent'));
      await vm().start('demo-000');
      await until(() => factory.active == 0);
      expect(resolver.calls, 1);
      expect(factory.engines.length, 1);
      expect(state().phase, PlayerPhase.failed);
    });
  }
  test('unavailable quality and invalid control values cannot reach native commands', () async {
    await vm().start('demo-000');
    await vm().selectQuality(80);
    await vm().selectPart('unrelated');
    await vm().setRate(double.nan);
    await vm().setRate(3);
    await vm().setVolume(-1);
    expect(factory.engines.length, 1);
    expect(state().rate, 1);
    expect(state().volume, 100);
  });
}
