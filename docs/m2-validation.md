# M2：真实游客播放流程与 iOS 风格验收

日期：2026-10-24。结论：本机与 TV 模拟器范围内通过，形成游客播放 alpha。账号仍按用户选择暂不登录，物理 TV/ARM 验收后补。

后续更新：真实账号流程已在 [M3](m3-validation.md) 补验，账号已按授权退出；下文保留 M2 的游客验收范围。

## 交付内容

默认入口已使用真实热门列表、视频搜索、详情、分 P 与播放器。流程为：发现/搜索 → 详情 → 确认播放/选集 → 真实画面与独立音轨 → 暂停/快进/继续 → 返回详情 → 原列表卡片和滚动位置。列表、详情和播放器均保留可操作的失败提示与返回路径。

界面采用深色 iOS 风格：渐变背景、浮动圆角侧栏、Cupertino 图标、半透明控制面板、白色焦点和蓝色点缀。保留 TV 的明确按键路径；没有将触摸手势作为必需操作。模糊局限于侧栏和控制面板，网格维持惰性构建与定尺寸图片缓存。

| 层 | 本阶段实现 |
| --- | --- |
| Domain | PlaybackSource/EngineSnapshot/WatchProgress、三个播放/进度端口、StartPlayback 跨仓储编排、PlaybackCoordinator 引擎生命周期串行化 |
| Data | Web/WBI 服务、json_serializable DTO 与 Mapper、真实 Catalog/Playback Repository、Drift 进度 Repository、media_kit 适配器 |
| App | 正式仓储 Provider、平台引擎与画面装配、真实播放器路由；默认入口初始化 MediaKit |
| UI | Riverpod 生成的 PlayerViewModel、Freezed PlayerState、原生画面宿主、分 P 入口、遥控器控制、错误重试、续播提示与显式重播 |

细节见 [ADR 0002](adr/0002-m2-playback-and-ios-style.md)。依赖保持原有锁定版本，没有新增运行时依赖或复制 PiliPlus 页面/播放器实现。

## 真实接口结果

正式仓储 CLI 探测 [guest-contracts.json](m2-evidence/guest-contracts.json)：热门 12 项、可继续分页；搜索过滤非 UGC 后 17 项、可继续分页；详情与独立音视频资源解析成功。样本返回 AVC、实际画质 ID 16、时长 82 秒。资源 URL 与签名只在内存使用，报告仅含公开 BVID/CID 和安全元数据。

搜索接口实际会混入 `type=ketang` 且 BVID/时长为空的课程推广项；在解析普通视频 DTO 前过滤，不把它当作 UGC，也不因此使整页加载失败。来源、请求约定与后续契约更新见 [接口契约](api-contracts.md)。

## 验证结果

- 全量 `flutter test` **35 项通过**，包含 M0/M1 回归与本阶段新增 14 项：DTO/仓储 4、有效进度存储 1、Player ViewModel 7、Player Widget 2。
- 代码生成通过；Flutter MCP 静态分析无诊断，执行了 DTD 连接、热重载、Driver 检查，最终运行错误检查无异常。
- Widget 覆盖 960×540 的播放/暂停/seek/返回、同一引擎画面绑定，以及 800×450 的网络失败、可聚焦重试与返回。
- ViewModel 覆盖显式打开、Provider 重建不重放、解析/打开中取消、迟到事件丢弃、20 次切换、有效续播、不写入初始零值、无权限显式重试、片尾重播。
- 仓储覆盖搜索混合类型过滤、时长/图片/标题映射、DASH 字段别名、AVC/AAC 选择、权限/不支持编码、Dio 在途取消，以及 SQLite 中无效进度不覆盖旧值。

原生集成报告：[native-playback.json](m2-evidence/native-playback.json)。设备为 `emulator-5554`，Android 16/API 36、x86_64、1920×1080、density 320（逻辑 960×540）。

| 原生验收项 | 结果 |
| --- | --- |
| 实际画面 | 640×360，等待首帧后验证，另经截图检查可见 |
| 独立音轨 | AAC 解码采样率 48000 Hz，播放时间持续推进 |
| 暂停 | 3133 ms；等待后位置保持在允许误差内 |
| 向前 seek | 从 3133 ms 到 13133 ms |
| SQLite 保存 | 13133 ms |
| 续播 | 请求起点与实际引擎位置均为 13133 ms |
| 连续切换 | 两个公开视频交替打开/关闭 20 次，每次验证画面与音轨就绪 |
| 引擎生命周期 | 合计创建 22、释放 22、同时存活最多 1、返回后存活 0 |
| 返回恢复 | 回到最初视频卡片，通过 |

集成测试使用独立的真实原生 SQLite 文件 `mambatv_m2_validation`，不会清空用户主数据库；仓储、WBI 请求、音视频源和原生播放器均为真实实现。重跑会清空该专用测试文件的进度表。默认应用数据库保持为 `mambatv`。

音轨参数与时间轴是已验证结果；扬声器听感、音画同步量测与物理电视的音频路由未在本次模拟器范围验收。20 次切换验证的是两个公开视频的反复切换，不表述为 20 个不同视频的兼容性覆盖。

## 界面证据

ADB 实际注入方向/确认/Android 返回，Flutter MCP 按页面状态等待并读取控制信息。另复核了暂停时从 00:47 跳到 00:57，以及修复后从保存的 00:27 实际续播。截图与自动化样本属于不同运行，精确测量以原生 JSON 为准。

- [iOS 风格真实热门列表](m2-evidence/home.png)
- [真实视频详情与选集](m2-evidence/detail.png)
- [真实画面与玻璃控制条](m2-evidence/playing.png)
- [暂停/快进后的界面](m2-evidence/paused.png)
- [续播后的实际画面与位置](m2-evidence/resumed.png)
- [返回原卡片的焦点](m2-evidence/returned.png)

截图均经过查看，未做像素修改或使用静态画面替代实际播放。开发 Driver 只在 `tool/m2_app.dart` 启用，默认产品入口不启用。

## 发现与修复

1. 准备阶段过早 seek 会被媒体加载重置。改用 Media.start，并在首帧后检查/补定位；保存前等待续播位置确认。验收比较实际进度，避免 UI 提示正确但仍从零播放。
2. 原生 Surface 的迟到 widListener 会对已销毁 Player 再次 seek。适配器停止新回调、取消参数订阅，再借库内 Android 控制器的锁排空旧回调后销毁；修复后完整切换验收通过。该处依赖 media_kit_video 2.0.1 内部入口，升级库需重验，未修改 pub cache 或引入 fork。
3. 异步引擎建立后显式发布 surfaceGeneration，保证画面宿主先挂载，再等待首帧，避免不可变状态相等而省略必要重建。
4. 位置更新单独由控制条 Consumer 监听，视频宿主和页面标题不会随每次进度更新重建。
5. Widget 测试中，流取消/排队存储需要交替推进真实异步任务和帧；仅调用 pumpAndSettle 不能证明退出已经完成。已使用有上限的状态等待。

早期 MCP 在尚未进入详情时等待详情/播放器控件曾超时，随后按实际页面状态重做；这些 Driver 等待错误不作为业务异常。最终运行错误检查为空。

## 重现

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
dart run tool/m2_probe.dart
flutter drive --driver=test_driver/m2_integration_test.dart --target=integration_test/m2_playback_flow_test.dart -d emulator-5554
flutter build apk --debug
flutter run -d emulator-5554
```

设备 ID 以 `flutter devices` 为准。M2 CLI 和原生集成会访问真实游客内容接口，不合并到普通离线测试。M1 原生壳测试现在显式覆盖 Fake Catalog，仍可独立重现而不访问真实内容接口。

默认 `lib/main.dart` 的调试 APK 已构建、安装并通过 LEANBACK_LAUNCHER 冷启动；产物为 `build/app/outputs/flutter-apk/app-debug.apk`，大小与 SHA-256 见 [debug-apk.json](m2-evidence/debug-apk.json)。该包含调试资源和多个 ABI，尚不是正式签名发布包。

## 下一阶段边界

账号确认与会话恢复留在 M3，完整发现/搜索筛选/输入法体验留在 M4，清晰度/倍速/换源/自动隐藏 OSD 与系统音频焦点恢复留在 M5，本地记录展示与个人列表留在 M6，物理 TV/ARM、长时稳定性、正式签名和发布留在 M7。

当前“记住播放位置”开关控制本地续播，已写入有效记录，但“我的”还未展示历史列表。API 24 是构建下限，不代表旧盒子已运行通过；无权限、弱网和不支持编码的恢复 UI 使用合成故障回归，未宣称穷尽真实服务的所有风控/权限场景。
