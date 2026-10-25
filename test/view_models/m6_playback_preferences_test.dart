import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/start_playback.dart';

import '../support/fake_playback.dart';
import '../support/memory_preferences.dart';

class LockedPreference extends FakePlaybackRepository {
  @override
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
    int? quality,
    int? audioId,
  }) async {
    failure = quality == 80
        ? const AppFailure(FailureKind.permission, '合成权限不足')
        : null;
    return super.resolve(
      videoId: videoId,
      partId: partId,
      cancellation: cancellation,
      quality: quality,
      audioId: audioId,
    );
  }
}

void main() {
  test('saved defaults apply once, unavailable preferred quality falls back with a notice, local progress wins', () async {
    final settings = LocalSettingsRepository(MemoryPreferencesStore());
    await settings.save(
      const AppSettings(defaultRate: 1.5, defaultQuality: 80, autoNext: true),
    );
    final progress = MemoryProgressRepository();
    final resolver = LockedPreference();
    final start = StartPlayback(
      FakeCatalogRepository(latency: Duration.zero),
      resolver,
      progress,
      settings,
    );
    await progress.save(
      const WatchProgress(
        ownerKey: 'guest',
        videoId: 'demo-000',
        partId: 'demo-000-p1',
        position: Duration(seconds: 20),
        duration: Duration(seconds: 120),
      ),
    );
    final plan = await start(
      videoId: 'demo-000',
      ownerKey: 'guest',
      cancellation: CancellationSignal(),
      fallbackPosition: const Duration(seconds: 60),
    );
    expect(plan.startAt.inSeconds, 20);
    expect(plan.initialRate, 1.5);
    expect(plan.autoNext, true);
    expect(plan.syncHistory, false);
    expect(plan.preferenceNotice, isNotNull);
    expect(resolver.requests.map((r) => r.quality), [80, null]);
    expect(
      () => start(
        videoId: 'demo-000',
        ownerKey: 'guest',
        quality: 80,
        cancellation: CancellationSignal(),
      ),
      throwsA(isA<AppFailure>()),
    );
  });
  test('remote resume is only a fallback; completed local progress and disabled resume block it', () async {
    final settings = LocalSettingsRepository(MemoryPreferencesStore()),
        progress = MemoryProgressRepository();
    final start = StartPlayback(
      FakeCatalogRepository(latency: Duration.zero),
      FakePlaybackRepository(),
      progress,
      settings,
    );
    Future<PlaybackPlan> plan() => start(
      videoId: 'demo-000',
      ownerKey: 'guest',
      cancellation: CancellationSignal(),
      fallbackPosition: const Duration(seconds: 60),
    );
    expect((await plan()).startAt.inSeconds, 60);
    await progress.save(
      const WatchProgress(
        ownerKey: 'guest',
        videoId: 'demo-000',
        partId: 'demo-000-p1',
        position: Duration(seconds: 119),
        duration: Duration(seconds: 120),
      ),
    );
    expect((await plan()).startAt, Duration.zero);
    await settings.save(const AppSettings(resumePlayback: false));
    expect((await plan()).startAt, Duration.zero);
  });
}
