import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: Platform.environment['M6_VM_URI'],
  );
  try {
    final response = await driver.requestData(
      'm6-readonly',
      timeout: const Duration(minutes: 3),
    );
    final report = jsonDecode(response) as Map<String, Object?>;
    await Directory('docs/m6-evidence').create(recursive: true);
    await File(
      'docs/m6-evidence/real-readonly.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } finally {
    await driver.close();
  }
}
