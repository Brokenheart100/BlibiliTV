# 音画同步与快进／快退修复

日期：2026-10-26。用户反馈：音画不同步，跳转后卡住、黑屏或声音没有跟上。修复继续使用现有官方 media_kit 和单个 mpv 播放器，实际验收结果见文末。

## 问题与修复

1. 原 `seek()` 在 Dart 播放位置进入目标附近就结束。真实 profile 原基线对照中，调用在 7–29 ms 返回，但 250 ms 后的样本仍可能是 `seeking=yes`、`audio-pts` 不可用。mpv 命令已接收不等于解码／音轨输出已经恢复。
2. 原 ViewModel 为每个方向键排队发起独立原生 seek。现在将连续输入累计为一个明确目标，同时最多执行一次原生 seek；执行期间新的输入只更新最终目标。进度条显示“跳转至”，等待期间保持可见；目标不写入已确认的播放进度。
3. 原跳转失败只显示重试提示，未释放卡住的原生会话。现在在 10 秒内没有恢复时进入既有、有次数限制的会话恢复流程，按最终目标重新加载，保留暂停意图。换 P、换画质、后台和关闭会使旧 seek 目标失效。
4. Data 适配器恢复 mpv 的 `hr-seek-framedrop=yes`，允许精确 seek 时丢弃目标前的解码帧；显式保持 `initial-audio-sync=yes`。起播也等待音视频输出就绪。

原生完成判定需要连续两次观察满足：`seeking=no`、`paused-for-cache=no`、视频输出已配置、播放位置已到达请求范围；播放中还要求音频时间戳可用，原生 A/V 差值和音频时间戳与播放位置的差值均不超过 250 ms。暂停时不要求正在输出的音频时间戳，不会为了验收跳转而擅自播放声音。该阈值是故障恢复保护，不能替代人的口型／听感判断。

## 本轮未采用的变更

27 次单次跳转诊断分别对照原外部音轨、允许解码丢帧、EDL 组合源，均能恢复，未证明 EDL 能修复这次反馈。保持当前源接入方式，避免同时改变源组合、同步模式和音频输出后无法判断原因。`display-resample`、音频输出后端和手动音频偏移未随本次修复调整。

mpv 的 seek、音轨加载和同步定义参见 [官方手册](https://mpv.io/manual/stable/)；EDL 的 `new_stream` 和统一缓存范围参见 [官方 EDL 说明](https://github.com/mpv-player/mpv/blob/master/DOCS/edl-mpv.rst)。

## 验证方法

- ViewModel 回归覆盖原生 seek 阻塞期间的连续方向变化、超时重新加载并保留暂停、换 P 取消旧目标；继续检查进度保存和单引擎生命周期。
- `integration_test/playback_seek_sync_test.dart` 使用公开真实 DASH 视频、独立 `.validation` 包和只读标记，不读取真实账号。测试普通前后跳转、接近片尾／回零、暂停跳转及 0.5／1.5／2／1 倍速跳转。
- 完整测试持续 900 秒，每 20 秒在多个位置前后跳转；每约 250 ms 检查原生 seeking、音频时间戳和 A/V 差值，每 5 秒保存一个样本。该测试刻意隔离字幕和弹幕，不作为 M8 覆盖层性能通过的证据。
- 本地另在长测跳转后抽取 TV 模拟器画面，检查是否有全黑画面并查看不同目标的实际内容。课件视频本身可静止数秒，不能把相同画面直接判为播放器停帧。

## 结果

原始诊断为 [seek-diagnostic.json](playback-fix-evidence/seek-diagnostic.json)；第一轮 60 秒短测为 [seek-smoke.json](playback-fix-evidence/seek-smoke.json)。完整 [900 秒报告](playback-fix-evidence/seek-validation.json)已通过：11 次普通／边界跳转、2 次暂停跳转、4 次倍速跳转和持续阶段 44 次跳转，共 61 次。没有跳转超时或原生错误流事件。普通跳转返回耗时 261–580 ms，返回时已结束 seeking 且音频时间戳可用。

每 5 秒保存的稳定阶段样本最大原生 A/V 差值为 0.044 ms；所有保存样本的最大差值为 139.684 ms，出现在 2 倍速切换后的即时检查，仍低于本轮 250 ms 保护阈值。88 张跳转后截图包含 43 个不同中心裁剪摘要，未出现全黑图；它们不证明每一帧都没有停顿。统计与本地源码／profile APK 摘要见 [summary.json](playback-fix-evidence/summary.json)。

最终 207 项 Flutter 单元／Widget 回归、fatal-infos 静态分析、代码生成与格式检查通过。实际页面通过 ADB 遥控器连按显示目标并恢复播放；暂停后执行两次快进和四次后退，从 05:53 到 05:33，暂停保持，退出后热重启正常，Flutter MCP 未发现运行时错误。见 [页面复验](playback-fix-evidence/ui-validation.json)。

开发限制：播放中直接执行 Dart 热重启，曾在 libmpv 触发原生崩溃并断开调试连接；冷启动可恢复，先退出播放器再热重启通过。该问题根因尚未定位，不属于上面的生产 profile 长测通过范围。开发时应先关闭播放；未将该原生问题宣称已修复。

本轮未进行物理 ARM TV 人工音画验收。旧 M7 的异常样本和 M8 弹幕性能未通过记录保留，不因本次局部回归通过而改变其历史结论。

## 重现

确认 AVD 归属和只读标记，构建与长测串行执行：

```powershell
flutter test --concurrency 2 --reporter expanded
flutter analyze --fatal-infos
flutter drive --profile --driver test_driver/playback_seek_sync_test.dart --target integration_test/playback_seek_sync_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --no-uninstall-first --keep-app-running
```

`SEEK_SOAK_SECONDS=60` 只用于短测，不能替代默认 900 秒。`SEEK_EXPERIMENTS=true` 用于诊断对照，不作为通过验收；报告中明确区分 `diagnostic`、`seek-smoke`、`seek-rejected` 和 `seek-validation`。
