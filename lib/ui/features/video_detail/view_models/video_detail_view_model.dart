import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/playback/playback.dart';
part 'video_detail_view_model.freezed.dart';
part 'video_detail_view_model.g.dart';

@freezed
abstract class VideoDetailState with _$VideoDetailState {
  const factory VideoDetailState({
    required VideoDetail detail,
    WatchProgress? resume,
    String? notice,
  }) = _VideoDetailState;
}

@riverpod
class VideoDetailViewModel extends _$VideoDetailViewModel {
  @override
  Future<VideoDetailState> build({
    required String id,
    required String pageId,
    required String ownerKey,
  }) async {
    final repository = ref.watch(catalogRepositoryProvider);
    final progress = ref.watch(progressRepositoryProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final signal = CancellationSignal();
    ref.onDispose(signal.cancel);
    final detail = (await repository.getVideo(
      id,
      ownerKey: ownerKey,
      cancellation: signal,
    )).valueOrThrow;
    if (detail.parts.isEmpty) {
      throw const AppFailure(FailureKind.unavailable, '此视频没有可播放的分集');
    }
    final saved = await progress.latestForVideo(ownerKey, id);
    final preferences = await settings.load();
    final resume = saved is Success<WatchProgress?> ? saved.value : null;
    final remember =
        preferences is Success<AppSettings> && preferences.value.resumePlayback;
    final valid =
        remember &&
        resume != null &&
        resume.isValid &&
        detail.parts.any((p) => p.id == resume.partId) &&
        resume.position < resume.duration - const Duration(seconds: 10);
    return VideoDetailState(
      detail: detail,
      resume: valid ? resume : null,
      notice: saved is ResultFailure ? '播放位置暂不可用，请稍后重试或检查本机存储' : null,
    );
  }
}

@riverpod
Future<List<VideoSummary>> relatedVideos(
  Ref ref, {
  required String id,
  required String pageId,
  required String ownerKey,
}) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final signal = CancellationSignal();
  ref.onDispose(signal.cancel);
  return (await repository.getRelated(
    id,
    ownerKey: ownerKey,
    cancellation: signal,
  )).valueOrThrow;
}
