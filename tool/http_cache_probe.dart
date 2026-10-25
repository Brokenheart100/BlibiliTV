import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/network/bilibili_http_cache.dart';

/// Explicit guest-only network probe. Persists counts and flags, never bodies.
Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  var networkRequests = 0;
  final responses = <Map<String, Object?>>[];
  dio.interceptors.addAll([
    BilibiliCacheInterceptor(),
    InterceptorsWrapper(
      onRequest: (request, handler) {
        networkRequests++;
        handler.next(request);
      },
      onResponse: (response, handler) {
        responses.add({
          'status': response.statusCode,
          'cacheHit': response.extra[extraFromNetworkKey] == false,
          'noStore': CacheControl.fromHeader(response.headers['cache-control'])
              .noStore,
          'hasSetCookie': response.headers['set-cookie'] != null,
        });
        handler.next(response);
      },
    ),
  ]);
  final api = BilibiliApi(dio);
  final checks = <Map<String, Object?>>[];
  try {
    for (final label in ['popular', 'detail', 'related', 'search']) {
      final path = switch (label) {
        'popular' => '/x/web-interface/popular',
        'detail' => '/x/web-interface/wbi/view',
        'related' => '/x/web-interface/archive/related',
        _ => '/x/web-interface/wbi/search/type',
      };
      final query = <String, Object>{
        if (label == 'popular') ...{'pn': 1, 'ps': 12},
        if (label == 'detail' || label == 'related') 'bvid': 'BV1wR4Xz6EqG',
        if (label == 'search') ...{
          'search_type': 'video',
          'keyword': '纪录片',
          'page': 1,
        },
      };
      Future<void> read({bool refresh = false}) async {
        if (label == 'related') {
          await api.getList(
            path,
            CancellationSignal(),
            query: query,
            forceRefresh: refresh,
          );
        } else {
          await api.get(
            path,
            CancellationSignal(),
            query: query,
            signed: label == 'detail' || label == 'search',
            forceRefresh: refresh,
          );
        }
      }

      try {
        await read();
        final afterCold = networkRequests;
        await read();
        final afterHit = networkRequests;
        final hitFlags = Map<String, Object?>.from(responses.last);
        await read(refresh: true);
        checks.add({
          'endpoint': label,
          'secondReadNetworkRequests': afterHit - afterCold,
          'refreshNetworkRequests': networkRequests - afterHit,
          'secondRead': hitFlags,
          'result': 'passed',
        });
      } on AppFailure catch (failure) {
        checks.add({
          'endpoint': label,
          'result': 'failed',
          'failureKind': failure.kind.name,
        });
      } catch (_) {
        checks.add({
          'endpoint': label,
          'result': 'failed',
          'failureKind': 'transport-or-contract',
        });
      }
    }
  } finally {
    api.close();
    dio.close(force: true);
  }
  final report = {
    'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'identity': 'new guest API scope; no stored credentials',
    'networkRequests': networkRequests,
    'checks': checks,
  };
  final output = File('docs/http-cache-evidence/guest-network-probe.json');
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
