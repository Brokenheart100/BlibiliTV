import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/services/auth/request_identity.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/network/bilibili_http_cache.dart';
import 'package:mambatv/data/services/network/safe_logging_interceptor.dart';
import 'package:mambatv/domain/entities/app_models.dart';

class CatalogAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  FutureOr<ResponseBody> Function(RequestOptions)? respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return respond?.call(options) ??
        body({
          'code': 0,
          'data': {'version': calls.length},
        });
  }

  static ResponseBody body(
    Object? value, {
    int status = 200,
    Map<String, List<String>> headers = const {},
  }) => ResponseBody.fromString(
    jsonEncode(value),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
      ...headers,
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  const popular = '/x/web-interface/popular';
  const detail = '/x/web-interface/wbi/view';
  const related = '/x/web-interface/archive/related';
  const search = '/x/web-interface/wbi/search/type';
  late Dio dio;
  late CatalogAdapter adapter;
  late BilibiliCacheScope scope;
  late DateTime clock;
  final logs = <String>[];

  setUp(() {
    clock = DateTime.now();
    scope = BilibiliCacheScope('guest:0', now: () => clock);
    adapter = CatalogAdapter();
    logs.clear();
    dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      SafeLoggingInterceptor(logs.add),
      BilibiliCacheInterceptor(),
    ]);
    addTearDown(() async {
      await scope.close();
      dio.close(force: true);
    });
  });

  Future<Response<Object?>> get(
    String path, {
    Map<String, Object> query = const {},
    bool refresh = false,
    BilibiliCacheScope? owner,
  }) => dio.get<Object?>(
    'https://api.bilibili.com$path',
    queryParameters: query,
    options: Options(
      extra: (owner ?? scope).requestExtra(path, refresh: refresh),
    ),
  );

  test('each allowlisted endpoint hits the real Dio interceptor on its second read', () async {
    for (final path in [popular, detail, related, search]) {
      final first = await get(path, query: {'id': 1});
      final cached = await get(path, query: {'id': 1});
      expect(cached.data, first.data);
      expect(cached.extra[extraFromNetworkKey], isFalse);
    }
    expect(adapter.calls, hasLength(4));
  });

  test(
    'refresh fetches and replaces an existing entry without losing future hits',
    () async {
      await get(popular);
      final updated = await get(popular, refresh: true);
      final cached = await get(popular);
      expect(adapter.calls, hasLength(2));
      expect(updated.data, cached.data);
      expect(cached.extra[extraFromNetworkKey], isFalse);
    },
  );

  test(
    'WBI timestamps, signatures and query order do not fragment a business key',
    () async {
      await get(
        search,
        query: {'keyword': '纪录片', 'page': 1, 'wts': 100, 'w_rid': 'old'},
      );
      await get(
        search,
        query: {'w_rid': 'new', 'page': 1, 'wts': 200, 'keyword': '纪录片'},
      );
      await get(search, query: {'keyword': '纪录片', 'page': 2});
      await get(search, query: {'keyword': '音乐', 'page': 1});
      expect(adapter.calls, hasLength(3));
    },
  );

  test(
    'account keys and session generations cannot reuse each other',
    () async {
      final owners = [
        scope,
        BilibiliCacheScope('user:101:1'),
        BilibiliCacheScope('user:202:2'),
        BilibiliCacheScope('user:101:3'),
      ];
      addTearDown(() async {
        for (final owner in owners.skip(1)) {
          await owner.close();
        }
      });
      for (final owner in owners) {
        await get(popular, owner: owner);
        await get(popular, owner: owner);
      }
      expect(adapter.calls, hasLength(4));
      final keys = owners.map(
        (owner) => CacheTestKey.fromExtraForTest(owner.requestExtra(popular)),
      );
      expect(keys.toSet(), hasLength(4));
    },
  );

  for (final path in [popular, search]) {
    test(
      '$path expires at one minute even after a hit near the deadline',
      () async {
        await get(path);
        clock = DateTime.now().add(const Duration(seconds: 55));
        await get(path);
        expect(adapter.calls, hasLength(1));
        clock = DateTime.now().add(const Duration(seconds: 65));
        await get(path);
        expect(adapter.calls, hasLength(2));
      },
    );
  }

  test(
    'detail and related expire at three minutes with no sliding extension',
    () async {
      for (final path in [detail, related]) {
        await get(path);
      }
      clock = DateTime.now().add(const Duration(seconds: 175));
      for (final path in [detail, related]) {
        await get(path);
      }
      expect(adapter.calls, hasLength(2));
      clock = DateTime.now().add(const Duration(seconds: 185));
      for (final path in [detail, related]) {
        await get(path);
      }
      expect(adapter.calls, hasLength(4));
    },
  );

  test(
    'authentication, QR, recommendation, playurl and unknown APIs never cache',
    () async {
      for (final path in [
        '/x/web-interface/nav',
        '/x/passport-login/web/qrcode/poll',
        '/x/passport-login/web/qrcode/generate',
        '/x/passport-login/web/logout',
        '/x/web-interface/wbi/index/top/feed/rcmd',
        '/x/player/wbi/playurl',
        '/x/new-unreviewed-api',
      ]) {
        expect(scope.requestExtra(path), isEmpty);
        await get(path);
        await get(path);
      }
      expect(adapter.calls, hasLength(14));
    },
  );

  test(
    'method and origin checks cannot be bypassed with copied cache options',
    () async {
      final options = Options(extra: scope.requestExtra(popular));
      for (var i = 0; i < 2; i++) {
        await dio.post<Object?>(
          'https://api.bilibili.com$popular',
          options: options,
        );
        await dio.get<Object?>(
          'https://example.invalid$popular',
          options: options,
        );
        await dio.get<Object?>(
          'http://api.bilibili.com$popular',
          options: options,
        );
      }
      expect(adapter.calls, hasLength(6));
    },
  );

  for (final code in [-101, -352, -403, -404]) {
    test(
      'HTTP 200 business error $code purges the old entry and remains visible',
      () async {
        await get(popular);
        adapter.respond = (_) =>
            CatalogAdapter.body({'code': code, 'data': null});
        expect((await get(popular, refresh: true)).data, {
          'code': code,
          'data': null,
        });
        adapter.respond = null;
        await get(popular);
        expect(adapter.calls, hasLength(3));
      },
    );
  }

  test(
    'authentication failure purges other metadata in the same scope',
    () async {
      await get(detail);
      adapter.respond = (_) =>
          CatalogAdapter.body({'code': -101, 'data': null});
      await get(popular, refresh: true);
      adapter.respond = null;
      await get(detail);
      expect(adapter.calls, hasLength(3));
    },
  );

  for (final header in ['no-store', 'set-cookie', 'vary']) {
    test('$header responses are never persisted', () async {
      adapter.respond = (_) => CatalogAdapter.body(
        {'code': 0, 'data': <String, Object?>{}},
        headers: {
          if (header == 'no-store') 'cache-control': ['no-store'],
          if (header == 'set-cookie') 'set-cookie': ['synthetic=do-not-cache'],
          if (header == 'vary') 'vary': ['*'],
        },
      );
      await get(popular);
      await get(popular);
      expect(adapter.calls, hasLength(2));
    });
  }

  test('malformed success envelopes and non-200 statuses cannot become cached successes', () async {
    for (final body in [
      <String, Object?>{'code': 0, 'data': null},
      'not-an-envelope',
    ]) {
      adapter.respond = (_) => CatalogAdapter.body(body);
      await get(popular);
      await get(popular);
    }
    adapter.respond = (_) => CatalogAdapter.body({
      'code': 0,
      'data': <String, Object?>{},
    }, status: 203);
    await get(popular);
    await get(popular);
    expect(adapter.calls, hasLength(6));
  });

  test(
    'HTTP rejection and network failure are not replaced by cached content',
    () async {
      for (final status in [401, 403, 412, 429, 500]) {
        adapter.respond = null;
        await get(popular, refresh: true);
        adapter.respond = (_) => CatalogAdapter.body({}, status: status);
        await expectLater(
          get(popular, refresh: true),
          throwsA(isA<DioException>()),
        );
        adapter.respond = null;
        final before = adapter.calls.length;
        await get(popular);
        expect(adapter.calls.length, before + 1);
      }
      adapter.respond = (request) => throw DioException.connectionError(
        requestOptions: request,
        reason: 'synthetic offline',
      );
      await expectLater(
        get(popular, refresh: true),
        throwsA(isA<DioException>()),
      );
      clock = DateTime.now().add(const Duration(minutes: 2));
      await expectLater(get(popular), throwsA(isA<DioException>()));
    },
  );

  test(
    'fresh content remains readable offline without allowing stale fallback',
    () async {
      await get(popular);
      adapter.respond = (request) => throw DioException.connectionError(
        requestOptions: request,
        reason: 'synthetic offline',
      );
      expect((await get(popular)).extra[extraFromNetworkKey], isFalse);
      expect(adapter.calls, hasLength(1));
    },
  );

  test('a cancelled cache read remains cancelled', () async {
    await get(popular);
    final token = CancelToken()..cancel('synthetic cancellation');
    await expectLater(
      dio.get<Object?>(
        'https://api.bilibili.com$popular',
        cancelToken: token,
        options: Options(extra: scope.requestExtra(popular)),
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(adapter.calls, hasLength(1));
  });

  test('closing a scope clears entries and blocks a late response from repopulating it', () async {
    await get(popular);
    final options = RequestOptions(
      path: 'https://api.bilibili.com$popular',
      extra: scope.requestExtra(popular),
    );
    final cache = options.getCacheOptions()!;
    final key = cache.keyBuilder(url: options.uri);
    final delayed = Completer<ResponseBody>();
    adapter.respond = (_) => delayed.future;
    final loading = get(popular, refresh: true);
    while (adapter.calls.length < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    await scope.close();
    delayed.complete(
      CatalogAdapter.body({'code': 0, 'data': <String, Object?>{}}),
    );
    await loading;
    expect(await cache.store!.exists(key), isFalse);
  });

  test(
    'oversized entries are skipped and the 4 MiB LRU evicts old content',
    () async {
      adapter.respond = (_) => CatalogAdapter.body({
        'code': 0,
        'data': {'text': 'x' * (600 * 1024)},
      });
      await get(popular);
      await get(popular);
      expect(adapter.calls, hasLength(2));
      adapter.respond = (_) => CatalogAdapter.body({
        'code': 0,
        'data': {'text': 'x' * (450 * 1024)},
      });
      for (var i = 0; i < 12; i++) {
        await get(popular, query: {'pn': i});
      }
      final before = adapter.calls.length;
      await get(popular, query: {'pn': 11});
      expect(adapter.calls.length, before);
      await get(popular, query: {'pn': 0});
      expect(adapter.calls.length, before + 1);
    },
  );

  test('BilibiliApi closes its store, preserves errors and never leaks credentials to logs', () async {
    var failures = 0;
    final api = BilibiliApi(
      dio,
      identity: const RequestIdentity(
        Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
          generation: 5,
        ),
        'SESSDATA=synthetic-secret',
      ),
      onAuthenticationFailure: (_) async {
        failures++;
      },
    );
    addTearDown(api.close);
    await api.get(popular, CancellationSignal());
    await api.get(popular, CancellationSignal());
    expect(adapter.calls, hasLength(1));
    expect(adapter.calls.single.headers['Cookie'], 'SESSDATA=synthetic-secret');
    adapter.respond = (_) => CatalogAdapter.body({'code': -101, 'data': null});
    await expectLater(
      api.get(popular, CancellationSignal(), forceRefresh: true),
      throwsA(isA<AppFailure>()),
    );
    expect(failures, 1);
    api.close();
    await expectLater(
      api.get(popular, CancellationSignal()),
      throwsA(isA<AppFailure>()),
    );
    for (final log in logs) {
      expect((jsonDecode(log) as Map).keys.toSet(), {
        'event',
        'method',
        'status',
        'category',
        'elapsedMs',
      });
      expect(log, isNot(contains('synthetic-secret')));
      expect(log, isNot(contains('user:101')));
      expect(log, isNot(contains('/popular')));
    }
  });
}

extension CacheTestKey on CacheOptions {
  static String fromExtraForTest(Map<String, dynamic> extra) {
    final options = RequestOptions(
      path: 'https://api.bilibili.com/x/web-interface/popular',
      extra: extra,
    ).getCacheOptions()!;
    return options.keyBuilder(
      url: Uri.parse('https://api.bilibili.com/x/web-interface/popular'),
    );
  }
}
