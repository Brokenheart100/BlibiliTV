import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mambatv/m0/data/bilibili_probe_service.dart';
import 'package:mambatv/m0/data/playback_configuration.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  testWidgets(
    'M0 real DASH video and external audio: frame, pause, seek, storage',
    (tester) async {
      final service = BilibiliProbeService();
      final player = Player();
      final controller = VideoController(
        player,
        configuration: probeVideoConfiguration(),
      );
      final errors = <String>[];
      final subscription = player.stream.error.listen(
        (_) => errors.add('redacted_engine_error'),
      );
      addTearDown(() async {
        await subscription.cancel();
        await player.dispose();
        service.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Video(controller: controller, controls: null)),
        ),
      );
      final checks = await service.probeGuest();
      expect(
        checks.where((check) => !check.passed),
        isEmpty,
        reason: 'Real API contract must pass before playback',
      );
      final media = service.media!;
      final watch = Stopwatch()..start();
      await player.open(
        Media(media.videoUrl, httpHeaders: BilibiliProbeService.mediaHeaders),
        play: false,
      );
      await player.setAudioTrack(AudioTrack.uri(media.audioUrl));
      await player.play();
      await controller.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 45),
      );
      final firstFrameMs = watch.elapsedMilliseconds;
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while ((player.state.position.inSeconds < 2 ||
              player.state.audioParams.sampleRate == null) &&
          DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(player.state.width, greaterThan(0));
      expect(player.state.height, greaterThan(0));
      expect(player.state.audioParams.sampleRate, greaterThan(0));
      expect(player.state.position.inSeconds, greaterThanOrEqualTo(2));
      await player.pause();
      await tester.pump(const Duration(milliseconds: 500));
      final pausedPosition = player.state.position;
      await tester.pump(const Duration(milliseconds: 750));
      expect(player.state.playing, isFalse);
      expect(
        (player.state.position - pausedPosition).inMilliseconds.abs(),
        lessThan(500),
      );
      await player.seek(const Duration(seconds: 10));
      await player.play();
      final seekDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (player.state.position.inSeconds < 10 &&
          DateTime.now().isBefore(seekDeadline)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(player.state.position.inSeconds, greaterThanOrEqualTo(10));
      expect(player.state.position.inSeconds, lessThan(15));
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
        'videoOutput': probeVideoConfiguration().vo ?? 'platform_default',
        'requestedHwdec': probeVideoConfiguration().hwdec ?? 'platform_default',
        'firstFrameMs': firstFrameMs,
        'width': player.state.width,
        'height': player.state.height,
        'audioSampleRate': player.state.audioParams.sampleRate,
        'audioChannels': player.state.audioParams.channelCount,
        'hwPixelFormat': player.state.videoParams.hwPixelformat,
        'pausePassed': true,
        'seekPositionMs': player.state.position.inMilliseconds,
        'secureStorageSyntheticRoundTrip': true,
        'engineErrorCount': errors.length,
        'mediaUrlsRedacted': true,
        'limitation': 'Decoder/render evidence only; no human audibility or physical-TV hardware claim',
      };
      binding.reportData = evidence;
      // This object is deliberately sanitized; never print PlayerState or Media.
      debugPrint('M0_EVIDENCE:${jsonEncode(evidence)}');
      await player.pause();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
