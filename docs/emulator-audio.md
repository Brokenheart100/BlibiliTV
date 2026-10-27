# Windows TV 模拟器杂音与无声处理

本机 HDMI 显示器输出下，将 Android Emulator 宿主输出切换为 **DirectSound** 后，用户确认同一片段“能听到，声音干净”。只调整模拟器启动参数；产品仍使用 media_kit／mpv 的 OpenSL ES 输出，没有切换产品音频后端。

## 重现与启动

先正常关闭准备重启的 `Mamba_TV_API36`，再在项目根目录执行：

```powershell
.\tool\start_tv_emulator.ps1
flutter run -d emulator-5556
```

脚本从 `ANDROID_HOME`、`ANDROID_SDK_ROOT` 或 `android/local.properties` 查找 SDK；可显式传入 `-AndroidSdk`、`-AvdName`、`-Port`。支持 `-WhatIf`，不会自动关闭其他模拟器、清除数据或修改 Windows 总音量。不要重复启动已运行的同名 AVD。

核心参数为 `-audio dsound`，冷启动且不加载／保存快照。当前实例 `Mamba_TV_API36` 的 `hw.audioInput=no`、`hw.audioOutput=yes`；关闭麦克风单独测试未恢复声音，不能认定麦克风是原因。该设置为本机已有实验配置，脚本不修改 AVD 配置文件。

这是 Windows 开发模拟器的兼容性处理，不随 APK 发布，也没有证据说明物理电视需要相同调整。命令行音频选项见 [Android 官方文档](https://developer.android.com/studio/run/emulator-commandline)。本机 Emulator 37.2.12.0 已实测接受 `-audio dsound`。

## 验证结果与边界

同一公开视频 `BV1wR4Xz6EqG`、同一 AAC 来源：

| 验证 | 结果 |
| --- | --- |
| Windows 直接播放 35–55 秒片段 | 用户确认声音干净 |
| 模拟器内 OpenSL ES／PCM16 等诊断 | 用户仍报告杂音；AudioTrack float 还出现超过 1 秒同步偏差与原生错误，未采用 |
| 本项目 AVD 冷启动、关闭麦克风、提高媒体音量 | 用户反复确认无声；不能按“无杂音”验收 |
| 无声时 Windows 会话 | 未静音，音量 100%，输出为 G7u HDMI；播放期间 100 次进程电平采样全部为 0 |
| 同一 AVD 冷启动并指定 DirectSound | Windows 会话 100 次采样全部非零，最大峰值 0.054992847；用户确认能听到且声音干净 |

Android AudioFlinger 在无声阶段有活动音轨和非零信号功率，Windows 进程电平却为零；结果支持问题位于模拟器宿主音频输出环节。由于改后也经历冷启动，尚不能将根因精确归于默认后端的某一个实现缺陷。验收覆盖本机本次片段，不代表长期播放或其他电脑／电视均已验证。

原始诊断记录在 [audio-output-evidence](audio-output-evidence)，人工反馈单列在 [summary.json](audio-output-evidence/summary.json)。`manualNoiseFreeVerified=false` 的原始自动报告不代表人工未确认；自动报告本身无法判断听感。

DirectSound 下 90 秒自动诊断完成，原生错误为 0，记录到的最大音画偏差为 0.000925 秒。新增 Dart 诊断源码分析通过，启动脚本语法与 `-WhatIf` 检查通过；已恢复普通应用界面，Flutter MCP 热重载成功，运行时错误为 0。

## 回归诊断

`integration_test/audio_output_test.dart` 通过真实游客接口解析来源，使用独立验证包，记录实际音频后端、采样格式和同步数值；报告不含媒体 URL 或登录信息。手动短测可运行：

```powershell
$env:AUDIO_REPORT_PREFIX='manual-recheck'
flutter drive --profile --no-uninstall-first --keep-app-running `
  --dart-define=MAMBA_VALIDATION_APP=true `
  --dart-define=MAMBA_READ_ONLY_VALIDATION=true `
  --dart-define=AUDIO_SINGLE_BACKEND=true `
  --dart-define=AUDIO_LISTEN_SECONDS=90 `
  --driver=test_driver/audio_output_test.dart `
  --target=integration_test/audio_output_test.dart -d emulator-5556
```

默认不传 `AUDIO_SINGLE_BACKEND` 时会比较四种输出，属于诊断实验。通过测试只表示诊断流程完成，听感仍须人工确认。Windows 直接 AAC 对照入口为 `tool/audio_windows_probe.dart`，要求本机已有 Windows Debug 构建及 libmpv DLL。

播放器当前的“音轨”菜单实际提供 AAC 码率选项。一般选择最高可用码率即可；提高码率不能修复模拟器宿主输出错误。
