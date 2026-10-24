import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main(List<String> arguments) async {
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: Platform.environment['M3_VM_URI'],
  );
  try {
    final result = jsonDecode(
      await driver.requestData(
        arguments.single,
        timeout: const Duration(seconds: 60),
      ),
    );
    stdout.writeln(jsonEncode(result));
  } finally {
    await driver.close();
  }
}
