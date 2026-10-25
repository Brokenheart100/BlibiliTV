import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';

import '../../../domain/playback/playback.dart';

class AudioSessionFocus implements PlaybackFocus {
  AudioSessionFocus({Future<AudioSession> Function()? sessionFactory})
    : _loadSession = sessionFactory ?? (() => AudioSession.instance);
  final Future<AudioSession> Function() _loadSession;
  static const _input = MethodChannel('mambatv/input');
  final _events = StreamController<void>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<Object?>>[];
  Future<AudioSession>? _session;
  Object? _owner;
  Future<void> _operations = Future<void>.value();
  Future<void>? _disposing;
  bool _disposed = false;
  Future<AudioSession> _initialize() async {
    _input.setMethodCallHandler((call) async {
      if (call.method == 'remoteChanged' &&
          call.arguments == false &&
          !_events.isClosed) {
        _events.add(null);
      }
    });
    final session = await _loadSession();
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
    _subscriptions.addAll([
      session.interruptionEventStream.listen((event) {
        if (event.begin && !_events.isClosed) _events.add(null);
      }),
      session.becomingNoisyEventStream.listen((_) {
        if (!_events.isClosed) _events.add(null);
      }),
    ]);
    return session;
  }

  @override
  Stream<void> get interruptions => _events.stream;
  @override
  Future<bool> acquire(Object owner) {
    final request = _operations.then((_) async {
      if (_disposed) return false;
      final session = await (_session ??= _initialize());
      if (_disposed) return false;
      final granted = await session.setActive(true);
      if (granted) _owner = owner;
      return granted;
    });
    _operations = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  @override
  Future<void> release(Object owner) {
    final request = _operations.then((_) async {
      if (!identical(_owner, owner)) return;
      _owner = null;
      if (_session != null) await (await _session!).setActive(false);
    });
    _operations = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return request;
  }

  Future<void> dispose() => _disposing ??= _dispose();
  Future<void> _dispose() async {
    _disposed = true;
    _input.setMethodCallHandler(null);
    await _operations;
    if (_session != null && _owner != null) {
      await (await _session!).setActive(false);
    }
    _owner = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _events.close();
  }
}
