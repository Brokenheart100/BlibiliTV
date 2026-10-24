import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../data/bilibili_probe_service.dart';
import '../data/playback_configuration.dart';
import '../domain/probe_models.dart';
import 'probe_view_model.dart';

class M0ProbeApp extends StatelessWidget {
  const M0ProbeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MambaTV M0',
    theme: ThemeData.dark(useMaterial3: true),
    home: const ProbePage(),
  );
}

class ProbePage extends ConsumerStatefulWidget {
  const ProbePage({super.key});
  @override
  ConsumerState<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends ConsumerState<ProbePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      ref.read(probeViewModelProvider.notifier).cancelQr();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(probeViewModelProvider);
    final vm = ref.read(probeViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('MambaTV · M0 技术验证')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '独立验证入口：真实接口 / Riverpod + Freezed / 扫码 / 音视频分离',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                FilledButton(
                  key: const Key('guest-probe'),
                  autofocus: true,
                  onPressed: state.busy || state.polling ? null : vm.runGuest,
                  child: const Text('验证游客接口'),
                ),
                FilledButton(
                  key: const Key('qr-start'),
                  onPressed: state.busy ? null : vm.startQr,
                  child: const Text('扫码验证账号'),
                ),
                OutlinedButton(
                  key: const Key('qr-cancel'),
                  onPressed: state.polling ? vm.cancelQr : null,
                  child: const Text('取消扫码'),
                ),
                FilledButton(
                  key: const Key('play-probe'),
                  onPressed: state.playable && !state.polling && !state.busy
                      ? () async {
                          final media = ref.read(probeServiceProvider).media;
                          if (media == null) return;
                          vm.cancelQr();
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ProbePlayerPage(media: media),
                            ),
                          );
                        }
                      : null,
                  child: const Text('验证独立音视频播放'),
                ),
                OutlinedButton(
                  onPressed: state.busy ? null : vm.clearSession,
                  child: const Text('清理 M0 内存会话'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              key: const Key('probe-message'),
              style: const TextStyle(fontSize: 20),
            ),
            if (state.busy) const LinearProgressIndicator(),
            for (final check in state.checks)
              ListTile(
                leading: Icon(
                  check.passed ? Icons.check_circle : Icons.error_outline,
                ),
                title: Text(check.capability),
                subtitle: Text(check.detail),
              ),
            if (state.qrUrl != null)
              Center(
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: PrettyQrView.data(data: state.qrUrl!),
                ),
              ),
            const SizedBox(height: 12),
            const Text('日志与证据仅记录状态，二维码、Cookie、签名媒体 URL 不写入报告。此页不是正式产品 UI。'),
          ],
        ),
      ),
    );
  }
}

class ProbePlayerPage extends StatefulWidget {
  const ProbePlayerPage({required this.media, super.key});
  final ProbeMedia media;
  @override
  State<ProbePlayerPage> createState() => _ProbePlayerPageState();
}

class _ProbePlayerPageState extends State<ProbePlayerPage>
    with WidgetsBindingObserver {
  late final Player player = Player();
  late final VideoController controller = VideoController(
    player,
    configuration: probeVideoConfiguration(),
  );
  String status = '正在打开独立视频与音轨';
  StreamSubscription<String>? errors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    errors = player.stream.error.listen((_) {
      if (mounted) setState(() => status = '媒体引擎报告错误（地址已隐藏）');
    });
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      await player.open(
        Media(
          widget.media.videoUrl,
          httpHeaders: BilibiliProbeService.mediaHeaders,
        ),
        play: false,
      );
      if (!mounted) return;
      await player.setAudioTrack(AudioTrack.uri(widget.media.audioUrl));
      if (!mounted) return;
      await player.play();
      if (mounted) setState(() => status = '已提交播放；需验证视频首帧、音轨和 seek');
    } catch (_) {
      if (mounted) setState(() => status = '打开失败（地址已隐藏）');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(player.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(errors?.cancel());
    unawaited(player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('M0 播放 · ${widget.media.bvid} / ${widget.media.codec}'),
    ),
    body: Column(
      children: [
        Expanded(child: Video(controller: controller, controls: null)),
        Text(status),
        StreamBuilder<Duration>(
          stream: player.stream.position,
          builder: (context, snapshot) => Text(
            '播放位置：${snapshot.data?.inSeconds ?? 0} 秒',
            key: const Key('play-position'),
          ),
        ),
        Wrap(
          spacing: 16,
          children: [
            FilledButton(
              key: const Key('play-pause'),
              autofocus: true,
              onPressed: player.playOrPause,
              child: const Text('播放 / 暂停'),
            ),
            FilledButton(
              key: const Key('seek-10'),
              onPressed: () => player.seek(const Duration(seconds: 10)),
              child: const Text('跳转至 10 秒'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回并释放'),
            ),
          ],
        ),
      ],
    ),
  );
}
