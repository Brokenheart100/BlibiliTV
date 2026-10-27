import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// Only ordinary catalog metadata is eligible; account and media APIs bypass it.
Duration? catalogCacheLifetime(String path) => switch (path) {
  '/x/web-interface/wbi/view' ||
  '/x/web-interface/archive/related' => const Duration(minutes: 3),
  '/x/web-interface/popular' ||
  '/x/web-interface/popular/series/list' ||
  '/x/web-interface/popular/series/one' ||
  '/x/web-interface/ranking/v2' ||
  '/x/web-interface/wbi/search/type' => const Duration(minutes: 1),
  _ => null,
};

/// Owned by one BilibiliApi generation, never shared across account changes.
final class BilibiliCacheScope {
  BilibiliCacheScope(this.scopeKey, {DateTime Function()? now})
    : _store = _SessionMemoryCache(now: now ?? DateTime.now);

  final String scopeKey;
  final _SessionMemoryCache _store;

  Map<String, dynamic> requestExtra(String path, {bool refresh = false}) {
    final lifetime = catalogCacheLifetime(path);
    if (lifetime == null) return const {};
    return CacheOptions(
      store: _store,
      policy: refresh ? CachePolicy.refreshForceCache : CachePolicy.forceCache,
      maxStale: lifetime,
      // Fresh entries already work offline. Expired data must not mask errors.
      hitCacheOnNetworkFailure: false,
      keyBuilder: ({required url, headers, body}) {
        final parameters =
            url.queryParametersAll.entries
                .where((entry) => entry.key != 'wts' && entry.key != 'w_rid')
                .toList()
              ..sort((a, b) => a.key.compareTo(b.key));
        final canonical = jsonEncode([
          scopeKey,
          'GET',
          url.scheme,
          url.host,
          url.port,
          url.path,
          for (final entry in parameters) [entry.key, entry.value],
        ]);
        return sha256.convert(utf8.encode(canonical)).toString();
      },
    ).toExtra();
  }

  Future<void> close() => _store.close();
  Future<void> clear() => _store.clean();
}

// Retain the package's bounded LRU storage; only add fixed TTL and lifecycle
// guards. maxStale alone slides on hits in dio_cache_interceptor 4.0.7.
final class _SessionMemoryCache extends MemCacheStore {
  _SessionMemoryCache({required this.now})
    : super(maxSize: 4 * 1024 * 1024, maxEntrySize: 512 * 1024);
  final DateTime Function() now;
  bool closed = false;

  @override
  Future<CacheResponse?> get(String key) async {
    if (closed) return null;
    final response = await super.get(key);
    if (response == null) return null;
    final lifetime = catalogCacheLifetime(Uri.parse(response.url).path);
    if (lifetime == null ||
        !now().isBefore(response.responseDate.add(lifetime))) {
      await delete(key);
      return null;
    }
    return response;
  }

  @override
  Future<void> set(CacheResponse response) async {
    if (closed) return;
    final lifetime = catalogCacheLifetime(Uri.parse(response.url).path);
    if (lifetime == null) return;
    await super.set(
      response.copyWith(maxStale: response.responseDate.add(lifetime)),
    );
  }

  @override
  Future<void> close() {
    closed = true;
    return super.close();
  }
}

/// Wrap the package's transport cache with Bilibili's HTTP-200 business rules.
final class BilibiliCacheInterceptor extends DioCacheInterceptor {
  BilibiliCacheInterceptor()
    : super(
        options: CacheOptions(
          policy: CachePolicy.noCache,
          store: MemCacheStore(),
        ),
      );

  _SessionMemoryCache? _store(RequestOptions request) {
    final uri = request.uri;
    final store = request.getCacheOptions()?.store;
    return request.method == 'GET' &&
            uri.scheme == 'https' &&
            uri.host == 'api.bilibili.com' &&
            uri.port == 443 &&
            catalogCacheLifetime(uri.path) != null &&
            store is _SessionMemoryCache
        ? store
        : null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_store(options) == null) {
      handler.next(options);
    } else {
      super.onRequest(options, handler);
    }
  }

  Future<void> _evict(RequestOptions request, _SessionMemoryCache store) async {
    final options = request.getCacheOptions()!;
    await store.delete(options.keyBuilder(url: request.uri));
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final request = response.requestOptions;
    final store = _store(request);
    if (store == null) {
      handler.next(response);
      return;
    }
    final data = response.data;
    final success =
        response.statusCode == 200 &&
        data is Map &&
        data['code'] == 0 &&
        (data['data'] is Map || data['data'] is List);
    final noStore = CacheControl.fromHeader(response.headers['cache-control'])
        .noStore;
    final variesAll =
        response.headers['vary']
            ?.expand((value) => value.split(','))
            .any((value) => value.trim() == '*') ??
        false;
    if (!success ||
        noStore ||
        variesAll ||
        response.headers['set-cookie'] != null ||
        store.closed ||
        request.cancelToken?.isCancelled == true) {
      if (data is Map && data['code'] == -101) {
        await store.clean();
      } else {
        await _evict(request, store);
      }
      handler.next(response);
      return;
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final store = _store(err.requestOptions);
    if (store != null && err.response != null) {
      if (err.response?.statusCode == 401) {
        await store.clean();
      } else {
        await _evict(err.requestOptions, store);
      }
    }
    // HTTP errors, cancellation and network failures remain observable errors.
    handler.next(err);
  }
}
