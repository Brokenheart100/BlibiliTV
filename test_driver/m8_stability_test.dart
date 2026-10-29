import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final hostClock = Stopwatch()..start();
  await integrationDriver(
    writeResponseOnFailure: true,
    timeout: const Duration(minutes: 40),
    responseDataCallback: (data) async {
      if (data == null) return;
      data['hostRecordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
      data['hostDriverElapsedMs'] = hostClock.elapsedMilliseconds;
      const output = 'docs/m8-performance-evidence';
      await Directory(output).create(recursive: true);
      final label = Platform.environment['M8_RUN_LABEL'] ?? 'current';
      if (!RegExp(r'^[a-z0-9_-]{1,48}$').hasMatch(label)) {
        throw ArgumentError('Invalid M8_RUN_LABEL');
      }
      final danmakuOnly = data['danmakuOnly'] == true;
      final realOnly = data['syntheticDanmakuPerSecond'] == 0;
      final prefix = danmakuOnly
          ? realOnly
                ? 'danmaku-real-'
                : 'danmaku-'
          : '';
      final name = data['status'] != 'passed'
          ? '${prefix}rejected-native.json'
          : data['fifteenMinuteThresholdMet'] == true
          ? '${prefix}native-15-minute.json'
          : '${prefix}native-smoke.json';
      await File(
        '$output/$label-$name',
      ).writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
    },
  );
}
