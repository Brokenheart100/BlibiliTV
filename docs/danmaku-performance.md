# 弹幕性能优化与当前播放器回归

日期：2026-10-28。源码基线 `af884a5`，本轮为其上的工作区增量。

**结论：应用侧调度／字形缓存优化已实现，当前 Better Player／Media3 的 15 分钟播放稳定性回归通过；弹幕性能门槛仍未通过，整体验收结果为失败。** M8 不因本轮应用侧优化而提前标为验收完成。

2026-10-28 后续按用户要求暂停字幕，只验证固定最高密度。最新结果见 [仅弹幕最高密度专项报告](danmaku-max-density-validation.md)：密度／连续运行通过，短窗通过，持续慢帧仍待优化。下文是此前字幕＋弹幕组合测试记录。

## 实现与边界

- 继续使用官方 `canvas_danmaku 0.3.3`，不修改全局 Pub 缓存，也不启用 `third_party` 补丁。
- 原生进度／缓冲事件只校准媒体时钟；普通准入由已有的 50 ms 采样器执行，暂停、缓冲变化、真实 seek／倍速改变仍立即处理。新增测试用 100 次原生缓冲事件验证没有 100 次重复准入。
- 为官方画布接受的普通文字图片加入路由级 LRU：最多 64 项／4 MiB，按文字、颜色、透明度、字号及设备像素比隔离。命中后以 `Image.clone()` 替换尚未绘制的新图片；画布与缓存分别拥有句柄，淘汰与退出分别释放。不同文字仍走官方栅格化路径，缓存不能保证所有视频的帧率改善。
- 实际上屏统计不再展开复制整个画布对象列表。视频纹理增加独立重绘边界，只在视频尺寸变化时重建布局；原生纹理仍由 Better Player 更新。
- 保留原有密度保护 40→20→10，最低档持续显示，不自动清屏／关弹幕；没有降低字号、像素比、屏幕分辨率、刷新率或放宽验收门槛。

## 当前原生性能证据

API 36、x86_64、`Mamba_TV_API36`、`emulator-5556`、1920×1080／density 320、host GPU，冷启动且不加载／保存 snapshot。另一个已有 `emulator-5554` 保留，未停止或更改。最终测量期间没有并行构建或全量测试。

播放器为 **Better Player／Media3**，Flutter 默认使用 **Impeller OpenGLES**。旧 M8 测试固定使用 MediaKit，本轮已迁移为当前引擎和当前应用容器；字幕时序改读 Media3 的原生 `controller.position`，不伪造 mpv 的 `time-pos`／`avsync`／音频采样率属性。

同一视频、同一位置、同一解码配置，每个模式预热 18 秒、记录约 10 秒。原门槛保持 build／raster P95≤16.7 ms，弹幕相对全关的 raster P95 增量≤3 ms；同时检查实际画布绘制时钟推进，自动停用的成绩不接受。

| 版本／模式 | build P95 | raster P95 | 说明 |
| --- | ---: | ---: | --- |
| 优化前：全关 | 0.864 ms | 2.834 ms | 基线 |
| 优化前：字幕＋弹幕 | 1.378 ms | 16.336 ms | 增量 13.502 ms，未通过 |
| 最终版：全关 | 0.934 ms | 4.105 ms | 本轮对照 |
| 最终版：仅字幕 | 0.784 ms | 3.283 ms | 201 次采样／201 次调度 |
| 最终版：字幕＋弹幕 | 1.740 ms | 18.237 ms | 增量 14.132 ms，密度已降至 10，未通过 |

这组结果**没有证明整体帧性能改善**。调度去重与有界图片复用由测试和运行计数验证；不能把缓存命中率直接等同于 FPS 收益，也不能把重复合成文字的命中率推广到全部真实弹幕。

额外诊断捕获到画面提交阶段 `SurfaceFrame::Submit` P95 约 16.9 ms，`LayerTree::Paint` P95 约 0.44 ms，见 [跟踪摘要](m8-performance-evidence/impeller-gles-trace-summary.json)。这指向提交／GPU 等待阶段，尚不足以认定模拟器或某个驱动是唯一根因。保持同一 APK 的 Skia 对照也未通过；全物理像素画布适配没有改善，已撤回，不进入最终实现。

原始报告保留在 [证据目录](m8-performance-evidence/)：`better-baseline-rejected-native.json`、`better-isolated-rejected-native.json`、`better-pixel-grid-rejected-native.json`、`better-baseline-skia-rejected-native.json`。最终 APK 和修改源码的 SHA256 见 [构建指纹](m8-performance-evidence/better-final-build.json)。诊断跟踪窗口与正式 A/B 分开记录。

## 连续回归

最终回归已完成。先完成 20 次进出、暂停时正反向 seek、播放中连续 seek、画质／音轨切换、0.5／1／2 倍速字幕时序和 10 次实际 HOME 返回，再从新媒体时间轴计满 900 秒。公开真实弹幕叠加每媒体秒 20 条合成输入；字幕为两轨合成 fixture。

性能断言移到连续回归末尾执行，门槛及最终失败状态保留：即使 A/B 未达标也收集完整长播证据，不再只因性能断言提前退出。长播稳定与整体性能验收分别报告。

- 累计有效媒体推进 **899.931 秒**；主机连续段计满 900 秒，包含退出清理后的报告时间为 902 秒。每分钟累计媒体进度与单调时钟差值均小于既定 30 秒门槛。
- 第 436 秒从首 P 自然切到第二 P；弹幕分段跨界、自然换 P 后的准入及画布绘制时钟持续推进，自动停用次数为 0。实际密度保护降至 10，不能称为全程 40 条密度验收。
- 原生错误事件 **0**，远端写入 **0**。8 次控制采样的原生位置与快照相符，画质／音轨切换保持暂停意图；3 个倍速字幕采样均落在对应 cue 内，不能替代全程人工音画验收。
- 创建／释放原生引擎 **37／37**，同时最多 1 个，退出后 0 个；覆盖层创建／销毁 **38／38**，活动覆盖层和采样器均为 0。
- 字形缓存退出后为 **0 字节**；每分钟样本中最高 1,977,100 字节（约 1.89 MiB）。累计命中 1,941 次／未命中 160 次，统计包含前置检查和长播；负载含重复合成文本，不能作为真实弹幕命中率。
- 长播进程 RSS 每分钟样本为 354,041,856～381,235,200 字节；只说明本次窗口，不能据此宣布长期无内存增长。

完整报告为 [better-final-rejected-native.json](m8-performance-evidence/better-final-rejected-native.json)，总状态 `failed`，其中 `playbackRegressionStatus=passed`、`fifteenMinuteThresholdMet=true`；失败原因严格保留为 raster P95>16.7 ms 和增量>3 ms。简表见 [validation-summary.json](m8-performance-evidence/validation-summary.json)，运行画面见 [better-final-soak.png](m8-performance-evidence/better-final-soak.png)。

预检：253 项 Flutter 单元／Widget 测试、13 项 Python CI 守卫、`flutter analyze --fatal-infos`、263 份 Dart 文件格式检查通过；Flutter MCP 定向分析无诊断；长播结束后，隔离验证包的普通 `lib/main.dart` 入口热重载成功，运行时错误为 0，见 [mcp.json](m8-performance-evidence/mcp.json)。未运行新的远端 CI 或创建 Release。

## 复现

先确认 5556 是本项目 AVD，在一个终端运行：

```powershell
$env:M8_RUN_LABEL='better-final'
flutter drive --profile --driver test_driver/m8_stability_test.dart --target integration_test/m8_stability_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --dart-define=M8_HOST_CYCLES=true --no-uninstall-first --keep-app-running
```

将上面的命令输出保存到 `.m0/m8-better-final.log`，另一个终端运行 `tool/m8_host_cycles.ps1 -Device emulator-5556 -AdbPath <ADB绝对路径>`。脚本仅操作选定设备上的隔离验证包；不清除应用或模拟器数据。主驱动默认 900 秒／20 次进出，报告写入 `docs/m8-performance-evidence/<M8_RUN_LABEL>-*.json`。

物理 ARM TV、人工听感／口型、真实多轨字幕和签名设备升级仍不属于本轮自动验收；账号会话为隔离游客，远端写入必须为 0。
