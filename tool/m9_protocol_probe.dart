import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_pgc_repository.dart';
import 'package:mambatv/data/repositories/bilibili_live_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio);
  final pgc = BilibiliPgcRepository(api), live = BilibiliLiveRepository(api);
  final signal = CancellationSignal();
  final report = <String, Object?>{
    'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'owner': 'guest',
    'readOnly': true,
    'referenceCommit': 'affac5334fc41744894618d9fb53b7101db9532a',
  };
  try {
    final listing = await pgc.browse(signal);
    report['pgcCatalog'] = listing is Success
        ? {'status': 'passed', 'count': listing.valueOrThrow.items.length}
        : {'status': 'failed'};
    final season = (await pgc.season('28320', signal)).valueOrThrow;
    report['season'] = {
      'id': season.id,
      'episodeCount': season.episodes.length,
      'additionalGroups': season.groups.length,
    };
    final free = await pgc.resolve(
      const PlaybackTarget.pgc(seasonId: '28320', episodeId: '280924')
          as PgcTarget,
      signal,
    );
    report['freeEpisode'] = free is Success<PlaybackSource>
        ? {
            'status': 'passed',
            'transport': free.value.transport.name,
            'durationSeconds': free.value.duration.inSeconds,
            'videoDashMetadata': free.value.videoDash != null,
            'audioDashMetadata': free.value.audioDash != null,
          }
        : {
            'status': 'failed',
            'kind': (free as ResultFailure).failure.kind.name,
          };
    final restricted = await pgc.resolve(
      const PlaybackTarget.pgc(seasonId: '28320', episodeId: '285889')
          as PgcTarget,
      signal,
    );
    report['restrictedEpisode'] = {
      'status':
          restricted is ResultFailure<PlaybackSource> &&
              restricted.failure.kind == FailureKind.permission
          ? 'passed'
          : 'failed',
      'sourceWithheld': restricted is ResultFailure,
    };
    final liveList = await live.browse(signal);
    report['liveCatalog'] = liveList is Success
        ? {'status': 'passed', 'count': liveList.valueOrThrow.items.length}
        : {
            'status': 'blocked',
            'kind': (liveList as ResultFailure).failure.kind.name,
          };
    final room = (await live.room('6', signal)).valueOrThrow;
    report['room'] = {
      'requestedId': '6',
      'canonicalId': room.id,
      'live': room.live,
      'locked': room.locked,
    };
    if (room.live && !room.locked) {
      final source = (await live.resolve(room.id, signal)).valueOrThrow;
      final playlist = await dio.get<String>(
        source.videoUrl,
        options: Options(
          headers: source.headers,
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );
      final text = playlist.data ?? '';
      report['liveSource'] = {
        'status': playlist.statusCode == 200 && text.startsWith('#EXTM3U')
            ? 'passed'
            : 'failed',
        'transport': source.transport.name,
        'quality': source.quality,
        'qualityOptions': source.qualities.where((q) => q.available).length,
        'backupCount': source.videoBackups.length,
        'playlistBytes': utf8.encode(text).length,
        'cleartextChildUri': text
            .split('\n')
            .any((line) => line.trim().startsWith('http://')),
      };
    }
    report['remoteWrites'] = api.remoteWriteRequestsSent;
    await Directory('docs/m9-evidence').create(recursive: true);
    await File(
      'docs/m9-evidence/interface-spike.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } catch (e) {
    stdout.writeln(
      jsonEncode({'status': 'failed', 'kind': safeApiFailure(e).kind.name}),
    );
    exitCode = 1;
  } finally {
    api.close();
    dio.close(force: true);
  }
}
