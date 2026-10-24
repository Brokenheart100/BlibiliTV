import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/logging/app_talker.dart';
import 'package:mambatv/data/services/network/safe_logging_interceptor.dart';
import 'package:talker/talker.dart';

void main() {
  test(
    'HTTP secrets never enter Talker history on either success or failure',
    () async {
      final talker = createAppTalker(console: false);
      final interceptor = SafeLoggingInterceptor(
        (metadata) => recordHttpMetadata(talker, metadata),
      );
      final request = RequestOptions(
        path: 'https://example.invalid/?qrcode_key=synthetic-secret',
        method: 'POST',
        headers: {
          'Cookie': 'synthetic-secret',
          'Authorization': 'synthetic-secret',
        },
        data: {'refresh_token': 'synthetic-secret'},
      );
      interceptor.onRequest(request, RequestInterceptorHandler());
      interceptor.onResponse(
        Response<Object?>(
          requestOptions: request,
          statusCode: 200,
          data: {'url': 'synthetic-secret'},
          headers: Headers.fromMap({
            'set-cookie': ['synthetic-secret'],
          }),
        ),
        ResponseInterceptorHandler(),
      );
      final client = Dio();
      addTearDown(() => client.close(force: true));
      client.interceptors.add(interceptor);
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'synthetic-secret',
                message: 'synthetic-secret',
                type: DioExceptionType.badResponse,
                response: Response<Object?>(
                  requestOptions: options,
                  statusCode: 503,
                  data: {'SESSDATA': 'synthetic-secret'},
                ),
              ),
              true,
            );
          },
        ),
      );
      await expectLater(
        client.post<Object?>(
          request.path,
          data: request.data,
          options: Options(headers: request.headers),
        ),
        throwsA(isA<DioException>()),
      );
      expect(talker.history, hasLength(2));
      expect(talker.history.first.logLevel, LogLevel.info);
      expect(talker.history.last.logLevel, LogLevel.error);
      for (final log in talker.history) {
        final text = log.generateTextMessage();
        expect(text, isNot(contains('synthetic-secret')));
        expect(text, isNot(contains('example.invalid')));
        expect(log.exception, isNull);
        expect(log.error, isNull);
        expect(log.stackTrace, isNull);
        final fields = jsonDecode(log.message!) as Map<String, dynamic>;
        expect(fields.keys.toSet(), {
          'event',
          'method',
          'status',
          'category',
          'elapsedMs',
        });
      }
    },
  );

  test('diagnostics are bounded and disabled mode retains no logs', () {
    const metadata =
        '{"event":"http","method":"GET","status":200,"category":"response","elapsedMs":1}';
    final talker = createAppTalker(console: false);
    for (var i = 0; i < 250; i++) {
      recordHttpMetadata(talker, metadata);
    }
    expect(talker.history, hasLength(200));
    final disabled = createAppTalker(enabled: false, console: false);
    recordHttpMetadata(disabled, metadata);
    expect(disabled.settings.useConsoleLogs, isFalse);
    expect(disabled.history, isEmpty);
  });

  test('cancel is debug, 4xx and network failures are warnings', () {
    final talker = createAppTalker(console: false);
    for (final (status, category, level) in [
      (null, 'cancel', LogLevel.debug),
      (401, 'response', LogLevel.warning),
      (null, 'connectionTimeout', LogLevel.warning),
    ]) {
      recordHttpMetadata(
        talker,
        jsonEncode({
          'event': 'http',
          'method': 'GET',
          'status': status,
          'category': category,
          'elapsedMs': 1,
        }),
      );
      expect(talker.history.last.logLevel, level);
    }
  });
}
