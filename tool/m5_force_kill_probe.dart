import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

// Run only after a debug product player is playing the selected public video.
// Copies stay in ignored .m0; only the requested guest row enters the report.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 ||
      !RegExp(r'^BV[a-zA-Z0-9]+$').hasMatch(arguments[0]) ||
      !RegExp(r'^\d+$').hasMatch(arguments[1])) {
    throw ArgumentError('Expected a public BV id and CID');
  }
  final adb = Platform.environment['M5_ADB'] ?? 'adb';
  final device = Platform.environment['M5_DEVICE'] ?? 'emulator-5554';
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: Platform.environment['M5_VM_URI'],
  );
  late String clockText;
  late int latency;
  try {
    await driver.tap(find.byType('PlayerPage'));
    final clock = Stopwatch()..start();
    clockText = await driver.getText(find.byValueKey('player-position'));
    final result = await Process.run(adb, [
      '-s',
      device,
      'shell',
      'am',
      'force-stop',
      'app.mamba.mambatv',
    ]);
    latency = clock.elapsedMilliseconds;
    if (result.exitCode != 0) throw StateError('Force-stop failed');
  } finally {
    try {
      await driver.close();
    } catch (_) {
      /* The process has intentionally stopped. */
    }
  }
  final components = clockText.split(':').map(int.parse);
  final seconds = components.fold(0, (total, value) => total * 60 + value);
  await Directory('.m0/m5-kill-snapshot').create(recursive: true);
  for (final (remote, local) in [
    ('app_flutter/mambatv.sqlite', '.m0/m5-kill-snapshot/mambatv.sqlite'),
    (
      'app_flutter/mambatv.sqlite-wal',
      '.m0/m5-kill-snapshot/mambatv.sqlite-wal',
    ),
    (
      'app_flutter/mambatv.sqlite-shm',
      '.m0/m5-kill-snapshot/mambatv.sqlite-shm',
    ),
  ]) {
    final file = File(local);
    if (await file.exists()) await file.delete();
    final result = await Process.run(adb, [
      '-s',
      device,
      'exec-out',
      'run-as',
      'app.mamba.mambatv',
      'cat',
      remote,
    ], stdoutEncoding: null);
    if (result.exitCode == 0) {
      await file.writeAsBytes(result.stdout as List<int>);
    }
  }
  final read = await Process.run(
    Platform.environment['M5_PYTHON'] ?? 'python',
    [
      'tool/read_m5_progress.py',
      '.m0/m5-kill-snapshot/mambatv.sqlite',
      arguments[0],
      arguments[1],
    ],
  );
  if (read.exitCode != 0) throw StateError('Guest progress query failed');
  final row = jsonDecode(read.stdout as String) as Map<String, Object?>;
  if (row['found'] != true) throw StateError('No matching guest progress');
  final stored = row['positionMs']! as int;
  // One second for display rounding and one for the last rendered clock update.
  final upperBound = (seconds + 2) * 1000 + latency - stored;
  final report = <String, Object?>{
    'recordedAtHostUtc': DateTime.now().toUtc().toIso8601String(),
    'identity': 'guest',
    'videoId': arguments[0],
    'partId': arguments[1],
    'observedUiClock': clockText,
    'readAndKillLatencyMs': latency,
    'clockRoundingAndRenderingMarginMs': 2000,
    'storedPositionMs': stored,
    'durationMs': row['durationMs'],
    'lossUpperBoundMs': upperBound,
    'withinFiveSecondsPlusOneSecondSchedulingMargin': upperBound <= 6000,
    'scope': 'current debug product app; only its selected guest progress row queried',
  };
  await Directory('docs/m5-evidence').create(recursive: true);
  await File('docs/m5-evidence/force-kill.json')
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
