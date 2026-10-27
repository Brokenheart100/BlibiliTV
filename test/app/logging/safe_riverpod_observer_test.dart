import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker/talker.dart';
import 'package:mambatv/app/logging/app_container.dart';
import 'package:mambatv/app/logging/app_talker.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

class _PlayerFixture extends Notifier<PlayerState> {
  @override
  PlayerState build() => const PlayerState(phase: PlayerPhase.playing);
  void emit(PlayerState value) => state = value;
}

class _PrivateData {
  @override
  String toString() => throw StateError('Raw state must never be formatted');
}

void main() {
  test(
    'shared Talker filters native clock floods and records meaningful state',
    () {
      final talker = createAppTalker(console: false);
      final container = createAppContainer(talker: talker);
      final provider = NotifierProvider<_PlayerFixture, PlayerState>(
        _PlayerFixture.new,
        name: 'playerViewModelProvider',
      );
      final listener = container.listen(provider, (_, _) {});
      expect(identical(container.read(appTalkerProvider), talker), isTrue);
      final initial = talker.history.length;
      final notifier = container.read(provider.notifier);
      for (var i = 1; i <= 1000; i++) {
        notifier.emit(
          PlayerState(
            phase: PlayerPhase.playing,
            title: 'private-title',
            partId: 'private-id',
            snapshot: EngineSnapshot(
              position: Duration(milliseconds: i * 100),
              bufferedPosition: Duration(seconds: i),
            ),
          ),
        );
      }
      expect(talker.history.length, initial);
      notifier.emit(const PlayerState(phase: PlayerPhase.paused));
      expect(talker.history.length, initial + 1);
      recordHttpMetadata(
        container.read(appTalkerProvider),
        '{"event":"http","method":"GET","status":200,"category":"response","elapsedMs":1}',
      );
      expect(talker.history.last.key, TalkerKey.httpResponse);
      expect(
        talker.history.map((log) => log.generateTextMessage()).join(),
        isNot(contains('private-')),
      );
      listener.close();
      container.dispose();
      expect(talker.history, isEmpty);
      expect(talker.settings.enabled, isFalse);
    },
  );

  test('family arguments, raw objects and errors never reach log history', () async {
    final talker = createAppTalker(console: false);
    final container = createAppContainer(talker: talker);
    addTearDown(container.dispose);
    final family = Provider.autoDispose.family<Object?, String>(
      (_, _) => _PrivateData(),
      name: 'personalProfileProvider',
    );
    container.read(
      Provider(
        (_) => const Session(
          ownerKey: 'user:secret-token',
          displayName: 'private-user',
          status: SessionStatus.authenticated,
        ),
        name: 'sessionProvider',
      ),
    );
    final sub = container.listen(family('user:secret-token'), (_, _) {});
    sub.close();
    await container.pump();
    final failed = FutureProvider.autoDispose<Object?>((_) async {
      throw const AppFailure(
        FailureKind.authentication,
        'SESSDATA=secret-token https://private.invalid/play?token=secret-token',
      );
    }, name: 'catalogViewModelProvider');
    final failSub = container.listen(failed, (_, _) {});
    await expectLater(
      container.read(failed.future),
      throwsA(isA<AppFailure>()),
    );
    await container.pump();
    failSub.close();
    await container.pump();
    expect(
      talker.history.any(
        (log) => jsonDecode(log.message!)['failure'] == 'authentication',
      ),
      isTrue,
    );
    for (final log in talker.history) {
      final text = log.generateTextMessage();
      for (final secret in [
        'secret-token',
        'private.invalid',
        'SESSDATA',
        '_PrivateData',
        'private-user',
      ]) {
        expect(text, isNot(contains(secret)));
      }
      expect(log.exception, isNull);
      expect(log.error, isNull);
      expect(log.stackTrace, isNull);
    }
    expect(
      talker.history.any(
        (log) => jsonDecode(log.message!)['event'] == 'disposed',
      ),
      isTrue,
    );
  });

  test('unselected providers and disabled diagnostics retain nothing', () {
    final talker = createAppTalker(console: false);
    final container = createAppContainer(talker: talker);
    container.read(Provider((_) => 'secret', name: 'danmakuViewModelProvider'));
    expect(talker.history, isEmpty);
    container.dispose();
    final disabled = createAppTalker(enabled: false, console: false);
    final off = createAppContainer(talker: disabled);
    off.read(Provider((_) => 'secret', name: 'sessionProvider'));
    expect(disabled.history, isEmpty);
    off.dispose();
  });
}
