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
      await Directory('docs/m8-evidence').create(recursive: true);
      final danmakuOnly = Platform.environment['M8_DANMAKU_ONLY'] == 'true';
      final realOnly = Platform.environment['M8_SYNTHETIC_PER_SECOND'] == '0';
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
        'docs/m8-evidence/$name',
      ).writeAsString('${const JsonEncoder.withIndent('  ').convert(data)}\n');
    },
  );
}
