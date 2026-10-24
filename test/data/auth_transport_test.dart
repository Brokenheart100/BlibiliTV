import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/services/auth/request_identity.dart';
import 'package:mambatv/data/services/auth/web_auth_service.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/auth/auth.dart';
import 'package:mambatv/domain/entities/app_models.dart';

import '../support/fake_auth.dart';

void main() {
  late Dio dio;
  setUp(() {
    dio = Dio();
    addTearDown(() => dio.close(force: true));
  });
  void respond(
    Object? Function(RequestOptions) body, {
    Map<String, List<String>>? headers,
  }) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: body(options),
              headers: Headers.fromMap(headers ?? {}),
            ),
          );
        },
      ),
    );
  }

  final challenge = QrChallenge(
    key: 'synthetic',
    url: 'https://account.bilibili.com/synthetic',
    expiresAt: DateTime.now().add(const Duration(minutes: 3)),
  );

  test(
    'current account host is accepted, an unrelated host is rejected',
    () async {
      var host = 'account.bilibili.com';
      respond((options) {
        expect(options.followRedirects, isFalse);
        expect(options.headers.containsKey('Cookie'), isFalse);
        return {
          'code': 0,
          'data': {'url': 'https://$host/synthetic', 'qrcode_key': 'synthetic'},
        };
      });
      final service = WebAuthService(dio);
      expect(
        (await service.create(CancellationSignal())).url,
        contains('account.bilibili.com'),
      );
      host = 'example.invalid';
      await expectLater(
        service.create(CancellationSignal()),
        throwsFormatException,
      );
    },
  );

  test('QR statuses and completion use Set-Cookie, never a success redirect URL', () async {
    var code = 86101;
    respond(
      (options) => {
        'code': 0,
        'data': {
          'code': code,
          'url':
              'https://example.invalid/redirect?SESSDATA=synthetic-do-not-use',
          'refresh_token': 'synthetic-refresh',
        },
      },
      headers: {
        'set-cookie': [
          'SESSDATA=synthetic-valid; Domain=.bilibili.com; HttpOnly; Secure',
          'bili_jct=synthetic-csrf; Domain=.bilibili.com',
          'DedeUserID=101; Domain=.bilibili.com',
          'tracking=synthetic-ignore; Domain=.bilibili.com',
        ],
      },
    );
    final service = WebAuthService(dio);
    for (final (value, expected) in [
      (86101, QrPollStatus.waiting),
      (86090, QrPollStatus.scanned),
      (86038, QrPollStatus.expired),
    ]) {
      code = value;
      expect(
        (await service.poll(challenge, CancellationSignal())).status,
        expected,
      );
    }
    code = 0;
    final result = await service.poll(challenge, CancellationSignal());
    expect(result.credential!.cookies['SESSDATA'], 'synthetic-valid');
    expect(result.credential!.cookies.containsKey('tracking'), isFalse);
    expect(result.toString(), isNot(contains('synthetic-valid')));
    expect(challenge.toString(), isNot(contains('synthetic')));
  });

  test(
    'refresh and confirmation use distinct old and new CSRF/token pairs',
    () async {
      final requests = <RequestOptions>[];
      respond(
        (options) {
          requests.add(options);
          if (options.uri.path.startsWith('/correspond/1/')) {
            return '<div id="1-name">synthetic-refresh-csrf</div>';
          }
          if (options.uri.path.endsWith('/cookie/refresh')) {
            return {
              'code': 0,
              'data': {'refresh_token': 'synthetic-new-token'},
            };
          }
          return {'code': 0, 'data': null};
        },
        headers: {
          'set-cookie': [
            'SESSDATA=synthetic-new; Domain=.bilibili.com',
            'bili_jct=synthetic-new-csrf; Domain=.bilibili.com',
          ],
        },
      );
      final service = WebAuthService(dio);
      final fresh = await service.refresh(
        syntheticCredential(),
        CancellationSignal(),
      );
      await service.confirmRefresh(
        fresh,
        'synthetic-old-token',
        CancellationSignal(),
      );
      expect(
        requests[0].uri.pathSegments.last,
        matches(RegExp(r'^[0-9a-f]{256}$')),
      );
      expect(requests[1].data, {
        'csrf': 'synthetic-csrf',
        'refresh_csrf': 'synthetic-refresh-csrf',
        'source': 'main_web',
        'refresh_token': 'synthetic-refresh-A',
      });
      expect(requests[2].data, {
        'csrf': 'synthetic-new-csrf',
        'refresh_token': 'synthetic-old-token',
      });
      expect(requests[2].headers['Cookie'], contains('SESSDATA=synthetic-new'));
      expect(requests.every((r) => !r.followRedirects), isTrue);
    },
  );

  test(
    'logout posts biliCSRF and does not follow the server redirect',
    () async {
      respond((options) {
        expect(options.method, 'POST');
        expect(options.data, {'biliCSRF': 'synthetic-csrf'});
        expect(options.followRedirects, isFalse);
        return {
          'code': 0,
          'status': true,
          'data': {'redirectUrl': 'https://example.invalid/ignored'},
        };
      });
      await WebAuthService(dio)
          .logout(syntheticCredential(), CancellationSignal());
    },
  );

  test('account-scoped request sends its own cookie, rejects old owner and cancels on disposal', () async {
    final gate = Completer<void>();
    final entered = Completer<void>();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          expect(options.headers['Cookie'], contains('SESSDATA=synthetic-A'));
          entered.complete();
          await gate.future;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {'code': 0, 'data': <String, Object?>{}},
            ),
          );
        },
      ),
    );
    final api = BilibiliApi(
      dio,
      identity: RequestIdentity(
        const Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
          generation: 3,
        ),
        syntheticCredential().header,
      ),
    );
    expect(() => api.checkOwner('user:202'), throwsA(isA<AppFailure>()));
    final pending = api.get('/synthetic', CancellationSignal());
    final expectation = expectLater(pending, throwsA(anything));
    await entered.future;
    api.close();
    gate.complete();
    await expectation;
    expect(() => api.checkOwner('user:101'), throwsA(isA<AppFailure>()));
  });

  test('guest requests have no cookie; authentication failure triggers validation once without replay', () async {
    var requests = 0, validations = 0;
    respond((options) {
      requests++;
      return {'code': -101, 'data': <String, Object?>{}};
    });
    final api = BilibiliApi(
      dio,
      identity: RequestIdentity(
        const Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
          generation: 8,
        ),
        syntheticCredential().header,
      ),
      onAuthenticationFailure: (generation) async {
        expect(generation, 8);
        validations++;
      },
    );
    await expectLater(
      api.get('/synthetic', CancellationSignal()),
      throwsA(isA<AppFailure>()),
    );
    expect(requests, 1);
    expect(validations, 1);
    dio.interceptors.clear();
    respond((options) {
      expect(options.headers.containsKey('Cookie'), isFalse);
      return {'code': 0, 'data': <String, Object?>{}};
    });
    await BilibiliApi(dio).get('/synthetic', CancellationSignal());
    final offline = RequestIdentity(
      const Session(ownerKey: 'user:101', status: SessionStatus.offline),
      syntheticCredential().header,
    );
    expect(offline.cookie, isNull);
  });
}
