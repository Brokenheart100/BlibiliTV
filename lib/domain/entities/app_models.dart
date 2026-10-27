import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_models.freezed.dart';

enum VideoOrder { relevance, newest, mostViewed }

@freezed
abstract class CatalogOptions with _$CatalogOptions {
  const factory CatalogOptions({
    @Default(0) int creatorId,
    @Default(VideoOrder.relevance) VideoOrder order,
    @Default(0) int duration,
  }) = _CatalogOptions;
}

enum SessionStatus {
  anonymous,
  restoring,
  authenticated,
  expired,
  offline,
  storageFailure,
}

@freezed
abstract class Session with _$Session {
  const Session._();
  const factory Session({
    @Default('guest') String ownerKey,
    String? displayName,
    @Default(SessionStatus.anonymous) SessionStatus status,
    @Default(0) int generation,
    String? notice,
  }) = _Session;
  bool get isAuthenticated =>
      status == SessionStatus.authenticated && ownerKey != 'guest';
  String get scopeKey => '$ownerKey:$generation';
}

@freezed
abstract class VideoSummary with _$VideoSummary {
  const factory VideoSummary({
    required String id,
    required String title,
    required String creator,
    required int durationSeconds,
    required int viewCount,
    String? coverUrl,
    String? creatorAvatarUrl,
  }) = _VideoSummary;
}

@freezed
abstract class VideoPart with _$VideoPart {
  const factory VideoPart({
    required String id,
    required String title,
    @Default(0) int durationSeconds,
  }) = _VideoPart;
}

@freezed
abstract class VideoDetail with _$VideoDetail {
  const factory VideoDetail({
    required VideoSummary video,
    required List<VideoPart> parts,
    required String description,
    String? creatorAvatarUrl,
    @Default(0) int creatorId,
  }) = _VideoDetail;
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(false) bool reducedMotion,
    @Default(true) bool resumePlayback,
    @Default(1.0) double defaultRate,
    @Default(0) int defaultQuality,
    @Default(false) bool autoNext,
    @Default(false) bool syncHistory,
    @Default(AppTheme.dark) AppTheme theme,
  }) = _AppSettings;
}

enum AppTheme { dark, light, system }
