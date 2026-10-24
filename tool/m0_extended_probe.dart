import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/m0/data/bilibili_probe_service.dart';
import 'package:mambatv/m0/data/wbi_signer.dart';

/// Bounded, read-only follow-up for multi-P, quality metadata and URL lifetime.
Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.bilibili.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: BilibiliProbeService.mediaHeaders,
    ),
  );
  try {
    final nav = objectMap(
      (await dio.get<Object?>('/x/web-interface/nav')).data,
    );
    final images = objectMap(objectMap(nav['data'])['wbi_img']);
    String key(Object? value) =>
        Uri.parse(value! as String).pathSegments.last.split('.').first;
    final image = key(images['img_url']);
    final sub = key(images['sub_url']);
    Future<Map<String, Object?>> get(
      String path,
      Map<String, Object> query,
    ) async {
      final response = await dio.get<Object?>(
        path,
        queryParameters: signWbi(
          query,
          image,
          sub,
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
      final root = objectMap(response.data);
      if (root['code'] != 0) throw ProbeFailure('business:${root['code']}');
      return objectMap(root['data']);
    }

    final popular = await get('/x/web-interface/popular', {'pn': 1, 'ps': 1});
    final first = objectMap((popular['list']! as List<Object?>).first);
    final bvid = first['bvid']! as String;
    final detail = await get('/x/web-interface/wbi/view', {'bvid': bvid});
    final playback = await get('/x/player/wbi/playurl', {
      'bvid': bvid,
      'cid': detail['cid']! as num,
      'qn': 32,
      'fnval': 4048,
      'fnver': 0,
      'fourk': 1,
    });
    final dash = objectMap(playback['dash']);
    final video = (dash['video']! as List<Object?>).map(objectMap).toList();
    final qualities =
        video.map((item) => (item['id']! as num).toInt()).toSet().toList()
          ..sort();
    final uri = Uri.parse(
      (video.first['baseUrl'] ?? video.first['base_url'])! as String,
    );
    final deadline = int.tryParse(uri.queryParameters['deadline'] ?? '');
    final search = await get('/x/web-interface/wbi/search/type', {
      'search_type': 'video',
      'keyword': 'Flutter',
      'page': 1,
    });
    final candidates = (search['result']! as List<Object?>)
        .map(objectMap)
        .take(5);
    Map<String, Object?> multipart = {
      'passed': false,
      'reason': 'not_found_in_first_five_results',
    };
    var inspected = 0;
    for (final candidate in candidates) {
      inspected++;
      final id = candidate['bvid']! as String;
      final metadata = await get('/x/web-interface/wbi/view', {'bvid': id});
      final pages = (metadata['pages']! as List<Object?>)
          .map(objectMap)
          .toList();
      if (pages.length < 2) continue;
      final cid1 = (pages[0]['cid']! as num).toInt();
      final cid2 = (pages[1]['cid']! as num).toInt();
      final second = await get('/x/player/wbi/playurl', {
        'bvid': id,
        'cid': cid2,
        'qn': 16,
        'fnval': 4048,
        'fnver': 0,
      });
      final secondDash = objectMap(second['dash']);
      multipart = {
        'passed':
            cid1 != cid2 && (secondDash['video']! as List<Object?>).isNotEmpty,
        'bvid': id,
        'parts': pages.length,
        'firstCid': cid1,
        'secondCid': cid2,
        'secondPartHasVideoAndAudio':
            (secondDash['video']! as List<Object?>).isNotEmpty &&
            (secondDash['audio']! as List<Object?>).isNotEmpty,
      };
      break;
    }
    final report = <String, Object?>{
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'bvid': bvid,
      'dashQualityIds': qualities,
      'urlDeadlinePresent': deadline != null,
      'observedUrlTtlSeconds': deadline == null
          ? null
          : deadline - DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'multipartCandidatesInspected': inspected,
      'multipart': multipart,
      'limitations': [
        'Quality IDs describe returned metadata, not all decoded profiles',
        'Actual expiry and re-resolution are not exercised',
      ],
      'credentialsAndUrlsRedacted': true,
    };
    final json = const JsonEncoder.withIndent('  ').convert(report);
    await File('docs/m0-evidence/extended-contracts.json')
        .writeAsString('$json\n');
    stdout.writeln(json);
  } catch (error) {
    stderr.writeln(describeFailure(error));
    exitCode = 1;
  } finally {
    dio.close(force: true);
  }
}
