import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/repositories/local_search_history_repository.dart';
import 'package:mambatv/data/repositories/local_progress_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/playback/playback.dart';

void main() {
  late AppDatabase database;
  late LocalSearchHistoryRepository history;
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    history = LocalSearchHistoryRepository(database);
    addTearDown(database.close);
  });
  test('history retains twelve recent distinct queries with stable same-second ordering', () async {
    await Future.wait([
      for (var i = 0; i < 20; i++) history.remember('guest', '关键词 $i'),
    ]);
    final items = (await history.load('guest')).valueOrThrow;
    expect(items, [for (var i = 19; i >= 8; i--) '关键词 $i']);
    await history.remember('guest', ' 关键词 10 ');
    expect((await history.load('guest')).valueOrThrow.first, '关键词 10');
    expect((await history.load('guest')).valueOrThrow, hasLength(12));
  });
  test(
    'recreated repository restores history and clear is owner-scoped',
    () async {
      await history.remember('guest', '中文');
      await history.remember('A', '另一个账号');
      final recreated = LocalSearchHistoryRepository(database);
      expect((await recreated.load('guest')).valueOrThrow, ['中文']);
      await recreated.clear('guest');
      expect((await recreated.load('guest')).valueOrThrow, isEmpty);
      expect((await recreated.load('A')).valueOrThrow, ['另一个账号']);
    },
  );
  test('blank and oversized queries are not recorded', () async {
    await history.remember('guest', '  ');
    await history.remember('guest', '中' * 101);
    expect((await history.load('guest')).valueOrThrow, isEmpty);
  });
  test('latest resume follows actual write order across repeated parts within one second', () async {
    final progress = LocalProgressRepository(database);
    Future<Result<void>> save(String owner, String part) => progress.save(
      WatchProgress(
        ownerKey: owner,
        videoId: 'BVtest',
        partId: part,
        position: const Duration(seconds: 5),
        duration: const Duration(minutes: 2),
      ),
    );
    await save('guest', '1');
    await save('guest', '2');
    await save('guest', '1');
    await save('A', '3');
    expect(
      (await progress.latestForVideo('guest', 'BVtest')).valueOrThrow?.partId,
      '1',
    );
    expect(
      (await progress.latestForVideo('A', 'BVtest')).valueOrThrow?.partId,
      '3',
    );
    expect((await progress.latestForVideo('B', 'BVtest')).valueOrThrow, isNull);
  });
}
