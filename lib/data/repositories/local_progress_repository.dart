import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/playback/playback.dart';
import '../services/local/app_database.dart';
import '../../domain/entities/app_models.dart';
import 'drift_history_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this.database);
  final AppDatabase database;
  @override
  Future<Result<void>> rememberVideo(String ownerKey, VideoSummary video) =>
      DriftHistoryRepository(database).rememberVideo(ownerKey, video);
  @override
  Future<Result<WatchProgress?>> latestForVideo(
    String ownerKey,
    String videoId,
  ) async {
    try {
      final row =
          await (database.select(database.watchProgressRows)
                ..where(
                  (t) =>
                      t.ownerKey.equals(ownerKey) & t.videoId.equals(videoId),
                )
                ..orderBy([
                  (t) => OrderingTerm.desc(t.updatedAt),
                  (t) => OrderingTerm.desc(t.rowId),
                ])
                ..limit(1))
              .getSingleOrNull();
      return Success(
        row == null
            ? null
            : WatchProgress(
                ownerKey: row.ownerKey,
                videoId: row.videoId,
                partId: row.partId,
                position: Duration(milliseconds: row.positionMs),
                duration: Duration(milliseconds: row.durationMs),
              ),
      );
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '无法读取播放位置'));
    }
  }

  @override
  Future<Result<WatchProgress?>> load(
    String ownerKey,
    String videoId,
    String partId,
  ) async {
    try {
      final row =
          await (database.select(database.watchProgressRows)..where(
                (t) =>
                    t.ownerKey.equals(ownerKey) &
                    t.videoId.equals(videoId) &
                    t.partId.equals(partId),
              ))
              .getSingleOrNull();
      return Success(
        row == null
            ? null
            : WatchProgress(
                ownerKey: ownerKey,
                videoId: videoId,
                partId: partId,
                position: Duration(milliseconds: row.positionMs),
                duration: Duration(milliseconds: row.durationMs),
              ),
      );
    } catch (_) {
      return const ResultFailure(
        AppFailure(FailureKind.storage, '无法读取播放位置，请稍后重试'),
      );
    }
  }

  @override
  Future<Result<void>> save(WatchProgress progress) async {
    if (!progress.isValid) return const Success(null);
    try {
      await database.transaction(() async {
        await (database.delete(database.watchProgressRows)..where(
              (t) =>
                  t.ownerKey.equals(progress.ownerKey) &
                  t.videoId.equals(progress.videoId) &
                  t.partId.equals(progress.partId),
            ))
            .go();
        await database
            .into(database.watchProgressRows)
            .insert(
              WatchProgressRowsCompanion.insert(
                ownerKey: progress.ownerKey,
                videoId: progress.videoId,
                partId: progress.partId,
                positionMs: Value(progress.position.inMilliseconds),
                durationMs: Value(progress.duration.inMilliseconds),
                updatedAt: DateTime.now(),
              ),
            );
      });
      return const Success(null);
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '播放位置未能保存'));
    }
  }
}
