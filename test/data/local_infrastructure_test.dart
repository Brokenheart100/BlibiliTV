import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/network/safe_logging_interceptor.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/data/repositories/local_progress_repository.dart';

import '../generated_migrations/schema.dart';
import '../support/memory_preferences.dart';

void main() {
  test(
    'zero or invalid progress cannot overwrite a valid resume point',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = LocalProgressRepository(database);
      WatchProgress progress(Duration position) => WatchProgress(
        ownerKey: 'guest',
        videoId: 'BVsynthetic',
        partId: '1',
        position: position,
        duration: const Duration(minutes: 2),
      );
      await repository.save(progress(const Duration(seconds: 25)));
      await repository.save(progress(Duration.zero));
      await repository.save(progress(const Duration(minutes: 3)));
      final restored = (await repository.load(
        'guest',
        'BVsynthetic',
        '1',
      )).valueOrThrow;
      expect(restored?.position.inSeconds, 25);
      expect(
        (await repository.load(
          'another-owner',
          'BVsynthetic',
          '1',
        )).valueOrThrow,
        isNull,
      );
    },
  );

  test('v1 schema upgrades to the exported v2 schema', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 2);
  });

  test('watch progress is keyed by owner, video and part', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 24);
    for (final owner in ['A', 'B']) {
      await database
          .into(database.watchProgressRows)
          .insertOnConflictUpdate(
            WatchProgressRowsCompanion.insert(
              ownerKey: owner,
              videoId: 'video',
              partId: 'part',
              positionMs: Value(owner == 'A' ? 1000 : 2000),
              updatedAt: now,
            ),
          );
    }
    await database
        .into(database.watchProgressRows)
        .insertOnConflictUpdate(
          WatchProgressRowsCompanion.insert(
            ownerKey: 'A',
            videoId: 'video',
            partId: 'part',
            positionMs: const Value(3000),
            updatedAt: now,
          ),
        );
    final rows = await database.select(database.watchProgressRows).get();
    expect(rows, hasLength(2));
    expect(rows.singleWhere((row) => row.ownerKey == 'B').positionMs, 2000);
    expect(rows.singleWhere((row) => row.ownerKey == 'A').positionMs, 3000);
  });

  test(
    'settings persist across repository instances without storing credentials',
    () async {
      final store = MemoryPreferencesStore();
      await LocalSettingsRepository(store)
          .save(const AppSettings(reducedMotion: true));
      final restored = (await LocalSettingsRepository(
        store,
      ).load()).valueOrThrow;
      expect(restored.reducedMotion, isTrue);
      expect(store.values.keys, ['app.preferences.v1']);
    },
  );

  test('HTTP logs omit URL, cookies, authorization and payload', () {
    final logs = <String>[];
    final interceptor = SafeLoggingInterceptor(logs.add);
    final request = RequestOptions(
      path: 'https://example.invalid/?token=synthetic-secret',
      method: 'POST',
      headers: {
        'Cookie': 'SESSDATA=synthetic-secret',
        'Authorization': 'synthetic-secret',
      },
      data: {'password': 'synthetic-secret'},
    );
    interceptor.onRequest(request, RequestInterceptorHandler());
    interceptor.onResponse(
      Response<Object?>(
        requestOptions: request,
        statusCode: 200,
        data: {'token': 'synthetic-secret'},
      ),
      ResponseInterceptorHandler(),
    );
    expect(logs.single, contains('"status":200'));
    expect(logs.single, isNot(contains('synthetic-secret')));
    expect(logs.single, isNot(contains('example.invalid')));
    expect(logs.single, isNot(contains('Cookie')));
  });
}
