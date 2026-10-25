import 'dart:async';

import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';

VideoSummary libraryVideo(String id) => VideoSummary(
  id: id,
  title: '合成视频 $id',
  creator: '测试作者',
  durationSeconds: 120,
  viewCount: 1,
);

class MemoryLocalHistory implements LocalHistoryRepository {
  final entries = <String, List<LibraryEntry>>{};
  int clears = 0;
  @override
  Future<Result<PageSlice<LibraryEntry>>> list(
    String ownerKey, {
    String? cursor,
  }) async => Success(PageSlice(items: entries[ownerKey] ?? []));
  @override
  Future<Result<void>> rememberVideo(
    String ownerKey,
    VideoSummary video,
  ) async => const Success(null);
  @override
  Future<Result<void>> remove(String ownerKey, String videoId) async {
    entries[ownerKey]?.removeWhere((e) => e.video.id == videoId);
    return const Success(null);
  }

  @override
  Future<Result<void>> clear(String ownerKey) async {
    clears++;
    entries.remove(ownerKey);
    return const Success(null);
  }
}

class FakeLibraryRepository implements LibraryRepository {
  final calls = <(String, LibrarySection, String?)>[];
  final signals = <CancellationSignal>[];
  final pages = <String, PageSlice<LibraryEntry>>{};
  Completer<Result<PageSlice<LibraryEntry>>>? gate;
  AppFailure? listFailure;
  int writes = 0, heartbeats = 0, reads = 0;
  bool later = false, uncertain = false;
  List<FavouriteFolder> folders = [const FavouriteFolder('1', '测试收藏夹')];
  @override
  Future<Result<PageSlice<LibraryEntry>>> list({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    calls.add((ownerKey, section, cursor));
    signals.add(cancellation);
    if (gate != null) return gate!.future;
    if (listFailure != null) return ResultFailure(listFailure!);
    return Success(pages[cursor ?? 'first'] ?? PageSlice(items: []));
  }

  @override
  Future<Result<LibraryMembership>> membership({
    required String ownerKey,
    required String videoId,
    required int aid,
    required CancellationSignal cancellation,
  }) async {
    reads++;
    return Success(
      LibraryMembership(aid: 7, watchLater: later, folders: folders),
    );
  }

  @override
  Future<Result<LibraryWriteResult>> change({
    required String ownerKey,
    required String videoId,
    required int aid,
    String? folderId,
    required bool desired,
    required CancellationSignal cancellation,
  }) async {
    writes++;
    if (uncertain) {
      return Success(
        LibraryWriteResult(
          WriteStatus.uncertain,
          '待确认',
          pendingDesired: desired,
          pendingFolder: folderId,
        ),
      );
    }
    later = desired;
    return const Success(LibraryWriteResult(WriteStatus.confirmed, '已确认'));
  }

  @override
  Future<Result<void>> heartbeat({
    required String ownerKey,
    required String videoId,
    required String partId,
    required int seconds,
    required CancellationSignal cancellation,
  }) async {
    heartbeats++;
    return const Success(null);
  }
}
