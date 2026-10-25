import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/repositories/drift_history_repository.dart';
import 'package:mambatv/data/repositories/local_progress_repository.dart';
import 'package:mambatv/data/repositories/local_search_history_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/domain/playback/playback.dart';

import '../generated_migrations/schema.dart';
import '../support/memory_preferences.dart';
import '../support/fake_library.dart';

void main() {
  test('v1 migration preserves resume and search rows and adds metadata without guessing titles', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute(
      "INSERT INTO watch_progress_rows VALUES ('guest','BVold','11',25000,120000,1700000000)",
      [],
    );
    schema.rawDatabase.execute(
      "INSERT INTO search_entries VALUES ('guest','旧搜索',1700000000)",
      [],
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
    final history = (await DriftHistoryRepository(db).list('guest'))
        .valueOrThrow;
    expect(history.items.single.position.inSeconds, 25);
    expect(history.items.single.partId, '11');
    expect(history.items.single.video.title, 'B站视频 BVold');
    expect(
      (await LocalSearchHistoryRepository(db).load('guest')).valueOrThrow,
      ['旧搜索'],
    );
  });
  test('local records deduplicate parts, paginate, and clear only the selected owner', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final history = DriftHistoryRepository(db),
        progress = LocalProgressRepository(db);
    Future<void> save(String owner, String video, String part) async {
      await progress.save(
        WatchProgress(
          ownerKey: owner,
          videoId: video,
          partId: part,
          position: const Duration(seconds: 20),
          duration: const Duration(minutes: 2),
        ),
      );
      await history.rememberVideo(owner, libraryVideo(video));
    }

    for (var i = 0; i < 26; i++) {
      await save('guest', 'BV$i', '1');
    }
    await save('guest', 'BV0', '2');
    await save('guest', 'BV0', '1');
    await save('user:2', 'BV0', '3');
    final page = (await history.list('guest')).valueOrThrow;
    expect(page.items, hasLength(24));
    expect(page.items.first.partId, '1');
    expect(page.items.first.video.title, '合成视频 BV0');
    expect(
      (await history.list('guest', cursor: page.nextCursor)).valueOrThrow.items,
      hasLength(2),
    );
    await LocalSearchHistoryRepository(db).remember('guest', '保留搜索');
    await history.remove('guest', 'BV0');
    expect(
      (await progress.latestForVideo('guest', 'BV0')).valueOrThrow,
      isNull,
    );
    await history.clear('guest');
    expect((await history.list('guest')).valueOrThrow.items, isEmpty);
    expect(
      (await history.list('user:2')).valueOrThrow.items.single.partId,
      '3',
    );
    expect(
      (await LocalSearchHistoryRepository(db).load('guest')).valueOrThrow,
      ['保留搜索'],
    );
  });
  test('legacy preferences preserve choices and default remote synchronization off', () async {
    final store = MemoryPreferencesStore()
      ..values['app.preferences.v1'] =
          '{"reducedMotion":true,"resumePlayback":false}';
    final repository = LocalSettingsRepository(store);
    final old = (await repository.load()).valueOrThrow;
    expect(old.reducedMotion, true);
    expect(old.resumePlayback, false);
    expect(old.syncHistory, false);
    final updated = old.copyWith(
      defaultRate: 1.5,
      defaultQuality: 80,
      autoNext: true,
      syncHistory: true,
    );
    await repository.save(updated);
    expect((await LocalSettingsRepository(store).load()).valueOrThrow, updated);
    store.values['app.preferences.v1'] =
        '{"defaultRate":99,"defaultQuality":999}';
    expect((await repository.load()).valueOrThrow.defaultRate, 1);
    expect((await repository.load()).valueOrThrow.defaultQuality, 0);
  });
}
