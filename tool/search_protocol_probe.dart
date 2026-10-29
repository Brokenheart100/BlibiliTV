import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_content_search_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/discovery/content_search.dart';

/// Public, read-only contract check; no account or signed playback URL is stored.
Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio);
  final repository = BilibiliContentSearchRepository(api);
  final report = <String, Object?>{
    'clientDate': '2026-10-29',
    'owner': 'guest',
    'referenceCommit': 'affac5334fc41744894618d9fb53b7101db9532a',
    'readOnly': true,
  };
  var passed = true;
  try {
    for (final pair in {
      SearchCategory.bangumi: '鬼灭之刃',
      SearchCategory.cinema: '流浪地球',
      SearchCategory.live: '哔哩哔哩',
    }.entries) {
      final result = await repository.search(
        category: pair.key,
        query: pair.value,
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      );
      if (result case Success(:final value)) {
        final item = value.items.firstOrNull;
        report[pair.key.name] = {
          'status': item == null ? 'empty' : 'passed',
          'count': value.items.length,
          'firstIdentity': item?.identity,
          'firstTitle': item?.title,
          'hasNextPage': value.nextCursor != null,
        };
        passed &= item != null;
        if (value.nextCursor != null) {
          final more = await repository.search(
            category: pair.key,
            query: pair.value,
            ownerKey: 'guest',
            cancellation: CancellationSignal(),
            cursor: value.nextCursor,
          );
          report['${pair.key.name}Page2'] =
              more is Success<PageSlice<ContentSearchItem>>
              ? {'status': 'passed', 'count': more.value.items.length}
              : {
                  'status': 'failed',
                  'kind': (more as ResultFailure).failure.kind.name,
                };
          passed &= more is Success<PageSlice<ContentSearchItem>>;
        }
      } else {
        passed = false;
        report[pair.key.name] = {
          'status': 'failed',
          'kind': (result as ResultFailure).failure.kind.name,
        };
      }
    }
    report['remoteWrites'] = api.remoteWriteRequestsSent;
    report['status'] = passed ? 'passed' : 'incomplete';
    await Directory('docs/search-glass-evidence').create(recursive: true);
    final json = '${const JsonEncoder.withIndent('  ').convert(report)}\n';
    await File('docs/search-glass-evidence/interface-spike.json')
        .writeAsString(json);
    stdout.write(json);
    if (!passed) {
      exitCode = 1;
    }
  } finally {
    api.close();
    dio.close(force: true);
  }
}
