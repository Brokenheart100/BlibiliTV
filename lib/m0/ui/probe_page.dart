import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../data/services/playback/better_player_engine.dart';
import '../../domain/playback/playback.dart';
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
  final engine = BetterPlayerEngine();
  String status = '正在打开独立视频与音轨';
  StreamSubscription<EngineSnapshot>? errors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    errors = engine.snapshots.listen((snapshot) {
      if (mounted && snapshot.failure != null) {
        setState(() => status = '媒体引擎报告错误（地址已隐藏）');
      }
    });
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      await engine.open(widget.media.source, startAt: Duration.zero);
      if (mounted) setState(() => status = '已提交播放；需验证视频首帧、音轨和 seek');
    } catch (_) {
      if (mounted) setState(() => status = '打开失败（地址已隐藏）');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(engine.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(errors?.cancel());
    unawaited(engine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('M0 播放 · ${widget.media.bvid} / ${widget.media.codec}'),
    ),
    body: Column(
      children: [
        Expanded(child: BetterPlayerSurface(engine)),
        Text(status),
        StreamBuilder<EngineSnapshot>(
          stream: engine.snapshots,
          builder: (context, snapshot) => Text(
            '播放位置：${snapshot.data?.position.inSeconds ?? 0} 秒',
            key: const Key('play-position'),
          ),
        ),
        Wrap(
          spacing: 16,
          children: [
            FilledButton(
              key: const Key('play-pause'),
              autofocus: true,
              onPressed: () =>
                  engine.snapshot.playing ? engine.pause() : engine.play(),
              child: const Text('播放 / 暂停'),
            ),
            FilledButton(
              key: const Key('seek-10'),
              onPressed: () => engine.seek(const Duration(seconds: 10)),
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
