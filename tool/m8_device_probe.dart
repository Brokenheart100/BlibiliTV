import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main(List<String> args) async {
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: Platform.environment['M8_VM_URI'],
  );
  try {
    final response = await driver.requestData(
      args.firstOrNull ?? 'm8-readonly',
      timeout: const Duration(minutes: 4),
    );
    final decoded = jsonDecode(response);
    if (decoded is Map && decoded.containsKey('error')) {
      throw StateError('Read-only validation entrypoint rejected the request');
    }
    if (args.isEmpty) {
      final data = jsonDecode(response) as Map<String, dynamic>;
      data['hostRecordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
      await Directory('docs/m8-evidence').create(recursive: true);
      await File(
        'docs/m8-evidence/real-readonly.json',
      ).writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(data));
    }
  } finally {
    await driver.close();
  }
}
