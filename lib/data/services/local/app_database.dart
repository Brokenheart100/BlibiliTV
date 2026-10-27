import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class WatchProgressRows extends Table {
  TextColumn get ownerKey => text()();
  TextColumn get videoId => text()();
  TextColumn get partId => text()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerKey, videoId, partId};
}

class SearchEntries extends Table {
  TextColumn get ownerKey => text()();
  TextColumn get query => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerKey, query};
}

class HistoryVideos extends Table {
  TextColumn get ownerKey => text()();
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get creator => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get creatorAvatarUrl => text().nullable()();
  IntColumn get durationSeconds => integer()();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {ownerKey, videoId};
}

@DriftDatabase(tables: [WatchProgressRows, SearchEntries, HistoryVideos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.defaults() : super(driftDatabase(name: 'mambatv'));
  @override
  int get schemaVersion => 3;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(historyVideos);
      if (from >= 2 && from < 3) {
        await migrator.addColumn(historyVideos, historyVideos.creatorAvatarUrl);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  Future<void> initialize() async {
    await customSelect('SELECT 1').get();
  }
}
