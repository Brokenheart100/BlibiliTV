import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/services/auth/web_auth_service.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  final signal = CancellationSignal();
  try {
    final service = WebAuthService(dio);
    final challenge = await service.create(signal);
    final poll = await service.poll(challenge, signal);
    final report = {
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'qrCreated': true,
      'qrHost': Uri.parse(challenge.url).host,
      'initialStatus': poll.status.name,
      'expiresInSeconds': challenge.expiresAt
          .difference(DateTime.now())
          .inSeconds,
      'accountConfirmed': false,
      'secretsPersisted': false,
    };
    await Directory('docs/m3-evidence').create(recursive: true);
    await File(
      'docs/m3-evidence/guest-qr-contract.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln(jsonEncode(report));
  } catch (error) {
    stderr.writeln(
      'QR contract verification failed: ${error.runtimeType}, ${safeApiFailure(error).kind.name} (details redacted)',
    );
    exitCode = 1;
  } finally {
    signal.cancel();
    dio.close(force: true);
  }
}
