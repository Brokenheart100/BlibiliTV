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
    const id = 'BV1wR4Xz6EqG';
    final detail = (await BilibiliCatalogRepository(
      api,
    ).getVideo(id, ownerKey: 'guest', cancellation: signal)).valueOrThrow;
    final part = detail.parts[1];
    final source = (await BilibiliPlaybackRepository(
      api,
    ).resolve(videoId: id, partId: part.id, cancellation: signal)).valueOrThrow;
    final metadata = await api.get(
      '/x/player/wbi/playurl',
      signal,
      signed: true,
      query: {
        'bvid': id,
        'cid': int.parse(part.id),
        'qn': 32,
        'fnval': 4048,
        'fnver': 0,
        'fourk': 1,
      },
    );
    final tracks = ((metadata['dash'] as Map<String, Object?>)['video'] as List)
        .cast<Map<String, Object?>>();
    final checks = <Object?>[];
    for (final (kind, url) in [
      ('video', source.videoUrl),
      ('audio', source.audioUrl),
    ]) {
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {...bilibiliMediaHeaders, 'Range': 'bytes=0-1023'},
          validateStatus: (_) => true,
        ),
      );
      checks.add({
        'kind': kind,
        'httpStatus': response.statusCode,
        'contentType': response.headers.value('content-type'),
        'receivedBytes': response.data?.length,
      });
    }
    final report = {
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'videoId': id,
      'part': 2,
      'cid': part.id,
      'codec': source.codec,
      'quality': source.quality,
      'tracks': tracks
          .map(
            (t) => {
              'id': t['id'],
              'codecs': t['codecs'],
              'width': t['width'],
              'height': t['height'],
            },
          )
          .toList(),
      'checks': checks,
      'signedUrlsPersisted': false,
    };
    await Directory('docs/m4-evidence').create(recursive: true);
    await File(
      'docs/m4-evidence/p2-network-probe.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(jsonEncode(report));
  } catch (error) {
    stderr.writeln(
      'P2 network probe failed: ${safeApiFailure(error).kind.name}; details redacted',
    );
    exitCode = 1;
  } finally {
    signal.cancel();
    api.close();
    dio.close(force: true);
  }
}
