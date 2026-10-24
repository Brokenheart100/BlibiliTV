import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/bilibili_probe_service.dart';
import '../domain/probe_models.dart';

part 'probe_view_model.g.dart';

@riverpod
BilibiliProbeService probeService(Ref ref) {
  final service = BilibiliProbeService();
  ref.onDispose(service.close);
  return service;
}

/// M0 wiring only; M1 will place production dependency providers in App.
@riverpod
class ProbeViewModel extends _$ProbeViewModel {
  CancelToken? _token;
  int _generation = 0;

  @override
  ProbeState build() {
    // Keep the auto-disposed service alive for the entire page lifetime.
    ref.watch(probeServiceProvider);
    ref.onDispose(() {
      _generation++;
      _token?.cancel();
    });
    return const ProbeState();
  }

  Future<void> runGuest() async {
    if (state.busy || state.polling) return;
    final generation = ++_generation;
    _token = CancelToken();
    final service = ref.read(probeServiceProvider);
    service.setCookie(null);
    state = state.copyWith(
      busy: true,
      message: '正在验证真实接口',
      qrUrl: null,
      authenticated: false,
    );
    try {
      final checks = await service.probeGuest(cancelToken: _token);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        busy: false,
        checks: checks,
        playable: service.media != null,
        message: '接口验证结束；播放需单独验证',
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(busy: false, message: describeFailure(error));
      }
    }
  }

  Future<void> startQr() async {
    if (state.busy) return;
    cancelQr();
    final generation = ++_generation;
    final token = _token = CancelToken();
    final service = ref.read(probeServiceProvider);
    state = state.copyWith(polling: true, qrUrl: null, message: '正在申请二维码');
    try {
      final challenge = await service.createQr(token);
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(qrUrl: challenge.url, message: '请使用 B 站手机端扫码并确认');
      final deadline = DateTime.now().add(const Duration(seconds: 180));
      while (ref.mounted &&
          generation == _generation &&
          DateTime.now().isBefore(deadline)) {
        final result = await service.pollQr(challenge, token);
        if (!ref.mounted || generation != _generation) return;
        if (result.code == 0) {
          final verified = await service.verifySession(
            token,
            cookie: result.cookie,
          );
          if (!ref.mounted || generation != _generation) return;
          if (!verified) throw const ProbeFailure('session_not_verified');
          service.setCookie(result.cookie);
          final checks = await service.probeGuest(cancelToken: token);
          if (!ref.mounted || generation != _generation) return;
          state = state.copyWith(
            polling: false,
            qrUrl: null,
            authenticated: true,
            checks: checks,
            playable: service.media != null,
            message: '登录确认且 nav 校验通过；已用同一会话验证内容与播放资源',
          );
          return;
        }
        if (result.code == 86038) break;
        if (result.code != 86101 && result.code != 86090) {
          throw ProbeFailure('qr_status:${result.code}');
        }
        state = state.copyWith(
          message: result.code == 86090 ? '已扫描，等待手机确认' : '等待扫码；可随时取消',
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          polling: false,
          qrUrl: null,
          message: '二维码已过期，请重新申请',
        );
      }
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = state.copyWith(
          polling: false,
          qrUrl: null,
          message: describeFailure(error),
        );
      }
    }
  }

  void cancelQr() {
    _generation++;
    _token?.cancel();
    state = state.copyWith(
      busy: false,
      polling: false,
      qrUrl: null,
      message: '已停止二维码轮询',
    );
  }

  void clearSession() {
    cancelQr();
    ref.read(probeServiceProvider).setCookie(null);
    state = state.copyWith(
      authenticated: false,
      playable: false,
      message: 'M0 内存会话已清理',
    );
  }
}
