import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/content_playback.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';
import 'package:mambatv/domain/playback/start_playback.dart';

import '../support/fake_content.dart';
import '../support/fake_playback.dart';
import '../support/memory_preferences.dart';

class GroupedPgc extends FakePgcRepository {
  @override
  Future<Result<ContentSeason>> season(
    String id,
    CancellationSignal signal,
  ) async => Success(
    ContentSeason(
      id: '10',
      title: '季',
      description: '',
      episodes: const [
        ContentEpisode(id: '1', title: '正片', cid: '101', bvid: 'BVmain'),
      ],
      groups: const {
        '花絮': [
          ContentEpisode(id: '91', title: '花絮一', cid: '191', bvid: 'BVextra'),
          ContentEpisode(id: '92', title: '花絮二', cid: '192', bvid: 'BVextra2'),
        ],
      },
    ),
  );
}

void main() {
  late MemoryContentProgress progress;
  late LocalSettingsRepository settings;
  late FakePlaybackRepository ugc;
  late FakeLiveRepository live;
  late GroupedPgc pgc;
  late StartPlayback start;
  setUp(() async {
    progress = MemoryContentProgress();
    settings = LocalSettingsRepository(MemoryPreferencesStore());
    await settings.save(
      const AppSettings(defaultRate: 2, autoNext: true, syncHistory: true),
    );
    ugc = FakePlaybackRepository();
    live = FakeLiveRepository();
    pgc = GroupedPgc();
    start = StartPlayback(
      FakeCatalogRepository(),
      ugc,
      progress,
      settings,
      pgc: () => pgc,
      live: () => live,
      contentProgress: () => progress,
    );
  });

  test('PGC extras keep their own sequence, real overlay IDs and owner-specific resume', () async {
    await progress.save(
      const WatchProgress(
        ownerKey: 'A',
        kind: ContentKind.pgc,
        videoId: '10',
        partId: '91',
        position: Duration(seconds: 40),
        duration: Duration(seconds: 120),
      ),
    );
    const target = PlaybackTarget.pgc(seasonId: '10', episodeId: '91');
    final plan = await start(
      target: target,
      ownerKey: 'A',
      cancellation: CancellationSignal(),
    );
    expect(plan.parts.map((p) => p.id), ['91', '92']);
    expect(plan.overlayVideoId, 'BVextra');
    expect(plan.overlayPartId, '191');
    expect(plan.startAt, const Duration(seconds: 40));
    expect(plan.initialRate, 2);
    expect(plan.autoNext, isTrue);
    expect(plan.syncHistory, isFalse);
    expect(plan.capabilities.remoteHistory, isFalse);
    final other = await start(
      target: target,
      ownerKey: 'B',
      cancellation: CancellationSignal(),
    );
    expect(other.startAt, Duration.zero);
    expect(ugc.calls, 0);
  });

  test(
    'episode outside the requested season never resolves a source',
    () async {
      await expectLater(
        start(
          target: const PlaybackTarget.pgc(seasonId: '10', episodeId: '999'),
          ownerKey: 'A',
          cancellation: CancellationSignal(),
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(pgc.requested, isEmpty);
    },
  );

  test('live ignores VOD preferences and position, and offline room never resolves', () async {
    final plan = await start(
      target: const PlaybackTarget.live(roomId: '6'),
      ownerKey: 'A',
      position: const Duration(minutes: 10),
      cancellation: CancellationSignal(),
    );
    expect(plan.target, const PlaybackTarget.live(roomId: '100'));
    expect(plan.startAt, Duration.zero);
    expect(plan.rememberProgress, isFalse);
    expect(plan.autoNext, isFalse);
    expect(plan.initialRate, 1);
    expect(plan.capabilities, PlaybackCapabilities.live);
    expect(progress.visits.single, plan.target);
    final fallback = await start(
      target: const PlaybackTarget.live(roomId: '6'),
      ownerKey: 'A',
      quality: 10000,
      cancellation: CancellationSignal(),
    );
    expect(fallback.source.quality, 250);
    expect(fallback.preferenceNotice, contains('服务端实际返回'));
    live.active = false;
    await expectLater(
      start(
        target: const PlaybackTarget.live(roomId: '6'),
        ownerKey: 'A',
        cancellation: CancellationSignal(),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(live.resolutions, 2);
  });
}
