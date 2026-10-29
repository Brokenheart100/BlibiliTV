import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'Better Player native seeks preserve pause and buffered readiness',
    (tester) async {
      expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
      expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final api = BilibiliApi(dio);
      final engine = BetterPlayerEngine();
      final samples = <Map<String, Object?>>[];
      final errors = <String>[];
      final subscription = engine.snapshots.listen((value) {
        if (value.failure != null) errors.add(value.failure!.kind.name);
      });
      binding.reportData = {
        'status': 'running',
        'backend': 'better_player',
        'readOnly': true,
        'samples': samples,
        'errors': errors,
        'audioVideoSyncMeasured': false,
        'limitation': 'Native position and buffered readiness do not measure audio PTS or audible noise.',
      };
      addTearDown(() async {
        if (binding.reportData?['status'] == 'running') {
          binding.reportData!['status'] = 'failed';
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(engine.dispose);
        await subscription.cancel();
        api.close();
        dio.close(force: true);
      });
      const videoId = 'BV1wR4Xz6EqG';
      final signal = CancellationSignal();
      final view = (await tester.runAsync(
        () =>
            api.get('/x/web-interface/view', signal, query: {'bvid': videoId}),
      ))!;
      final cid = ((view['pages']! as List).first as Map)['cid'].toString();
      final source = (await tester.runAsync(
        () =>
            BilibiliPlaybackRepository(api)
                .resolve(videoId: videoId, partId: cid, cancellation: signal),
      ))!.valueOrThrow;
      await tester.pumpWidget(MaterialApp(home: BetterPlayerSurface(engine)));
      await tester.runAsync(() => engine.open(source, startAt: Duration.zero));
      Future<void> until(bool Function() predicate) async {
        final clock = Stopwatch()..start();
        while (!predicate() && clock.elapsed < const Duration(seconds: 30)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(predicate(), isTrue);
      }

      await until(
        () =>
            engine.snapshot.position.inSeconds >= 2 &&
            engine.snapshot.width > 0,
      );
      Future<void> seek(int target, {required bool playing}) async {
        final clock = Stopwatch()..start();
        await tester.runAsync(() => engine.seek(Duration(seconds: target)));
        final native = (await tester.runAsync(
          () => engine.controller.position,
        ))!;
        expect((native.inSeconds - target).abs(), lessThanOrEqualTo(3));
        expect(engine.snapshot.playing, playing);
        expect(engine.controller.value.isBuffering, isFalse);
        expect(engine.snapshot.bufferedPosition, greaterThanOrEqualTo(native));
        expect(engine.snapshot.failure, isNull);
        samples.add({
          'targetSeconds': target,
          'seekMs': clock.elapsedMilliseconds,
          'positionMs': native.inMilliseconds,
          'bufferMs': engine.snapshot.bufferedPosition.inMilliseconds,
          'playing': engine.snapshot.playing,
          'rate': engine.snapshot.rate,
        });
        if (playing) {
          await until(
            () =>
                engine.snapshot.position >
                native + const Duration(milliseconds: 500),
          );
        }
      }

      for (final target in [35, 85, 25, 120, 15, 180, 40, 210, 10, 0]) {
        await seek(target, playing: true);
      }
      await tester.runAsync(engine.pause);
      for (final target in [60, 10]) {
        await seek(target, playing: false);
      }
      await tester.runAsync(() => engine.setRate(1.5));
      await tester.runAsync(engine.play);
      await seek(35, playing: true);
      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
      binding.reportData!['status'] = 'passed';
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
