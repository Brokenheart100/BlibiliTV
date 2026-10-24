import '../../core/result.dart';
import '../entities/app_models.dart';

abstract interface class CatalogRepository {
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    required CancellationSignal cancellation,
  });
  Future<Result<VideoDetail>> getVideo(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  });
  Future<Result<List<VideoSummary>>> getRelated(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  });
}

abstract interface class SearchHistoryRepository {
  Future<Result<List<String>>> load(String ownerKey);
  Future<Result<void>> remember(String ownerKey, String query);
  Future<Result<void>> clear(String ownerKey);
}

abstract interface class SessionRepository {
  Session get current;
  Future<void> restore();
  Future<void> revalidate({bool force = false});
  Future<Result<void>> logout();
  Stream<Session> watch();
}

abstract interface class SettingsRepository {
  Future<Result<AppSettings>> load();
  Future<Result<void>> save(AppSettings settings);
}
