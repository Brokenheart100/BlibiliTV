# 播放器缓冲进度条

播放器控制面板底部现在使用三层进度：深色为总时长背景，浅灰为播放器报告的缓冲进度，白色为播放位置或遥控器跳转预览。暂停时也会更新缓冲条。

## 数据来源与架构

2026-10-27：Android 默认试用 Better Player／Media3，缓冲来源改为原生 `VideoPlayerValue.buffered`，选取覆盖当前播放位置的范围终点；界面比例与跳转清空规则保持一致。原生验证见 [Better Player 试用](better-player-trial.md)。以下 mpv 实现与采样属于 media_kit 回退后端的历史验证。

`MediaKitEngine` 通过 `NativePlayer.observeProperty` 订阅 `demuxer-cache-state`，解析 `seekable-ranges`，选取当前播放位置所在连续缓存区间的终点，写入 `EngineSnapshot.bufferedPosition`。重叠／相邻区间合并，缓存空隙保持分离。原有 Riverpod ViewModel 转发快照，界面按 `bufferedPosition / duration` 显示，并限制到 0–1。缓冲条允许缩短，缓存被回收后不会沿用历史最大值。非 NativePlayer 平台才使用 `player.stream.buffer`。

本项目锁定的 media_kit 1.2.6 使用 `demuxer-cache-time` 生成简化缓冲流，但本次实际 DASH 验证发现该值可停在 -0.1 或旧时间戳，原生真实缓存区间却已覆盖到约 200 秒。因此原生平台直接使用 mpv 的可缓存跳转区间，不使用 `bufferingPercentage`（恢复播放前的缓冲填充比例），也不按播放位置或下载速度伪造进度。详见 [mpv 官方属性文档](https://mpv.io/manual/stable/#properties) 及 [旧终点诊断](playback-buffer-evidence/stale-endpoint-diagnostic.json)。

这是播放预读缓存，不是离线下载。独立音视频来源下也不应将这一终点解释为所有音视频分片均已完整保存。

## 跳转与切换

- 新资源打开或原生 seek 开始时清空缓冲位置，暂缓接收旧时间线事件。
- 跳转预览期间界面隐藏灰色缓存层。
- 原生 seek 就绪后重新读取当前 `demuxer-cache-state`，再恢复事件更新；当前播放位置不属于任何已报告缓存区间时保持空条。
- 画质／音质／分 P 切换沿用播放器实例隔离，旧实例事件不能污染新实例。时间线代次也防止较早的异步读取覆盖新结果。
- 总时长未知时显示空条；负数和超出时长的显示值安全限制在边界内。

## 验证

组件测试覆盖原生快照转发、缓冲增长／回退、负值／超时长、未知时长、快进预览隐藏旧条和画质切换清空缓存；解析测试覆盖旧终点异常、区间合并、缓存空隙及无效数据。完整本机回归 212 项通过，修改源码静态分析通过。

`integration_test/playback_buffer_test.dart` 使用独立验证包、游客会话及专用数据库，对真实公开 DASH 视频检查界面比例、原生缓冲区间、快进／快退清空和恢复。API 36 x86_64 TV 模拟器 Debug 验证通过，报告不记录媒体地址或登录信息；结果见 [native-validation.json](playback-buffer-evidence/native-validation.json)。早期简化终点路径的失败记录保留，不能计作通过。物理 TV 未验证。

实际采样：总时长 436.166 秒，原生缓存到 99.966688 秒，界面灰条比例 22.9193%；跳转到 60.433 秒、再退至 15.433 秒后均与原生缓存区间一致。普通应用已恢复，Flutter MCP 热重载成功；最终可见界面通过 ADB 确认，见 [截图](playback-buffer-evidence/player-buffer.png)。控制面板沿用自动隐藏逻辑。

```powershell
flutter drive --profile --no-uninstall-first --keep-app-running `
  --dart-define=MAMBA_VALIDATION_APP=true `
  --dart-define=MAMBA_READ_ONLY_VALIDATION=true `
  --driver=test_driver/playback_buffer_test.dart `
  --target=integration_test/playback_buffer_test.dart -d emulator-5556
```
