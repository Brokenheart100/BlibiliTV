import '../../core/result.dart';
import '../entities/app_models.dart';

enum PersonalSection {
  submissions('我的投稿'),
  folders('收藏夹'),
  bangumi('追番'),
  drama('追剧'),
  watchLater('稍后再看');

  const PersonalSection(this.label);
  final String label;
}

final class PersonalProfile {
  const PersonalProfile({
    required this.mid,
    required this.name,
    this.avatarUrl,
  });
  final int mid;
  final String name;
  final String? avatarUrl;
}

sealed class PersonalItem {
  const PersonalItem();
  String get key;
  String get title;
  String get subtitle;
  String? get coverUrl;
}

final class PersonalVideo extends PersonalItem {
  const PersonalVideo(this.video, {this.unavailableReason});
  final VideoSummary video;
  final String? unavailableReason;
  @override
  String get key => video.id;
  @override
  String get title => video.title;
  @override
  String get subtitle => unavailableReason ?? video.creator;
  @override
  String? get coverUrl => video.coverUrl;
}

final class PersonalFolder extends PersonalItem {
  const PersonalFolder({
    required this.id,
    required this.title,
    required this.count,
    this.coverUrl,
  });
  final String id;
  final int count;
  @override
  final String title;
  @override
  final String? coverUrl;
  @override
  String get key => 'folder:$id';
  @override
  String get subtitle => '$count 个视频';
}

/// A followed season is deliberately separate from a playable UGC video.
final class PersonalSeason extends PersonalItem {
  const PersonalSeason({
    required this.id,
    required this.title,
    required this.subtitle,
    this.coverUrl,
    this.progress = '',
    this.badge = '',
  });
  final int id;
  final String progress, badge;
  @override
  final String title, subtitle;
  @override
  final String? coverUrl;
  @override
  String get key => 'season:$id';
}

abstract interface class PersonalHomeRepository {
  Future<Result<PersonalProfile>> profile(
    String ownerKey,
    CancellationSignal cancellation,
  );
  Future<Result<PageSlice<PersonalItem>>> list({
    required String ownerKey,
    required PersonalSection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  });
}
