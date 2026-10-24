import 'dart:convert';

import 'package:dio/dio.dart';

/// Only allowlisted metadata can reach the sink; no URI, headers or payloads.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor(this.sink);
  final void Function(String) sink;
  static const _clockKey = 'mambatv.request_clock';
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_clockKey] = Stopwatch()..start();
    handler.next(options);
  }

  void _record(RequestOptions request, int? status, String category) {
    final clock = request.extra[_clockKey] as Stopwatch?;
    sink(
      jsonEncode({
        'event': 'http',
        'method':
            const {
              'GET',
              'POST',
              'PUT',
              'PATCH',
              'DELETE',
              'HEAD',
            }.contains(request.method)
            ? request.method
            : 'OTHER',
        'status': status,
        'category': category,
        'elapsedMs': clock?.elapsedMilliseconds,
      }),
    );
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _record(response.requestOptions, response.statusCode, 'response');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions, err.response?.statusCode, err.type.name);
    handler.next(err);
  }
}
