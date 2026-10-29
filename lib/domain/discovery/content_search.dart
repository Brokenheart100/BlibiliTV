import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/result.dart';

part 'content_search.freezed.dart';

enum SearchCategory {
  video('视频'),
  bangumi('番剧'),
  cinema('影视'),
  live('直播');

  const SearchCategory(this.label);
  final String label;
  bool get poster => this == bangumi || this == cinema;
}

/// Search identities stay distinct from UGC BVIDs and playback episode IDs.
@freezed
sealed class ContentSearchItem with _$ContentSearchItem {
  const ContentSearchItem._();
  const factory ContentSearchItem.season({
    required String seasonId,
    required String title,
    required String subtitle,
    String? coverUrl,
  }) = SeasonSearchItem;
  const factory ContentSearchItem.live({
    required String roomId,
    required String title,
    required String subtitle,
    required bool broadcasting,
    String? coverUrl,
    String? avatarUrl,
  }) = LiveSearchItem;

  String get identity => switch (this) {
    SeasonSearchItem(:final seasonId) => 'season:$seasonId',
    LiveSearchItem(:final roomId) => 'live:$roomId',
  };
}

abstract interface class ContentSearchRepository {
  Future<Result<PageSlice<ContentSearchItem>>> search({
    required SearchCategory category,
    required String query,
    required String ownerKey,
    required CancellationSignal cancellation,
    String? cursor,
    bool forceRefresh = false,
  });
}
