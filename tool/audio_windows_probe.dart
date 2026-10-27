/// Plays the same public AAC excerpt outside the emulator for noise diagnosis.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

Future<void> main() async {
  if (!Platform.isWindows) throw UnsupportedError('Windows-only diagnostic');
  MediaKit.ensureInitialized(
    libmpv: File('build/windows/x64/runner/Debug/libmpv-2.dll').absolute.path,
  );
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final api = BilibiliApi(client);
  final player = Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.error),
  );
  final native = player.platform! as NativePlayer;
  try {
    final signal = CancellationSignal();
    const videoId = 'BV1wR4Xz6EqG';
    final view = await api.get(
      '/x/web-interface/view',
      signal,
      query: {'bvid': videoId},
    );
    final part = ((view['pages']! as List).first as Map)['cid'].toString();
    final source = (await BilibiliPlaybackRepository(api).resolve(
      videoId: videoId,
      partId: part,
      cancellation: signal,
    )).valueOrThrow;
    await player.setVolume(60);
    final finished = player.stream.completed.firstWhere((value) => value);
    await player.open(
      Media(
        source.audioUrl,
        httpHeaders: bilibiliMediaHeaders,
        start: const Duration(seconds: 35),
        end: const Duration(seconds: 55),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    final report = <String, Object?>{
      'readOnly': true,
      'source': 'same public AAC; seconds 35-55',
      'audioOutput': await native.getProperty('current-ao'),
      'inputSampleRate': await native.getProperty('audio-params/samplerate'),
      'outputSampleRate': await native.getProperty(
        'audio-out-params/samplerate',
      ),
      'outputFormat': await native.getProperty('audio-out-params/format'),
      'volume': 60,
      'manualNoiseFreeVerified': false,
    };
    stdout.writeln(jsonEncode(report));
    await finished.timeout(const Duration(seconds: 30));
    await Directory('docs/audio-output-evidence').create(recursive: true);
    await File(
      'docs/audio-output-evidence/windows-direct.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
  } finally {
    await player.dispose();
    api.close();
    client.close(force: true);
  }
}
