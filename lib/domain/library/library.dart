import '../../core/result.dart';
import '../entities/app_models.dart';
import '../playback/playback_target.dart';

enum LibrarySection { local, remote, folders, folder, watchLater }

final class LibraryEntry {
  const LibraryEntry({
    required this.key,
    required this.video,
    this.partId,
    this.position = Duration.zero,
    this.updatedAt,
    this.folderId,
    this.count = 0,
    this.unavailableReason,
    this.target,
  });
  final String key;
  final VideoSummary video;
  final String? partId, folderId, unavailableReason;
  final Duration position;
  final DateTime? updatedAt;
  final int count;
  final PlaybackTarget? target;
}

final class FavouriteFolder {
  const FavouriteFolder(this.id, this.title, {this.selected = false});
  final String id, title;
  final bool selected;
}

final class LibraryMembership {
  LibraryMembership({
    required this.watchLater,
    required List<FavouriteFolder> folders,
    this.aid = 0,
  }) : folders = List.unmodifiable(folders);
  final bool watchLater;
  final int aid;
  final List<FavouriteFolder> folders;
}

enum WriteStatus { confirmed, rejected, uncertain }

final class LibraryWriteResult {
  const LibraryWriteResult(
    this.status,
    this.message, {
    this.pendingDesired,
    this.pendingFolder,
  });
  final WriteStatus status;
  final String message;
  final bool? pendingDesired;
  final String? pendingFolder;
}

abstract interface class LocalHistoryRepository {
  Future<Result<PageSlice<LibraryEntry>>> list(
    String ownerKey, {
    String? cursor,
  });
  Future<Result<void>> rememberVideo(String ownerKey, VideoSummary video);
  Future<Result<void>> remove(String ownerKey, String videoId);
  Future<Result<void>> clear(String ownerKey);
}

abstract interface class TypedLocalHistoryRepository {
  Future<Result<void>> removeTarget(String ownerKey, PlaybackTarget target);
}

abstract interface class LibraryRepository {
  Future<Result<PageSlice<LibraryEntry>>> list({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  });
  Future<Result<LibraryMembership>> membership({
    required String ownerKey,
    required String videoId,
    required int aid,
    required CancellationSignal cancellation,
  });
  Future<Result<LibraryWriteResult>> change({
    required String ownerKey,
    required String videoId,
    required int aid,
    String? folderId,
    required bool desired,
    required CancellationSignal cancellation,
  });
  Future<Result<void>> heartbeat({
    required String ownerKey,
    required String videoId,
    required String partId,
    required int seconds,
    required CancellationSignal cancellation,
  });
}
