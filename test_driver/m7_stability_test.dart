import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 40),
  responseDataCallback: (data) async {
    if (data == null) return;
    await Directory('docs/m7-evidence').create(recursive: true);
    final name = data['fifteenMinuteThresholdMet'] == true
        ? 'native-15-minute.json'
        : 'native-smoke.json';
    await File('docs/m7-evidence/$name')
        .writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
