import 'package:drift/drift.dart';

import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/library/library.dart';
import '../services/local/app_database.dart';

class DriftHistoryRepository implements LocalHistoryRepository {
  DriftHistoryRepository(this.database);
  final AppDatabase database;
  @override
  Future<Result<PageSlice<LibraryEntry>>> list(
    String ownerKey, {
    String? cursor,
  }) async {
    try {
      final offset = int.parse(cursor ?? '0');
      if (offset < 0 || offset > 10000000) {
        throw const FormatException('Cursor');
      }
      final rows = await database
          .customSelect(
            '''
        SELECT p.*, h.title, h.creator, h.cover_url, h.duration_seconds, h.view_count
        FROM watch_progress_rows p LEFT JOIN history_videos h
        ON p.owner_key=h.owner_key AND p.video_id=h.video_id
        WHERE p.owner_key=? AND p.position_ms>=1000 AND p.duration_ms>=p.position_ms
        AND NOT EXISTS (SELECT 1 FROM watch_progress_rows n
          WHERE n.owner_key=p.owner_key AND n.video_id=p.video_id
          AND (n.updated_at>p.updated_at OR (n.updated_at=p.updated_at AND n.rowid>p.rowid)))
        ORDER BY p.updated_at DESC, p.rowid DESC LIMIT 25 OFFSET ?
      ''',
            variables: [Variable(ownerKey), Variable(offset)],
          )
          .get();
      return Success(
        PageSlice(
          items: [
            for (final row in rows.take(24))
              LibraryEntry(
                key: row.read<String>('video_id'),
                video: VideoSummary(
                  id: row.read<String>('video_id'),
                  title:
                      row.readNullable<String>('title') ??
                      'B站视频 ${row.read<String>('video_id')}',
                  creator: row.readNullable<String>('creator') ?? '本地观看记录',
                  coverUrl: row.readNullable<String>('cover_url'),
                  durationSeconds: row.read<int>('duration_ms') ~/ 1000,
                  viewCount: row.readNullable<int>('view_count') ?? 0,
                ),
                partId: row.read<String>('part_id'),
                position: Duration(milliseconds: row.read<int>('position_ms')),
                updatedAt: row.read<DateTime>('updated_at'),
              ),
          ],
          nextCursor: rows.length > 24 ? '${offset + 24}' : null,
        ),
      );
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '本地观看记录暂不可用'));
    }
  }

  @override
  Future<Result<void>> rememberVideo(
    String ownerKey,
    VideoSummary video,
  ) async {
    try {
      await database
          .into(database.historyVideos)
          .insertOnConflictUpdate(
            HistoryVideosCompanion.insert(
              ownerKey: ownerKey,
              videoId: video.id,
              title: video.title,
              creator: video.creator,
              coverUrl: Value(video.coverUrl),
              durationSeconds: video.durationSeconds,
              viewCount: Value(video.viewCount),
            ),
          );
      return const Success(null);
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '观看信息未能保存'));
    }
  }

  Future<Result<void>> _delete(String ownerKey, String? videoId) async {
    try {
      await database.transaction(() async {
        await (database.delete(database.watchProgressRows)..where(
              (t) =>
                  t.ownerKey.equals(ownerKey) &
                  (videoId == null
                      ? const Constant(true)
                      : t.videoId.equals(videoId)),
            ))
            .go();
        await (database.delete(database.historyVideos)..where(
              (t) =>
                  t.ownerKey.equals(ownerKey) &
                  (videoId == null
                      ? const Constant(true)
                      : t.videoId.equals(videoId)),
            ))
            .go();
      });
      return const Success(null);
    } catch (_) {
      return const ResultFailure(AppFailure(FailureKind.storage, '本地记录未能删除'));
    }
  }

  @override
  Future<Result<void>> remove(String ownerKey, String videoId) =>
      _delete(ownerKey, videoId);
  @override
  Future<Result<void>> clear(String ownerKey) => _delete(ownerKey, null);
}
