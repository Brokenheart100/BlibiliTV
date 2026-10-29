import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 40),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;
    data['hostRecordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
    await Directory('docs/m9-evidence').create(recursive: true);
    await File(
      'docs/m9-evidence/${data['status'] == 'passed' ? 'native-validation' : 'rejected-native'}.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
  },
);
