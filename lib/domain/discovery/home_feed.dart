/// Home navigation identifiers also isolate feed state and focus memory.
enum HomeFeed {
  recommendation('home', '个性推荐'),
  following('following', '正在关注'),
  popular('popular', '热门视频'),
  weekly('weekly', '每周必看'),
  ranking('ranking', '排行'),
  live('live', '直播');

  const HomeFeed(this.section, this.label);
  final String section, label;
  String get location =>
      this == recommendation ? '/home' : '/home?feed=$section';
  static HomeFeed fromSection(String? section) => values.firstWhere(
    (feed) => feed.section == section,
    orElse: () => recommendation,
  );
}
