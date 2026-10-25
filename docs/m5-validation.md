# M5：播放器控制与恢复验收

日期：2026-10-25。状态：功能已实现，本机与 TV 模拟器自动验收通过。用户明确暂不人工听看；人工听感／口型同步、物理电视／ARM 验收仍待补充，不能视为 M7 发布验收。

设计、范围与恢复预算见 [ADR 0006](adr/0006-playback-controls-and-recovery.md)。图片和 HTTP 缓存继续使用原方案；playurl／签名媒体资源不进入缓存。

## 实现

- iOS 深色玻璃控制条，5 秒隐藏、画面确认／左右 seek、完整 D-pad 控制、弹层按键隔离与焦点返回。
- 实际可用 AVC 清晰度与 AAC 音轨、倍速、播放器音量、103 P 等长列表定位、下一集与可关闭的连续播放。
- 串行命令与最新意图优先；换画质／音轨保留位置、倍速、音量、暂停意图；快速换集无双引擎及串写。
- 本地进度节流、倒退 seek／暂停／退出保存、完成判定与零时间轴保护。
- 有预算的备用线路／重新解析；账号、权限、限流、契约及解码错误停止自动恢复。
- 音频焦点／耳机与遥控器中断、后台、Home、休眠和路由遮挡处理；恢复后需确认，旧路由不能释放新路由的焦点。

## 验证与边界

本机 152 项测试通过，较 M4 缓存补充的 113 项新增 39 项，覆盖暂停切换、迟到响应、快速选集、串行 seek、进度、完成与连播、恢复预算、焦点所有权、弹层和隐藏控制。Flutter analyze 无问题，Flutter MCP analyze 返回 No errors。显式关闭后不再在 Provider 销毁时追加重复数据库写入。

附加的 Windows 调试运行能完成 Flutter MCP 热重启，但产品 Roaming AppData 子目录创建被操作系统拒绝，不能把桌面运行算作通过，见 [windows-debug.json](m5-evidence/windows-debug.json)。仅对调试进程设置了可写的任务临时目录，没有修改系统 ACL；本机自动验收指单元／Widget 和静态分析，主目标仍为 Android TV。

真实游客资源探测见 [playback-contracts.json](m5-evidence/playback-contracts.json)：公开 45 分钟样本可提供 360P／480P AVC、多条 AAC 及成对备用资源；不据此推定登录会员能力或所有视频均有两个档位。

原生 profile 自动流程已通过，见 [native-profile.json](m5-evidence/native-profile.json)。API 36 x86_64 TV 模拟器、显式游客、独立验证包／数据库，单调计时 1800 秒，媒体从 0 推进至 1799.04 秒。480P AVC 与 AAC 切换保持暂停，换清晰度、音轨、正常续播与本地 HTTP 403 恢复误差均为 0 ms；403 只重新解析一次。另一次 HTTP 503 测试使用服务实际提供的成对备用资源，1 次备用尝试恢复，没有额外解析。

10 次 Home 和 10 次实际屏幕休眠全部通过，最大恢复位置误差 40 ms；后台引擎为 0，返回没有自动播放。27 次引擎创建全部释放，最大同时存活数为 1，长时及销毁日志未见 Flutter 异常。记录到 4009 个 Flutter UI 帧，build P95 0.851 ms、raster P95 7.086 ms；[播放期间只读截屏](m5-evidence/soak-visible-frame.png)确认可见画面。

验收使用 `MAMBA_VALIDATION_APP=true` 构建开关和独立 `app.mamba.mambatv.validation`，默认产品仍为 `app.mamba.mambatv`。MainActivity 使用完整类名以支持独立应用 ID。当前 Flutter SDK 的 drive 停止逻辑仍可能按主清单 ID 卸载，因此必须同时添加 `--keep-app-running --no-uninstall-first`；结束后显式 force-stop 验证包。历史 M0–M4 命令也应补上这些选项，不能声称独立数据库会保留产品安装数据。

长时诊断曾出现 1.0 倍速下 120 秒推进 216.56 秒的异常，原短流程断言虽通过，但该记录明确拒收，见 [音频时钟诊断](m5-evidence/native-audio-clock-diagnostic.json)。重启同一模拟器后，同样的 OpenSL ES 配置在 120 秒推进 119.76 秒，见 [短复测](m5-evidence/native-short-profile.json)。当前长流程额外每分钟检查时间轴与单调计时偏差小于 10 秒；没有用更长视频掩盖此异常，也没有改全局音频配置。短复测编译早于重复写入修复，其销毁日志出现数据库已关闭异常；最终长流程与产品调试须单独检查。

模拟器 profile 的 Flutter build／raster P95 只描述该环境中记录到的 UI 帧，原生视频独立渲染，不代表硬件解码帧率、真实电视性能或人工音画同步。物理遥控器断开、扬声器听感与 ARM 机型仍需物理设备补验。

## 产品包与界面

默认主包通过 Flutter MCP 热重启、真实搜索／详情／播放、原生 D-pad 打开清晰度并在暂停时切到 480P、退出和最终运行时错误检查。初次热重启后过早操作曾遇到 Driver 扩展未注册和自动化超时／guard 冲突；扩展就绪后重新执行全链路，最终运行时错误集合为空。[控制条](m5-evidence/player-controls.png)和[清晰度菜单](m5-evidence/quality-menu.png)为实际模拟器截图。

[强杀记录](m5-evidence/force-kill.json)：未先暂停／退出以触发保存，界面 00:42 时强杀，已有持久进度 41760 ms；读取与终止耗时 175 ms，计入 2 秒显示取整／渲染余量，损失上界 2415 ms，低于 5 秒加 1 秒调度余量。[冷启动](m5-evidence/cold-resume.json)后搜索历史恢复，立即暂停并重复读取稳定显示 00:41，对应整秒区间内与保存点最大差 760 ms；该 UI 结果有取整限制，毫秒级正常续播另由原生集成覆盖。

默认 `lib/main.dart` Debug APK 的包名、TV 入口、ABI、大小和 SHA256 见 [debug-apk.json](m5-evidence/debug-apk.json)。仅在 API 36 x86_64 实际运行；包含 ARM 库不代表已验证 ARM，Debug 签名不代表正式发布签名。汇总见 [verification.json](m5-evidence/verification.json)。

存活计数指未关闭的播放器租约，不据此推断完整进程内存或所有底层延迟资源均立即回收。原始设备时间保留；连续时长由单调 Stopwatch 测量，不用设备墙钟推算 30 分钟。

## 重现

```powershell
flutter pub get
dart run build_runner build
flutter test
flutter analyze
dart run tool/m5_contract_probe.dart
flutter drive --profile --keep-app-running --no-uninstall-first --dart-define=MAMBA_VALIDATION_APP=true --dart-define=M5_SOAK_MINUTES=30 --dart-define=M5_HOST_CYCLES=true --driver=test_driver/m5_integration_test.dart --target=integration_test/m5_playback_flow_test.dart -d emulator-5554 *> .m0/m5-native-profile.log
flutter build apk --debug
```

原生命令启动后，在同一项目的第二个终端运行 `pwsh -File tool/m5_host_cycles.ps1 -Device emulator-5554 -AdbPath D:\Software\ASSDK\platform-tools\adb.exe`；按实际 SDK／设备修改参数，先创建 `.m0` 日志目录。

完成后按验证包 ID 停止：`adb -s emulator-5554 shell am force-stop app.mamba.mambatv.validation`。测试包可留作复测，不清理产品数据。

开启 M5_HOST_CYCLES 需要主机配合真实 Home／Sleep／Wake：辅助脚本按日志 WAIT／PAUSED／DONE 标记操作指定设备，休眠停留至少 2 秒再唤醒。屏幕关闭会停 vsync，所以休眠检查以捕获的生命周期事件和唤醒后的无自动播放为准。没有主机配合时去掉 M5_HOST_CYCLES，仅运行播放／恢复／长时部分；不能将跳过的循环写成已验收。

`M5_SOAK_MINUTES=0` 只用于诊断短路径，不能用作 30 分钟证据。正式签名、发布及后续个人列表仍分别属于 M7／M6。
