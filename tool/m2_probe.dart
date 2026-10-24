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
  try {
    final api = BilibiliApi(dio);
    final catalog = BilibiliCatalogRepository(api);
    final signal = CancellationSignal();
    final popular = (await catalog.fetchVideos(
      section: 'home',
      ownerKey: 'guest',
      cancellation: signal,
    )).valueOrThrow;
    final search = (await catalog.fetchVideos(
      section: 'search',
      ownerKey: 'guest',
      query: 'Flutter',
      cancellation: signal,
    )).valueOrThrow;
    final video = popular.items.firstWhere((v) => v.durationSeconds >= 60);
    final detail = (await catalog.getVideo(
      video.id,
      ownerKey: 'guest',
      cancellation: signal,
    )).valueOrThrow;
    final source = (await BilibiliPlaybackRepository(api).resolve(
      videoId: video.id,
      partId: detail.parts.first.id,
      cancellation: signal,
    )).valueOrThrow;
    final report = {
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'popularItems': popular.items.length,
      'nextPopularPage': popular.nextCursor,
      'searchItems': search.items.length,
      'nextSearchPage': search.nextCursor,
      'videoId': video.id,
      'partId': detail.parts.first.id,
      'partCount': detail.parts.length,
      'quality': source.quality,
      'codec': source.codec,
      'durationSeconds': source.duration.inSeconds,
      'separateAudio': true,
      'accountLoginAttempted': false,
    };
    await Directory('docs/m2-evidence').create(recursive: true);
    await File(
      'docs/m2-evidence/guest-contracts.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(jsonEncode(report));
  } catch (error) {
    stderr.writeln(
      error is AppFailure ? error.message : 'Contract verification failed',
    );
    exitCode = 1;
  } finally {
    dio.close(force: true);
  }
}
