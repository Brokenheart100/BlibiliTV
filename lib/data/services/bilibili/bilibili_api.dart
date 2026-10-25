import 'package:dio/dio.dart';

import 'dart:async';

import '../../../core/result.dart';
import '../../../domain/entities/app_models.dart';
import '../auth/request_identity.dart';
import '../network/bilibili_http_cache.dart';
import 'bilibili_dto.dart';
import 'wbi_signer.dart';

const bilibiliMediaHeaders = <String, String>{
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  'Referer': 'https://www.bilibili.com/',
};

/// Account-scoped Web/WBI service. Credentials stay bound to this generation.
class BilibiliApi {
  BilibiliApi(
    this.client, {
    RequestIdentity? identity,
    this.onAuthenticationFailure,
  }) : identity = identity ?? const RequestIdentity(Session()),
       _cache = BilibiliCacheScope(
         (identity?.session ?? const Session()).scopeKey,
       );
  final Dio client;
  final RequestIdentity identity;
  final Future<void> Function(int generation)? onAuthenticationFailure;
  final _scope = CancellationSignal();
  final BilibiliCacheScope _cache;
  int _writesSent = 0;
  int get remoteWriteRequestsSent => _writesSent;
  Future<void> clearCache() => _cache.clear();
  void close() {
    _scope.cancel();
    unawaited(_cache.close());
  }

  void checkOwner(String ownerKey) {
    if (_scope.isCancelled || ownerKey != identity.session.ownerKey) {
      throw const AppFailure(FailureKind.cancelled, '账号状态已变化，请重新打开页面');
    }
  }

  void _unauthorized() {
    if (identity.session.isAuthenticated) {
      unawaited(onAuthenticationFailure?.call(identity.session.generation));
    }
  }

  String? _imageKey, _subKey;
  DateTime? _keyTime;

  Future<void> postForm(
    String path,
    Map<String, Object> values,
    CancellationSignal cancellation,
  ) async {
    if (const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION')) {
      throw const AppFailure(FailureKind.permission, '本次只读验收不执行账号变更');
    }
    if (!identity.session.isAuthenticated || identity.cookie == null) {
      throw const AppFailure(FailureKind.authentication, '请先扫码登录');
    }
    if (_scope.isCancelled || cancellation.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '账号状态已变化');
    }
    final csrf = identity.cookie!
        .split(';')
        .map((v) => v.trim())
        .where((v) => v.startsWith('bili_jct='))
        .map((v) => v.substring(9))
        .firstOrNull;
    if (csrf == null || csrf.isEmpty) {
      throw const AppFailure(FailureKind.authentication, '登录凭据不完整，请重新扫码');
    }
    final token = CancelToken();
    final remove = cancellation.onCancel(() => token.cancel('cancelled'));
    final removeScope = _scope.onCancel(() => token.cancel('session_changed'));
    try {
      _writesSent++;
      final response = await client.post<Object?>(
        'https://api.bilibili.com$path',
        data: {...values, 'csrf': csrf},
        cancelToken: token,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          headers: {...bilibiliMediaHeaders, 'Cookie': identity.cookie},
        ),
      );
      if (_scope.isCancelled || cancellation.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '账号状态已变化');
      }
      final code = jsonInteger(jsonObject(response.data)['code']);
      if (code == -101) _unauthorized();
      if (code != 0) throw businessFailure(code);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) _unauthorized();
      throw safeApiFailure(error);
    } finally {
      remove();
      removeScope();
    }
  }

  Future<Map<String, Object?>> get(
    String path,
    CancellationSignal cancellation, {
    Map<String, Object> query = const {},
    bool signed = false,
    bool allowGuest = false,
    bool forceRefresh = false,
  }) async => jsonObject(
    await _get(
      path,
      cancellation,
      query: query,
      signed: signed,
      allowGuest: allowGuest,
      forceRefresh: forceRefresh,
    ),
  );

  Future<List<Object?>> getList(
    String path,
    CancellationSignal cancellation, {
    Map<String, Object> query = const {},
    bool forceRefresh = false,
  }) async => jsonList(
    await _get(path, cancellation, query: query, forceRefresh: forceRefresh),
  );

  Future<Object?> _get(
    String path,
    CancellationSignal cancellation, {
    Map<String, Object> query = const {},
    bool signed = false,
    bool allowGuest = false,
    bool forceRefresh = false,
  }) async {
    if (cancellation.isCancelled || _scope.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '请求已取消');
    }
    var parameters = query;
    if (signed) {
      if (_imageKey == null ||
          DateTime.now().difference(_keyTime!) > const Duration(hours: 1)) {
        final nav = await get(
          '/x/web-interface/nav',
          cancellation,
          allowGuest: true,
        );
        final images = jsonObject(nav['wbi_img']);
        String key(Object? value) =>
            Uri.parse(value! as String).pathSegments.last.split('.').first;
        _imageKey = key(images['img_url']);
        _subKey = key(images['sub_url']);
        _keyTime = DateTime.now();
      }
      parameters = signWbi(
        query,
        _imageKey!,
        _subKey!,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
    final token = CancelToken();
    final remove = cancellation.onCancel(() => token.cancel('cancelled'));
    final removeScope = _scope.onCancel(() => token.cancel('session_changed'));
    try {
      final response = await client.get<Object?>(
        'https://api.bilibili.com$path',
        queryParameters: parameters,
        cancelToken: token,
        options: Options(
          extra: _cache.requestExtra(path, refresh: forceRefresh),
          followRedirects: false,
          headers: {
            ...bilibiliMediaHeaders,
            if (identity.cookie != null) 'Cookie': identity.cookie,
          },
        ),
      );
      if (_scope.isCancelled || cancellation.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '请求已取消');
      }
      final envelope = jsonObject(response.data);
      final code = jsonInteger(envelope['code']);
      if (code == -101) _unauthorized();
      if (code != 0 && !(allowGuest && code == -101)) {
        if (code == -403 || code == -352) _imageKey = null;
        throw businessFailure(code);
      }
      return envelope['data'];
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) _unauthorized();
      rethrow;
    } finally {
      remove();
      removeScope();
    }
  }
}

AppFailure businessFailure(int code) => switch (code) {
  -101 => const AppFailure(FailureKind.authentication, '登录已失效，请重新扫码'),
  -104 ||
  -403 ||
  -404 ||
  62002 ||
  62004 ||
  62012 ||
  -400 => const AppFailure(FailureKind.permission, '该内容暂不可播放，可能需要登录或没有访问权限'),
  -352 ||
  -412 ||
  -509 => const AppFailure(FailureKind.rateLimited, '请求暂时受限，请稍后手动重试'),
  _ => const AppFailure(FailureKind.unavailable, '内容服务暂不可用，请稍后重试'),
};

AppFailure safeApiFailure(Object error) => switch (error) {
  AppFailure() => error,
  DioException(type: DioExceptionType.cancel) => const AppFailure(
    FailureKind.cancelled,
    '请求已取消',
  ),
  DioException(
    type: DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout,
  ) =>
    const AppFailure(FailureKind.timeout, '连接超时，请检查网络后重试'),
  DioException(response: final response)
      when response?.statusCode == 429 || response?.statusCode == 412 =>
    const AppFailure(FailureKind.rateLimited, '请求暂时受限，请稍后重试'),
  DioException(response: final response) when response?.statusCode == 403 =>
    const AppFailure(FailureKind.permission, '服务拒绝访问，可以返回或稍后重试'),
  DioException(response: final response) when response?.statusCode == 401 =>
    const AppFailure(FailureKind.authentication, '登录已失效，请重新扫码'),
  DioException() => const AppFailure(FailureKind.network, '网络连接失败，请检查网络后重试'),
  _ => const AppFailure(FailureKind.contract, '内容格式暂不支持，请返回选择其他视频'),
};
