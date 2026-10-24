import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio);
  final signal = CancellationSignal();
  try {
    final repo = BilibiliCatalogRepository(api);
    final videos = (await repo.fetchVideos(
      section: 'search',
      ownerKey: 'guest',
      query: 'Flutter 2019',
      cancellation: signal,
    )).valueOrThrow.items;
    final found = <Object?>[];
    for (final video in videos.take(5)) {
      final detail = (await repo.getVideo(
        video.id,
        ownerKey: 'guest',
        cancellation: signal,
      )).valueOrThrow;
      if (detail.parts.length > 1) {
        final source = (await BilibiliPlaybackRepository(api).resolve(
          videoId: video.id,
          partId: detail.parts[1].id,
          cancellation: signal,
        )).valueOrThrow;
        found.add({
          'bvid': video.id,
          'parts': detail.parts.length,
          'codec': source.codec,
          'quality': source.quality,
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (found.length == 3) break;
    }
    stdout.writeln(jsonEncode(found));
  } catch (error) {
    stderr.writeln(
      'Candidate check failed: ${safeApiFailure(error).kind.name}',
    );
    exitCode = 1;
  } finally {
    signal.cancel();
    api.close();
    dio.close(force: true);
  }
}
