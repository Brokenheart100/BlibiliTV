/// Read-only public protocol spike. Never prints credentials, URLs or content.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/danmaku/generated/danmaku.pb.dart'
    as wire;

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio);
  final signal = CancellationSignal();
  final report = <String, Object?>{
    'readOnly': true,
    'account': 'guest',
    'samples': <Object?>[],
  };
  try {
    final popular = await api.get(
      '/x/web-interface/popular',
      signal,
      query: {'ps': 5, 'pn': 1},
    );
    final ids = [
      'BV1wR4Xz6EqG',
      for (final row in popular['list']! as List)
        (row as Map)['bvid']! as String,
    ];
    for (final id in ids.take(4)) {
      final entry = <String, Object?>{'videoId': id};
      try {
        final detail = await api.get(
          '/x/web-interface/wbi/view',
          signal,
          signed: true,
          query: {'bvid': id},
        );
        final cid = ((detail['pages']! as List).first as Map)['cid']! as int;
        entry['cid'] = cid;
        entry['mid'] = (detail['owner']! as Map)['mid'];
        final info = await api.get(
          '/x/player/wbi/v2',
          signal,
          signed: true,
          query: {'bvid': id, 'cid': cid},
        );
        final subtitle = info['subtitle'] as Map?;
        final tracks = subtitle?['subtitles'] as List? ?? [];
        entry['subtitleCount'] = tracks.length;
        entry['subtitleFields'] = subtitle?.keys.toList();
        if (tracks.isNotEmpty) {
          final track = tracks.first as Map;
          var uri = track['subtitle_url'] as String;
          if (uri.startsWith('//')) uri = 'https:$uri';
          final body = await dio.get<Map<String, dynamic>>(
            uri,
            options: Options(headers: bilibiliMediaHeaders),
          );
          entry['cueCount'] = (body.data?['body'] as List?)?.length;
          entry['trackFields'] = track.keys.toList();
        }
        for (final kind in ['view', 'seg']) {
          final response = await dio.get<List<int>>(
            'https://api.bilibili.com/x/v2/dm/web/${kind == 'view' ? 'view' : 'seg.so'}',
            queryParameters: {
              'type': 1,
              'oid': cid,
              'pid': detail['aid'],
              if (kind == 'seg') 'segment_index': 1,
            },
            options: Options(
              responseType: ResponseType.bytes,
              headers: bilibiliMediaHeaders,
            ),
          );
          entry['dm${kind}Bytes'] = response.data?.length;
          if (kind == 'view') {
            final config = wire.WebView.fromBuffer(response.data!).dmSge;
            entry['segmentSize'] = config.pageSize.toInt();
            entry['segmentCount'] = config.total.toInt();
          } else {
            final items = wire.Segment.fromBuffer(response.data!).elems;
            entry['danmakuCount'] = items.length;
            entry['modes'] = items.map((e) => e.mode).toSet().toList();
          }
          await Directory('.m0/m8-public-probe').create(recursive: true);
          await File('.m0/m8-public-probe/$id-$kind.bin')
              .writeAsBytes(response.data!);
        }
      } catch (error) {
        entry['failure'] = error is AppFailure
            ? error.kind.name
            : error is DioException
            ? 'http:${error.response?.statusCode}'
            : error.runtimeType.toString();
      }
      (report['samples']! as List).add(entry);
    }
    report['remoteWrites'] = api.remoteWriteRequestsSent;
    await Directory('docs/m8-evidence').create(recursive: true);
    await File(
      'docs/m8-evidence/interface-spike.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } finally {
    api.close();
    dio.close(force: true);
  }
}
