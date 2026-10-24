import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/repositories/repositories.dart';
import '../services/local/app_database.dart';

class LocalSearchHistoryRepository implements SearchHistoryRepository {
  LocalSearchHistoryRepository(this.database);
  final AppDatabase database;
  Future<void> _queue = Future<void>.value();
  @override
  Future<Result<List<String>>> load(String ownerKey) async {
    try {
      await _queue;
      final rows =
          await (database.select(database.searchEntries)
                ..where((t) => t.ownerKey.equals(ownerKey))
                ..orderBy([
                  (t) => OrderingTerm.desc(t.updatedAt),
                  (t) => OrderingTerm.desc(t.rowId),
                ])
                ..limit(12))
              .get();
      return Success(rows.map((r) => r.query).toList());
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '搜索历史暂不可用'));
    }
  }

  Future<Result<void>> _write(Future<void> Function() operation) {
    final result = _queue.then((_) async {
      try {
        await operation();
        return const Success<void>(null);
      } catch (_) {
        return const ResultFailure<void>(
          AppFailure(FailureKind.storage, '搜索历史未能保存'),
        );
      }
    });
    _queue = result.then<void>((_) {});
    return result;
  }

  @override
  Future<Result<void>> remember(String ownerKey, String query) =>
      _write(() async {
        final value = query.trim();
        if (value.isEmpty || value.length > 100) return;
        await database.transaction(() async {
          await (database.delete(database.searchEntries)..where(
                (t) => t.ownerKey.equals(ownerKey) & t.query.equals(value),
              ))
              .go();
          await database
              .into(database.searchEntries)
              .insert(
                SearchEntriesCompanion.insert(
                  ownerKey: ownerKey,
                  query: value,
                  updatedAt: DateTime.now(),
                ),
              );
          final old =
              await (database.select(database.searchEntries)
                    ..where((t) => t.ownerKey.equals(ownerKey))
                    ..orderBy([
                      (t) => OrderingTerm.desc(t.updatedAt),
                      (t) => OrderingTerm.desc(t.rowId),
                    ]))
                  .get();
          for (final row in old.skip(12)) {
            await (database.delete(database.searchEntries)..where(
                  (t) =>
                      t.ownerKey.equals(ownerKey) & t.query.equals(row.query),
                ))
                .go();
          }
        });
      });
  @override
  Future<Result<void>> clear(String ownerKey) => _write(() async {
    await (database.delete(
      database.searchEntries,
    )..where((t) => t.ownerKey.equals(ownerKey))).go();
  });
}
