import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/persistent_session_repository.dart';
import 'package:mambatv/data/repositories/web_auth_repository.dart';
import 'package:mambatv/domain/auth/auth.dart';
import 'package:mambatv/data/services/network/bilibili_http_cache.dart';

import '../support/fake_auth.dart';
import '../support/memory_preferences.dart';

void main() {
  test('a watched API provider closes each old scope and binds only the current credential', () async {
    final gateway = FakeAuthGateway();
    final sessions = PersistentSessionRepository(
      gateway,
      MemoryCredentialStore(),
      MemoryPreferencesStore(),
    );
    final dio = Dio()..interceptors.add(BilibiliCacheInterceptor());
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        persistentSessionProvider.overrideWithValue(sessions),
        apiClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.dispose();
      dio.close(force: true);
    });
    final sessionSubscription = container.listen(sessionProvider, (_, _) {});
    addTearDown(sessionSubscription.close);
    await container.read(sessionProvider.future);
    final subscription = container.listen(bilibiliApiProvider, (_, _) {});
    addTearDown(subscription.close);
    final guestApi = container.read(bilibiliApiProvider);
    expect(guestApi.identity.cookie, isNull);
    await sessions.signIn(
      syntheticCredential(),
      sessions.revision,
      CancellationSignal(),
    );
    await container.pump();
    final accountA = container.read(bilibiliApiProvider);
    expect(accountA.identity.session.ownerKey, 'user:101');
    expect(accountA.identity.cookie, contains('SESSDATA=synthetic-A'));
    RequestOptions? accountRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          accountRequest = request;
          handler.resolve(
            Response<Object?>(
              requestOptions: request,
              statusCode: 200,
              data: {
                'code': 0,
                'data': {'synthetic': true},
              },
            ),
            true,
          );
        },
      ),
    );
    await accountA.get('/x/web-interface/popular', CancellationSignal());
    final cachedOptions = accountRequest!.getCacheOptions()!;
    final cacheKey = cachedOptions.keyBuilder(url: accountRequest!.uri);
    expect(await cachedOptions.store!.exists(cacheKey), isTrue);
    expect(() => guestApi.checkOwner('guest'), throwsA(isA<AppFailure>()));
    final oldGeneration = accountA.identity.session.generation;
    await sessions.logout();
    await sessions.signIn(
      syntheticCredential('B'),
      sessions.revision,
      CancellationSignal(),
    );
    await container.pump();
    final accountB = container.read(bilibiliApiProvider);
    expect(accountB.identity.session.ownerKey, 'user:202');
    expect(accountB.identity.cookie, contains('SESSDATA=synthetic-B'));
    expect(
      await cachedOptions.store!.exists(cacheKey),
      isFalse,
      reason:
          'The actual Riverpod session replacement must clear the old store',
    );
    expect(() => accountA.checkOwner('user:101'), throwsA(isA<AppFailure>()));
    expect(() => accountB.checkOwner('user:101'), throwsA(isA<AppFailure>()));
    final verifies = gateway.verifies;
    await sessions.authenticationFailed(oldGeneration);
    expect(gateway.verifies, verifies);
    final generation = sessions.current.generation;
    await sessions.revalidate(force: true);
    expect(
      sessions.current.generation,
      generation,
      reason: 'A valid unchanged session cannot trigger a rebuild loop',
    );
  });

  test(
    'an old QR completion cannot replace a newer signed-in account',
    () async {
      final gateway = FakeAuthGateway();
      final sessions = PersistentSessionRepository(
        gateway,
        MemoryCredentialStore(),
        MemoryPreferencesStore(),
      );
      addTearDown(sessions.dispose);
      await sessions.restore();
      final auth = WebAuthRepository(gateway, sessions);
      final signal = CancellationSignal();
      final challenge = (await auth.create(signal)).valueOrThrow;
      await sessions.signIn(
        syntheticCredential('B'),
        sessions.revision,
        CancellationSignal(),
      );
      gateway.pollStatus = QrPollStatus.completed;
      expect(
        await auth.poll(challenge, signal),
        isA<ResultFailure<QrPollStatus>>(),
      );
      expect(sessions.current.ownerKey, 'user:202');
      expect(sessions.capture().cookie, contains('SESSDATA=synthetic-B'));
    },
  );
}
