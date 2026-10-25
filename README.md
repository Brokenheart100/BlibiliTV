# MambaTV

面向 Android TV／安卓电视盒子的第三方 B 站客户端，采用 Flutter + Riverpod + Freezed + MVVM + 整洁架构。

M4 已完成首页推荐／热门、中文搜索与本地历史、去重分页、详情续播、UP 信息、长分 P 和相关视频，延续深色 iOS 风格。扫码登录与账号隔离沿用 M3；M5 已实现完整播放器控制与受限恢复。M0 探测入口独立保留。

M5 播放器控制与受限恢复已实现：画质／AAC 音轨、倍速／音量、选集／连播、按键优先级和焦点／后台恢复。152 项本机测试、TV 模拟器 30 分钟连续播放及各 10 次 Home／休眠循环通过；人工音画同步与物理 TV 验证待补充，见 [M5 验收](docs/m5-validation.md)。

- [设计原则与架构](docs/tv-bilibili-architecture.md)
- [详细开发计划与验收标准](docs/development-plan.md)
- [M0 验收记录与运行方式](docs/m0-validation.md)
- [M1 验收记录与证据](docs/m1-validation.md)
- [M2 游客播放与 iOS 风格验收](docs/m2-validation.md)
- [M3 登录、会话与账号隔离验收](docs/m3-validation.md)
- [M4 内容发现、中文搜索与分 P 验收](docs/m4-validation.md)
- [M5 播放控制、恢复与长时验收](docs/m5-validation.md)
- [Talker 日志约定](docs/logging.md)
- [CI/CD、签名与标签发布](docs/ci-cd.md)

## CI/CD

GitHub Actions 在 PR／推送 `master` 时检查工作流、依赖锁定、生成代码、格式、分析、测试，并构建三个 ABI 的 Debug APK。推送与 `pubspec.yaml` 一致的 `v*` tag 后，完整重跑 CI、使用正式密钥签名、验证 APK／SHA256 并发布 GitHub Release。

应用和工作流已推送至 `Brokenheart100/BlibiliTV` 并通过 GitHub 托管 CI，见[验收记录](docs/ci-cd-validation.json)。正式发布前仍需配置文档中的四项签名 Secrets。当前 `1.0.0+1` 对应 `v1.0.0`；缺少密钥时 Release 会失败，Debug／profile 不受影响。本次没有创建 tag 或发布 Release，详见 [CI/CD 说明](docs/ci-cd.md)。

## 运行

当前工具链：Flutter 3.47.5 / Dart 3.13.4（本机为自定义频道），Android 构建最低 API 24；运行验收为 API 36 x86_64 TV 模拟器。物理电视与 ARM 仍待验证。

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter devices
flutter run -d emulator-5554
```

设备 ID 应替换为实际结果。方向键移动，确认键进入，返回键退出当前页；根页返回会先弹出确认框。搜索完成后从搜索按钮按左返回导航。

M1 原生壳测试使用 Fake 内容和真实本地基础设施，不访问 B 站或发起登录：

```powershell
flutter drive --keep-app-running --no-uninstall-first --dart-define=MAMBA_VALIDATION_APP=true --driver=test_driver/m1_integration_test.dart --target=integration_test/m1_shell_test.dart -d emulator-5554
```

M2 原生播放测试访问真实游客内容接口，使用独立验证数据库，包含续播与 20 次切换：

```powershell
flutter drive --keep-app-running --no-uninstall-first --dart-define=MAMBA_VALIDATION_APP=true --driver=test_driver/m2_integration_test.dart --target=integration_test/m2_playback_flow_test.dart -d emulator-5554
```

M3 原生测试使用合成账号、真实 Android 安全存储和独立验证键空间，不修改个人登录：

```powershell
flutter drive --keep-app-running --no-uninstall-first --dart-define=MAMBA_VALIDATION_APP=true --driver=test_driver/m3_integration_test.dart --target=integration_test/m3_auth_flow_test.dart -d emulator-5554
```

`lib/main.dart` 为产品入口；`tool/m4_app.dart` 额外启用开发期 Flutter Driver，供 Flutter MCP 检查。M4 原生完整流程及播放回归命令见验收记录；M0/M1/M2/M3 入口和重现步骤保留。

## 代码边界

- `app/`：Riverpod 装配、启动、路由和生命周期。
- `core/`、`domain/`：纯 Dart 结果类型、不可变业务模型、仓储接口。
- `data/`：Web/WBI 内容与资源、本地偏好/续播、安全存储、Drift v1、Dio 脱敏日志、media_kit 适配器；Fake 用于自动测试。
- `ui/`：TV 组件与焦点、页面、生成的 Riverpod ViewModel。

依赖以 `pubspec.lock` 为准；生成文件随源码保留。正式签名、发布和完整业务能力按开发计划继续推进。

2026-10-25 补充 HTTP 缓存：详情／相关视频最多 3 分钟、热门／搜索最多 1 分钟，按账号与会话代次隔离，主动刷新访问网络。见 [缓存决策](docs/adr/0005-scoped-http-cache.md) 与 [验收记录](docs/http-cache-validation.md)。显式游客探测可运行 `dart run tool/http_cache_probe.dart`，只记录计数和安全标记。
