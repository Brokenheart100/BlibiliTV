import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 6),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;
    data['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    await Directory('docs/playback-buffer-evidence').create(recursive: true);
    await File('docs/playback-buffer-evidence/native-validation.json')
        .writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
