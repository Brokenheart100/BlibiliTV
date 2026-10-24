import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mambatv/m0/data/bilibili_probe_service.dart';
import 'package:mambatv/m0/data/probe_check_dto.dart';

Future<void> main() async {
  final service = BilibiliProbeService();
  try {
    final checks = await service.probeGuest();
    final token = CancelToken();
    final qr = await service.createQr(token);
    final poll = await service.pollQr(qr, token);
    final evidence = <String, Object?>{
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'environment': 'Windows Dart CLI; no login confirmation',
      'checks': checks
          .map((check) => ProbeCheckDto.fromDomain(check).toJson())
          .toList(),
      'qr': {
        'generated': true,
        'pollCode': poll.code,
        'challengeRedacted': true,
      },
      'mediaUrlsRedacted': true,
    };
    final json = const JsonEncoder.withIndent('  ').convert(evidence);
    await Directory('docs/m0-evidence').create(recursive: true);
    await File('docs/m0-evidence/guest-api.json').writeAsString('$json\n');
    stdout.writeln(json);
  } catch (error) {
    stderr.writeln(describeFailure(error));
    exitCode = 1;
  } finally {
    service.close();
  }
}
