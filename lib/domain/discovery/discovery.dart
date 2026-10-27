import '../../core/result.dart';
import '../entities/app_models.dart';

abstract interface class CreatorRepository {
  Future<Result<PageSlice<VideoSummary>>> creatorVideos({
    required int mid,
    required String ownerKey,
    required VideoOrder order,
    String? cursor,
    required CancellationSignal cancellation,
  });
}

abstract interface class FollowingFeedRepository {
  Future<Result<PageSlice<VideoSummary>>> followingVideos({
    required String ownerKey,
    String? cursor,
    required CancellationSignal cancellation,
  });
}
