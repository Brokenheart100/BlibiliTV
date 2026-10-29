import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/m0/data/bilibili_probe_service.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'M0 real DASH through Better Player: timeline, pause, seek, storage',
    (tester) async {
      final service = BilibiliProbeService();
      final player = BetterPlayerEngine();
      final errors = <String>[];
      final subscription = player.snapshots.listen((snapshot) {
        if (snapshot.failure != null) errors.add(snapshot.failure!.kind.name);
      });
      addTearDown(() async {
        await subscription.cancel();
        await player.dispose();
        service.close();
      });
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BetterPlayerSurface(player))),
      );
      final checks = await service.probeGuest();
      expect(
        checks.where((check) => !check.passed),
        isEmpty,
        reason: 'Real API contract must pass before playback',
      );
      final media = service.media!;
      final watch = Stopwatch()..start();
      await tester.runAsync(
        () => player.open(media.source, startAt: Duration.zero),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while ((player.snapshot.position.inSeconds < 2 ||
              player.snapshot.width == 0) &&
          DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      final readyMs = watch.elapsedMilliseconds;
      expect(player.snapshot.width, greaterThan(0));
      expect(player.snapshot.height, greaterThan(0));
      expect(player.snapshot.position.inSeconds, greaterThanOrEqualTo(2));
      await tester.runAsync(player.pause);
      await tester.pump(const Duration(milliseconds: 500));
      final pausedPosition = player.snapshot.position;
      await tester.pump(const Duration(milliseconds: 750));
      expect(player.snapshot.playing, isFalse);
      expect(
        (player.snapshot.position - pausedPosition).inMilliseconds.abs(),
        lessThan(500),
      );
      await tester.runAsync(() => player.seek(const Duration(seconds: 10)));
      await tester.runAsync(player.play);
      final seekDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (player.snapshot.position.inSeconds < 10 &&
          DateTime.now().isBefore(seekDeadline)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(player.snapshot.position.inSeconds, greaterThanOrEqualTo(10));
      expect(player.snapshot.position.inSeconds, lessThan(15));
      expect(errors, isEmpty);

      const storage = FlutterSecureStorage();
      const key = 'm0.synthetic_storage_probe';
      await storage.write(key: key, value: 'synthetic-nonsecret-value');
      expect(await storage.read(key: key), 'synthetic-nonsecret-value');
      await storage.delete(key: key);
      expect(await storage.read(key: key), isNull);

      final evidence = <String, Object?>{
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'bvid': media.bvid,
        'cid': media.cid,
        'codec': media.codec,
        'quality': media.quality,
        'backend': 'better_player',
        'timelineReadyMs': readyMs,
        'width': player.snapshot.width,
        'height': player.snapshot.height,
        'audioSampleRate': null,
        'audioChannels': null,
        'audioMetricsAvailable': false,
        'pausePassed': true,
        'seekPositionMs': player.snapshot.position.inMilliseconds,
        'secureStorageSyntheticRoundTrip': true,
        'engineErrorCount': errors.length,
        'mediaUrlsRedacted': true,
        'limitation': 'Native size and playback timeline evidence only; no separate audio PTS or human audibility measurement',
      };
      binding.reportData = evidence;
      // This object is deliberately sanitized; never print PlayerState or Media.
      debugPrint('M0_EVIDENCE:${jsonEncode(evidence)}');
      await tester.runAsync(player.pause);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
