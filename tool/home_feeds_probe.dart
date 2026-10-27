import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(dio);
  final repo = BilibiliCatalogRepository(api);
  final report = <String, Object?>{
    'readOnly': true,
    'authenticated': false,
    'feeds': <Object?>[],
  };
  try {
    for (final section in ['weekly', 'ranking']) {
      final row = <String, Object?>{'section': section};
      try {
        final first = (await repo.fetchVideos(
          section: section,
          ownerKey: 'guest',
          cancellation: CancellationSignal(),
        )).valueOrThrow;
        row['count'] = first.items.length;
        row['hasMore'] = first.nextCursor != null;
        if (first.nextCursor != null) {
          final next = (await repo.fetchVideos(
            section: section,
            ownerKey: 'guest',
            cursor: first.nextCursor,
            cancellation: CancellationSignal(),
          )).valueOrThrow;
          row['nextCount'] = next.items.length;
          row['overlap'] = next.items
              .where((item) => first.items.any((old) => old.id == item.id))
              .length;
        }
        row['status'] = first.items.isEmpty ? 'empty' : 'passed';
      } catch (error) {
        row['status'] = 'failed';
        row['failure'] = error is AppFailure
            ? error.kind.name
            : error.runtimeType.toString();
      }
      (report['feeds']! as List).add(row);
    }
    report['remoteWrites'] = api.remoteWriteRequestsSent;
    report['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    await Directory('docs/appearance-evidence').create(recursive: true);
    await File(
      'docs/appearance-evidence/public-feeds.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(jsonEncode(report));
  } finally {
    api.close();
    dio.close(force: true);
  }
}
