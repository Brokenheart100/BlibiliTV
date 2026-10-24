import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
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
  final report = <String, Object?>{
    'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'account': 'guest',
  };
  try {
    final feed = await api.get(
      '/x/web-interface/wbi/index/top/feed/rcmd',
      signal,
      signed: true,
      query: {
        'version': 1,
        'feed_version': 'V8',
        'homepage_ver': 1,
        'ps': 12,
        'fresh_idx': 1,
        'brush': 1,
        'fresh_type': 4,
      },
    );
    final items = feed['item'] as List;
    final video = items.whereType<Map<String, Object?>>().firstWhere(
      (r) => r['goto'] == 'av',
    );
    report['recommend'] = {
      'keys': feed.keys.toList(),
      'count': items.length,
      'itemKeys': video.keys.toList(),
      'sampleBvid': video['bvid'],
      'hasMore': feed['has_more'],
      'coverScheme': Uri.parse(video['pic']! as String).scheme,
    };
    final response = await dio.get<Object?>(
      'https://api.bilibili.com/x/web-interface/archive/related',
      queryParameters: {'bvid': video['bvid']},
      options: Options(headers: bilibiliMediaHeaders),
    );
    final root = response.data as Map;
    final related = root['data'] as List;
    report['related'] = {
      'code': root['code'],
      'count': related.length,
      'itemKeys': (related.first as Map).keys.toList(),
    };
    await Directory('docs/m4-evidence').create(recursive: true);
    await File(
      'docs/m4-evidence/discovery-contracts.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(jsonEncode(report));
  } catch (error) {
    stderr.writeln(
      'Discovery contract probe: ${safeApiFailure(error).kind.name}; details redacted',
    );
    exitCode = 1;
  } finally {
    signal.cancel();
    api.close();
    dio.close(force: true);
  }
}
