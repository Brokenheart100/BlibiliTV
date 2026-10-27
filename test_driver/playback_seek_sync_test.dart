import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  timeout: const Duration(minutes: 20),
  responseDataCallback: (data) async {
    if (data == null) return;
    await Directory('docs/playback-fix-evidence').create(recursive: true);
    final variants = data['variants'] as List? ?? [];
    final soak = variants.isEmpty
        ? 0
        : (variants.first as Map)['soakSeconds'] as int? ?? 0;
    final name = data['experiments'] == true
        ? 'seek-diagnostic'
        : data['status'] != 'passed'
        ? 'seek-rejected'
        : soak >= 900
        ? 'seek-validation'
        : 'seek-smoke';
    data['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    await File('docs/playback-fix-evidence/$name.json')
        .writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
