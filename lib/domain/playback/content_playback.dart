import '../../core/result.dart';
import '../entities/app_models.dart';
import 'playback.dart';
import 'playback_target.dart';

final class ContentEpisode {
  const ContentEpisode({
    required this.id,
    required this.title,
    required this.cid,
    required this.bvid,
    this.badge = '',
    this.restricted = false,
    this.coverUrl,
  });
  final String id, title, cid, bvid, badge;
  final bool restricted;
  final String? coverUrl;
}

final class ContentSeason {
  ContentSeason({
    required this.id,
    required this.title,
    required this.description,
    required List<ContentEpisode> episodes,
    this.coverUrl,
    this.groups = const {},
    this.facts = const SeasonFacts(),
  }) : episodes = List.unmodifiable(episodes);
  final String id, title, description;
  final String? coverUrl;
  final List<ContentEpisode> episodes;
  final Map<String, List<ContentEpisode>> groups;
  final SeasonFacts facts;
}

/// Optional public metadata. Missing values never become invented zero counts.
final class SeasonFacts {
  const SeasonFacts({
    this.tags = const [],
    this.views,
    this.danmaku,
    this.followText = '',
    this.score,
    this.ratingCount,
    this.published = '',
    this.status = '',
    this.actors = '',
    this.staff = '',
  });
  final List<String> tags;
  final int? views, danmaku, ratingCount;
  final double? score;
  final String followText, published, status, actors, staff;
}

final class LiveRoom {
  const LiveRoom({
    required this.id,
    required this.title,
    required this.creator,
    required this.live,
    this.coverUrl,
    this.locked = false,
  });
  final String id, title, creator;
  final bool live, locked;
  final String? coverUrl;
}

abstract interface class PgcRepository {
  Future<Result<PageSlice<VideoSummary>>> browse(
    CancellationSignal cancellation, {
    int page = 1,
    String keyword = '',
  });
  Future<Result<ContentSeason>> season(
    String id,
    CancellationSignal cancellation,
  );
  Future<Result<PlaybackSource>> resolve(
    PgcTarget target,
    CancellationSignal cancellation, {
    int? quality,
    int? audioId,
  });
}

abstract interface class LiveRepository {
  Future<Result<PageSlice<LiveRoom>>> browse(
    CancellationSignal cancellation, {
    int page = 1,
    String keyword = '',
  });
  Future<Result<LiveRoom>> room(String id, CancellationSignal cancellation);
  Future<Result<PlaybackSource>> resolve(
    String roomId,
    CancellationSignal cancellation, {
    int? quality,
  });
}

abstract interface class ContentProgressRepository {
  Future<Result<WatchProgress?>> loadTarget(
    String ownerKey,
    PlaybackTarget target,
  );
  Future<Result<void>> rememberTarget(
    String ownerKey,
    PlaybackTarget target,
    VideoSummary metadata,
  );
}
