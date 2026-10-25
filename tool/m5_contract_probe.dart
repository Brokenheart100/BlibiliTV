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
  try {
    final catalog = BilibiliCatalogRepository(api);
    final page = (await catalog.fetchVideos(
      section: 'search',
      ownerKey: 'guest',
      query: '缅北电诈覆灭纪实 第一集',
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    final rows = <Map<String, Object?>>[];
    for (final video
        in page.items.where((v) => v.durationSeconds >= 2000).take(3)) {
      final detail = (await catalog.getVideo(
        video.id,
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      final longParts = detail.parts.where((p) => p.durationSeconds >= 2000);
      if (longParts.isEmpty) continue;
      final part = longParts.first;
      final source = (await BilibiliPlaybackRepository(api).resolve(
        videoId: video.id,
        partId: part.id,
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      rows.add({
        'videoId': video.id,
        'partId': part.id,
        'durationSeconds': source.duration.inSeconds,
        'quality': source.quality,
        'availableQualities': [
          for (final q in source.qualities.where((q) => q.available)) q.id,
        ],
        'audioIds': [for (final a in source.audioTracks) a.id],
        'pairedBackup': source.alternate != null,
      });
    }
    final output = File('docs/m5-evidence/playback-contracts.json');
    await output.parent.create(recursive: true);
    final report = {
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'identity': 'guest',
      'candidates': rows,
    };
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } finally {
    api.close();
    dio.close(force: true);
  }
}
