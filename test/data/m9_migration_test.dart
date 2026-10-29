import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/repositories/drift_history_repository.dart';
import 'package:mambatv/data/repositories/local_progress_repository.dart';
import 'package:mambatv/data/repositories/local_search_history_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';

import '../generated_migrations/schema.dart';

void main() {
  for (final version in [1, 2, 3]) {
    test(
      'v$version to v4 retains owner, UGC progress, metadata and search',
      () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(version);
        schema.rawDatabase.execute(
          "INSERT INTO watch_progress_rows VALUES ('user:1','BVold','123',25000,120000,1700000000)",
          [],
        );
        schema.rawDatabase.execute(
          "INSERT INTO search_entries VALUES ('user:1','保留搜索',1700000000)",
          [],
        );
        if (version >= 2) {
          schema.rawDatabase.execute(
            "INSERT INTO history_videos (owner_key,video_id,title,creator,duration_seconds,view_count) VALUES ('user:1','BVold','旧标题','旧作者',120,10)",
            [],
          );
        }
        if (version == 3) {
          schema.rawDatabase.execute(
            "UPDATE history_videos SET creator_avatar_url='https://i0.hdslb.com/bfs/face/synthetic.jpg' WHERE owner_key='user:1'",
            [],
          );
        }
        final database = AppDatabase(schema.newConnection());
        addTearDown(database.close);
        await verifier.migrateAndValidate(database, 4);
        final row = await database
            .select(database.watchProgressRows)
            .getSingle();
        expect(row.contentKind, 'ugc');
        expect(row.ownerKey, 'user:1');
        expect(row.positionMs, 25000);
        expect(
          (await LocalProgressRepository(database).loadTarget(
            'user:1',
            const PlaybackTarget.ugc(bvid: 'BVold', cid: '123'),
          )).valueOrThrow!.position.inSeconds,
          25,
        );
        expect(
          (await LocalSearchHistoryRepository(database).load('user:1'))
              .valueOrThrow,
          ['保留搜索'],
        );
        if (version >= 2) {
          expect(
            (await DriftHistoryRepository(database).list('user:1'))
                .valueOrThrow
                .items
                .single
                .video
                .title,
            '旧标题',
          );
        }
        if (version == 3) {
          expect(
            (await database.select(database.historyVideos).getSingle())
                .creatorAvatarUrl,
            'https://i0.hdslb.com/bfs/face/synthetic.jpg',
          );
        }
      },
    );
  }
  test(
    'same ids across UGC, PGC, live and owners cannot collide or cross-delete',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final progress = LocalProgressRepository(database),
          history = DriftHistoryRepository(database);
      const metadata = VideoSummary(
        id: '123',
        title: '标题',
        creator: '作者',
        durationSeconds: 120,
        viewCount: 0,
      );
      const ugc = PlaybackTarget.ugc(bvid: '123', cid: '456');
      const pgc = PlaybackTarget.pgc(seasonId: '123', episodeId: '456');
      const live = PlaybackTarget.live(roomId: '123');
      for (final owner in ['guest', 'user:1']) {
        await progress.rememberTarget(owner, ugc, metadata);
        await progress.rememberTarget(owner, pgc, metadata);
        await progress.rememberTarget(owner, live, metadata);
        for (final kind in [ContentKind.ugc, ContentKind.pgc]) {
          await progress.save(
            WatchProgress(
              ownerKey: owner,
              kind: kind,
              videoId: '123',
              partId: '456',
              position: Duration(seconds: kind == ContentKind.ugc ? 20 : 50),
              duration: const Duration(seconds: 120),
            ),
          );
        }
      }
      expect((await history.list('guest')).valueOrThrow.items, hasLength(3));
      expect(
        (await progress.loadTarget(
          'guest',
          ugc,
        )).valueOrThrow!.position.inSeconds,
        20,
      );
      expect(
        (await progress.loadTarget(
          'guest',
          pgc,
        )).valueOrThrow!.position.inSeconds,
        50,
      );
      expect((await progress.loadTarget('guest', live)).valueOrThrow, isNull);
      await history.removeTarget('guest', pgc);
      expect((await progress.loadTarget('guest', pgc)).valueOrThrow, isNull);
      expect((await progress.loadTarget('guest', ugc)).valueOrThrow, isNotNull);
      expect((await history.list('user:1')).valueOrThrow.items, hasLength(3));
      await history.clear('guest');
      expect((await history.list('guest')).valueOrThrow.items, isEmpty);
      expect((await history.list('user:1')).valueOrThrow.items, hasLength(3));
    },
  );
}
