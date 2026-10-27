import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;
    await Directory('docs/audio-output-evidence').create(recursive: true);
    final prefix = Platform.environment['AUDIO_REPORT_PREFIX'] ?? 'comparison';
    await File('docs/audio-output-evidence/$prefix.json')
        .writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
