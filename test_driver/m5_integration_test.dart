import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 45),
  responseDataCallback: (data) async {
    if (data == null) return;
    await Directory('docs/m5-evidence').create(recursive: true);
    final reportName = (data['soakSeconds'] as num? ?? 0) >= 1800
        ? 'native-profile.json'
        : 'native-short-profile.json';
    await File('docs/m5-evidence/$reportName')
        .writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
