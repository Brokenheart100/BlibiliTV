import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/repositories/bilibili_pgc_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio), signal = CancellationSignal();
  try {
    final season = (await BilibiliPgcRepository(
      api,
    ).season('281', signal)).valueOrThrow;
    final catalog = BilibiliCatalogRepository(api);
    final related = (await catalog.getRelated(
      'BV1wR4Xz6EqG',
      ownerKey: 'guest',
      cancellation: signal,
    )).valueOrThrow;
    final feed = (await catalog.fetchVideos(
      section: 'home',
      ownerKey: 'guest',
      cancellation: signal,
    )).valueOrThrow;
    final next = feed.nextCursor == null
        ? null
        : (await catalog.fetchVideos(
            section: 'home',
            ownerKey: 'guest',
            cursor: feed.nextCursor,
            cancellation: signal,
          )).valueOrThrow;
    final report = <String, Object?>{
      'clientDate': '2026-10-29',
      'owner': 'guest',
      'readOnly': true,
      'season': {
        'id': season.id,
        'title': season.title,
        'score': season.facts.score,
        'ratingCount': season.facts.ratingCount,
        'views': season.facts.views,
        'danmaku': season.facts.danmaku,
        'followText': season.facts.followText,
        'tags': season.facts.tags,
        'hasActors': season.facts.actors.isNotEmpty,
        'hasStaff': season.facts.staff.isNotEmpty,
        'episodeCount': season.episodes.length,
        'groupCount': season.groups.length,
        'episodesWithArtwork': season.episodes
            .where((e) => e.coverUrl?.startsWith('https://') == true)
            .length,
      },
      'discovery': {
        'relatedCount': related.length,
        'feedCount': feed.items.length,
        'nextPageCount': next?.items.length,
        'continued': next != null,
        'notice': feed.notice,
      },
      'remoteWrites': api.remoteWriteRequestsSent,
    };
    await Directory('docs/detail-layout-evidence').create(recursive: true);
    final json = '${const JsonEncoder.withIndent('  ').convert(report)}\n';
    await File('docs/detail-layout-evidence/interface-spike.json')
        .writeAsString(json);
    stdout.write(json);
  } finally {
    api.close();
    dio.close(force: true);
  }
}
