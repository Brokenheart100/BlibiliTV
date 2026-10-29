import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/playback/playback.dart';
import '../services/local/app_database.dart';
import '../../domain/entities/app_models.dart';
import 'drift_history_repository.dart';
import '../../domain/playback/content_playback.dart';
import '../../domain/playback/playback_target.dart';

class LocalProgressRepository
    implements ProgressRepository, ContentProgressRepository {
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
                      t.ownerKey.equals(ownerKey) &
                      t.contentKind.equals('ugc') &
                      t.videoId.equals(videoId),
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
    return _load(ownerKey, ContentKind.ugc, videoId, partId);
  }

  Future<Result<WatchProgress?>> _load(
    String ownerKey,
    ContentKind kind,
    String videoId,
    String partId,
  ) async {
    try {
      final row =
          await (database.select(database.watchProgressRows)..where(
                (t) =>
                    t.ownerKey.equals(ownerKey) &
                    t.contentKind.equals(kind.name) &
                    t.videoId.equals(videoId) &
                    t.partId.equals(partId),
              ))
              .getSingleOrNull();
      return Success(
        row == null
            ? null
            : WatchProgress(
                ownerKey: ownerKey,
                kind: kind,
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
                  t.contentKind.equals(progress.kind.name) &
                  t.videoId.equals(progress.videoId) &
                  t.partId.equals(progress.partId),
            ))
            .go();
        await database
            .into(database.watchProgressRows)
            .insert(
              WatchProgressRowsCompanion.insert(
                ownerKey: progress.ownerKey,
                contentKind: Value(progress.kind.name),
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

  @override
  Future<Result<WatchProgress?>> loadTarget(
    String ownerKey,
    PlaybackTarget target,
  ) => target is LiveTarget
      ? Future.value(const Success(null))
      : _load(ownerKey, target.kind, target.contentId, target.partId ?? '');

  @override
  Future<Result<void>> rememberTarget(
    String ownerKey,
    PlaybackTarget target,
    VideoSummary metadata,
  ) async {
    try {
      await database
          .into(database.historyVideos)
          .insertOnConflictUpdate(
            HistoryVideosCompanion.insert(
              ownerKey: ownerKey,
              contentKind: Value(target.kind.name),
              videoId: target.contentId,
              title: metadata.title,
              creator: metadata.creator,
              coverUrl: Value(metadata.coverUrl),
              durationSeconds: metadata.durationSeconds,
            ),
          );
      if (target is LiveTarget) {
        await database
            .into(database.watchProgressRows)
            .insertOnConflictUpdate(
              WatchProgressRowsCompanion.insert(
                ownerKey: ownerKey,
                contentKind: const Value('live'),
                videoId: target.roomId,
                partId: '',
                updatedAt: DateTime.now(),
              ),
            );
      }
      return const Success(null);
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '观看信息未能保存'));
    }
  }
}
