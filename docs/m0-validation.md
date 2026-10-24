# M0 技术验证与验收记录

日期：2026-10-24。状态：部分通过。用户选择本机 + TV 模拟器范围，并选择暂不登录；账号确认不是已完成项。

后续更新：用户已在 M3 授权并完成真实扫码、重启恢复、登录态播放及退出，见 [M3 验收记录](m3-validation.md)。下文保留 M0 当时的结果，不将后续验证冒充 M0 原始证据。

## 结论与证据

| 项目 | 结果 | 证据／限制 |
| --- | --- | --- |
| 本地 Git 基线 | 通过 | 初始提交 `466bece`；没有远端、没有推送 |
| 工具链与构建最低版本 | 已确认 | [toolchain.json](m0-evidence/toolchain.json)；Flutter 自定义频道已记录，API 24 为构建下限 |
| Riverpod + Freezed + JSON + Drift 生成兼容性 | 通过 | 依赖共同解析与 build_runner 实际生成；版本见 [依赖清单](dependency-inventory.md) |
| Flutter MCP 静态分析 | 通过 | 最后一次 analyze_files 无诊断；严格类型检查已启用 |
| 单元／Widget 测试 | 通过 | 5 项 M0 取消、生命周期和防重复回归 + 1 项原模板测试，共 6 项 |
| 游客真实接口 | 通过 | [guest-api.json](m0-evidence/guest-api.json)：热门、搜索、详情、H.264 + 独立音轨资源 |
| 扫码申请、等待、取消 | 通过 | CLI 得到 86101；MCP 实际点开二维码并取消；取消后 UI 显示停止 |
| 扫码后账号／列表／播放一致性 | 待验证 | 用户选择暂不登录，轮询已停止，无真实账号凭据存入文件 |
| Android debug 构建与安装 | 通过 | [APK 元数据与 SHA256](m0-evidence/debug-apk.json)；package=`app.mamba.mambatv`，minSdk=24，target/compileSdk=36，LEANBACK 启动入口；不是正式签名发布包 |
| TV 模拟器媒体状态与音轨 | 通过 | [tv-playback.json](m0-evidence/tv-playback.json)：最终配置首帧事件 530 ms、640×360、48 kHz 双声道、暂停、seek 至 10.433 秒 |
| 实际画面可见 | 通过 | [最终画面](m0-evidence/tv-playback-embed.png)：media_kit 的 mediacodec_embed + mediacodec 输出，宿主 GPU 模拟器；不是物理 TV 硬解 |
| 安全存储插件 | 通过 | 集成测试写／读／删合成非秘密标记，没有测试真实凭据持久化 |
| MCP 交互与热更新 | 通过 | get_health、按 Key 点击、读取状态、hot_reload、hot_restart；运行时异常读取无 Flutter 异常 |
| 多 P、画质与资源有效期元数据 | 通过 | [extended-contracts.json](m0-evidence/extended-contracts.json)：103 P 样本、不同 CID、P2 音视频资源、返回画质 ID 16/32、URL 观测 TTL 7199 秒 |
| 物理 TV、ARM、完整换画质／换 P、资源过期恢复 | 待验证 | 元数据通过不等于这些运行流程已经完成 |

## 已实施代码

- `lib/m0_main.dart`：独立 M0 应用入口，不替换正式 `lib/main.dart` 模板。
- `tool/m0_app.dart`：仅开发使用的 Flutter Driver 入口，供 MCP 操作。
- `lib/m0/domain/`：Freezed 不可变状态与内存资源类型，无 Flutter／Riverpod 依赖。
- `lib/m0/data/`：真实协议探测、WBI 签名、JSON DTO；无页面跳转逻辑。
- `lib/m0/ui/`：生成的 Riverpod ViewModel、二维码与媒体验证页面。
- `tool/m0_probe.dart`：可重复的真实游客／二维码未扫描探测，仅输出脱敏结果。
- `test/m0/`、`integration_test/m0_playback_test.dart`、`test_driver/integration_test.dart`：取消、释放、并发与真服务／原生媒体测试。
- Android：包名、联网权限、TV／非触屏声明、横屏、临时矢量 banner、连接变化处理和备份关闭。

M0 是为验证风险而编写的隔离代码。正式业务 Repository、可替换媒体端口、完整 TV 导航、会话恢复和数据库迁移在后续阶段整理，不能将临时探测器当作成品架构。

## 本次发现与修复

1. Kotlin 2.4 增量缓存跨 C: Pub 缓存与 D: 项目路径失败。按 [Kotlin 官方配置](https://kotlinlang.org/docs/gradle-compilation-and-caches.html) 在项目内关闭 Kotlin 增量编译后，Android 构建成功。
2. 仅在 Command 内 `ref.read` 自动释放的网络服务，会导致页面仍存在但网络请求被服务释放取消。ViewModel 在 build 中 `ref.watch` 服务依赖，补充在途请求期间服务保活／离页释放测试，并热重启验证。
3. 取消正在进行的游客请求后需要清除 busy，并丢弃迟到结果；已补充专门回归测试。
4. build_runner 2.16.2 已忽略旧的 `--delete-conflicting-outputs` 参数；当前流程改为 `dart run build_runner build`。
5. 默认 Android `vo=gpu` 在 SwiftShader 和 host GPU 模式都出现 EGL_BAD_ATTRIBUTE，首帧信号和时间轴正常但屏幕黑。使用已安装库提供的 `VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec')` 后画面可见，并重跑完整集成测试通过；原生解码器为模拟器 `c2.goldfish.h264.decoder`，不能称作真机硬解。配置集中在 M0 data 适配文件，后续真机仍需选择和验证回退策略。

保留 [初始黑屏](m0-evidence/tv-playback.png)、[host GPU 默认输出仍黑](m0-evidence/tv-playback-host.png) 与 [切换输出后的可见画面](m0-evidence/tv-playback-embed.png)，便于解释为什么不能只看播放器事件。

MCP 调试时曾等待一个已错过的“播放位置：5 秒”文本而超时，这是测试驱动等待错误，已与业务运行异常区分；实际进度读取和后续操作正常。

## 运行与重现

从项目根目录运行，设备 ID 以 `flutter devices` 的实时结果为准：

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
dart run tool/m0_probe.dart
dart run tool/m0_extended_probe.dart
flutter run -d emulator-5556 --target tool/m0_app.dart
```

TV 媒体与插件集成测试会访问真实 B 站游客接口，不作为普通离线 CI 测试：

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/m0_playback_test.dart -d emulator-5556
```

Host driver 将脱敏报告写入 `docs/m0-evidence/tv-playback.json`。CLI 报告覆盖写入 `guest-api.json`，重跑时样本可能改变；不要将新的样本与旧截图误当成同一次测量。

如果需要复现本次模拟器配置，使用已有 AVD `Mamba_TV_API36`，本次最终使用 `-gpu host`；M0 Android 画面输出采用 mediacodec_embed。确认 AVD 名称后再选择设备，不停止其他项目的模拟器。宿主 GPU 与虚拟 MediaCodec 的结果不能用于宣称 ARM 电视的解码性能。

## 剩余验收

- 用户主动扫码确认后，验证 nav.isLogin=true，并使用同一会话重跑列表／播放接口。
- 多 P 的第二段资源与可用画质元数据已验证；完整换 P／换画质、等待真实 URL 过期后的恢复放入 M2–M5；不承诺会员／地区权限外内容。
- 实际目标 TV／盒子的 ARM、硬解、音画同步与遥控器验收，按用户当前选择延后。
- 正式 release 签名、长期稳定性、完整 TV UX 与发布仍按 M1–M7 推进。

当前不宣布 M0 整体通过。按用户后续要求，独立推进不依赖账号确认的 M1 应用骨架，见 [M1 验收记录](m1-validation.md)；这不代表 M0 的账号项补验通过。
