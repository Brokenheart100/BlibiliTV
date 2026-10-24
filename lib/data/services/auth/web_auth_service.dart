import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pointycastle/export.dart';

import '../../../core/result.dart';
import '../../../domain/auth/auth.dart';
import '../bilibili/bilibili_api.dart';
import '../bilibili/bilibili_dto.dart';

const authCookies = {
  'SESSDATA',
  'bili_jct',
  'DedeUserID',
  'DedeUserID__ckMd5',
  'sid',
};

final class WebCredential {
  WebCredential(Map<String, String> cookies, {this.refreshToken})
    : cookies = Map.unmodifiable(cookies) {
    if (cookies['SESSDATA']?.isNotEmpty != true ||
        cookies.entries.any(
          (e) =>
              !authCookies.contains(e.key) ||
              RegExp(r'[;\r\n]').hasMatch(e.value),
        )) {
      throw const FormatException('Invalid credential');
    }
  }
  final Map<String, String> cookies;
  final String? refreshToken;
  String get header =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  String get csrf => cookies['bili_jct'] ?? '';
  @override
  String toString() => 'WebCredential(redacted)';
  static WebCredential fromHeaders(Headers headers, String? refreshToken) {
    final cookies = <String, String>{};
    for (final line in headers['set-cookie'] ?? <String>[]) {
      final cookie = Cookie.fromSetCookieValue(line);
      if (authCookies.contains(cookie.name) &&
          cookie.value.isNotEmpty &&
          const [
            null,
            '',
            '.bilibili.com',
            'bilibili.com',
          ].contains(cookie.domain)) {
        cookies[cookie.name] = cookie.value;
      }
    }
    return WebCredential(cookies, refreshToken: refreshToken);
  }
}

final class VerifiedAccount {
  const VerifiedAccount(this.uid, this.name);
  final int uid;
  final String name;
  String get ownerKey => 'user:$uid';
}

final class WebQrPoll {
  const WebQrPoll(this.status, [this.credential]);
  final QrPollStatus status;
  final WebCredential? credential;
  @override
  String toString() => 'WebQrPoll($status, redacted)';
}

abstract interface class AuthGateway {
  Future<QrChallenge> create(CancellationSignal signal);
  Future<WebQrPoll> poll(QrChallenge challenge, CancellationSignal signal);
  Future<VerifiedAccount> verify(
    WebCredential credential,
    CancellationSignal signal,
  );
  Future<bool> needsRefresh(
    WebCredential credential,
    CancellationSignal signal,
  );
  Future<WebCredential> refresh(
    WebCredential credential,
    CancellationSignal signal,
  );
  Future<void> confirmRefresh(
    WebCredential credential,
    String oldToken,
    CancellationSignal signal,
  );
  Future<void> logout(WebCredential credential, CancellationSignal signal);
}

class WebAuthService implements AuthGateway {
  WebAuthService(this.client);
  final Dio client;
  static const passport = 'https://passport.bilibili.com';
  Future<Response<Object?>> _request(
    String url,
    CancellationSignal signal, {
    WebCredential? credential,
    Map<String, Object>? query,
    Map<String, String>? form,
    bool html = false,
  }) async {
    final token = CancelToken();
    final remove = signal.onCancel(() => token.cancel('cancelled'));
    try {
      return await client.request<Object?>(
        url,
        cancelToken: token,
        queryParameters: query,
        data: form,
        options: Options(
          method: form == null ? 'GET' : 'POST',
          followRedirects: false,
          responseType: html ? ResponseType.plain : ResponseType.json,
          contentType: form == null ? null : Headers.formUrlEncodedContentType,
          headers: {
            ...bilibiliMediaHeaders,
            if (credential != null) 'Cookie': credential.header,
          },
        ),
      );
    } finally {
      remove();
    }
  }

  Map<String, Object?> _data(Response<Object?> response) {
    final root = jsonObject(response.data);
    final code = jsonInteger(root['code']);
    if (code == -101 || code == -111 || code == 86095) {
      throw const AppFailure(FailureKind.authentication, '登录已失效，请重新扫码');
    }
    if (code != 0) throw businessFailure(code);
    return root['data'] == null
        ? <String, Object?>{}
        : jsonObject(root['data']);
  }

  @override
  Future<QrChallenge> create(CancellationSignal signal) async {
    final data = _data(
      await _request('$passport/x/passport-login/web/qrcode/generate', signal),
    );
    final url = data['url']! as String;
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' ||
        !const {
          'passport.bilibili.com',
          'account.bilibili.com',
        }.contains(uri.host) ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Unexpected login host');
    }
    return QrChallenge(
      key: data['qrcode_key']! as String,
      url: url,
      expiresAt: DateTime.now().add(const Duration(seconds: 180)),
    );
  }

  @override
  Future<WebQrPoll> poll(
    QrChallenge challenge,
    CancellationSignal signal,
  ) async {
    final response = await _request(
      '$passport/x/passport-login/web/qrcode/poll',
      signal,
      query: {'qrcode_key': challenge.key},
    );
    final data = _data(response);
    return switch (jsonInteger(data['code'])) {
      86101 => const WebQrPoll(QrPollStatus.waiting),
      86090 => const WebQrPoll(QrPollStatus.scanned),
      86038 => const WebQrPoll(QrPollStatus.expired),
      0 => WebQrPoll(
        QrPollStatus.completed,
        WebCredential.fromHeaders(
          response.headers,
          data['refresh_token'] as String?,
        ),
      ),
      _ => throw const AppFailure(FailureKind.unavailable, '扫码状态暂不可用，请刷新二维码'),
    };
  }

  @override
  Future<VerifiedAccount> verify(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    final data = _data(
      await _request(
        'https://api.bilibili.com/x/web-interface/nav',
        signal,
        credential: credential,
      ),
    );
    if (data['isLogin'] != true) {
      throw const AppFailure(FailureKind.authentication, '登录已失效，请重新扫码');
    }
    final uid = jsonInteger(data['mid']);
    if (uid <= 0) throw const FormatException('Invalid user');
    return VerifiedAccount(uid, data['uname']! as String);
  }

  @override
  Future<bool> needsRefresh(
    WebCredential credential,
    CancellationSignal signal,
  ) async =>
      _data(
        await _request(
          '$passport/x/passport-login/web/cookie/info',
          signal,
          credential: credential,
          query: {'csrf': credential.csrf},
        ),
      )['refresh'] ==
      true;

  @override
  Future<WebCredential> refresh(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    if (credential.refreshToken?.isNotEmpty != true ||
        credential.csrf.isEmpty) {
      throw const AppFailure(FailureKind.authentication, '此登录无法自动续期，请重新扫码');
    }
    final path = correspondPath(DateTime.now().millisecondsSinceEpoch);
    final html =
        (await _request(
              'https://www.bilibili.com/correspond/1/$path',
              signal,
              credential: credential,
              html: true,
            )).data!
            as String;
    final csrf = RegExp(r'''<div\s+id=["']1-name["']\s*>([^<]+)</div>''')
        .firstMatch(html)
        ?.group(1)
        ?.trim();
    if (csrf == null || csrf.isEmpty) {
      throw const FormatException('Missing refresh confirmation');
    }
    final response = await _request(
      '$passport/x/passport-login/web/cookie/refresh',
      signal,
      credential: credential,
      form: {
        'csrf': credential.csrf,
        'refresh_csrf': csrf,
        'source': 'main_web',
        'refresh_token': credential.refreshToken!,
      },
    );
    final data = _data(response);
    return WebCredential.fromHeaders(
      response.headers,
      data['refresh_token']! as String,
    );
  }

  @override
  Future<void> confirmRefresh(
    WebCredential credential,
    String oldToken,
    CancellationSignal signal,
  ) async {
    _data(
      await _request(
        '$passport/x/passport-login/web/confirm/refresh',
        signal,
        credential: credential,
        form: {'csrf': credential.csrf, 'refresh_token': oldToken},
      ),
    );
  }

  @override
  Future<void> logout(
    WebCredential credential,
    CancellationSignal signal,
  ) async {
    if (credential.csrf.isEmpty) return;
    final root = jsonObject(
      (await _request(
        '$passport/login/exit/v2',
        signal,
        credential: credential,
        form: {'biliCSRF': credential.csrf},
      )).data,
    );
    if (root['code'] != 0 || root['status'] != true) {
      throw const AppFailure(FailureKind.unavailable, '本机已退出，服务端退出未确认');
    }
  }
}

/// Public JWK from the documented Bilibili Web refresh protocol; no private key.
String correspondPath(int timestamp, {RSAPublicKey? publicKey}) {
  const n =
      'y4HdjgJHBlbaBN04VERG4qNBIFHP6a3GozCl75AihQloSWCXC5HDNgyinEnhaQ_4-gaMud_GF50elYXLlCToR9se9Z8z433U3KjM-3Yx7ptKkmQNAMggQwAVKgq3zYAoidNEWuxpkY_mAitTSRLnsJW-NCTa0bqBFF6Wm1MxgfE';
  final bytes = base64Url.decode(base64Url.normalize(n));
  final modulus = BigInt.parse(
    bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
  final cipher = OAEPEncoding.withSHA256(RSAEngine())
    ..init(
      true,
      PublicKeyParameter<RSAPublicKey>(
        publicKey ?? RSAPublicKey(modulus, BigInt.from(65537)),
      ),
    );
  return cipher
      .process(Uint8List.fromList(utf8.encode('refresh_$timestamp')))
      .map((v) => v.toRadixString(16).padLeft(2, '0'))
      .join();
}
