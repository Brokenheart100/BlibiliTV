# M1：架构骨架与 TV 基础验收

日期：2026-10-24。范围：本机自动测试、API 36 TV 模拟器；按用户选择，不发起账号登录、不要求物理电视。本阶段交付演示数据驱动的可遥控应用壳，真实内容与音视频播放流程在 M2 接入。

## 已交付

| 层 | 实现与边界 |
| --- | --- |
| `lib/app` | ProviderScope、应用启动、Repository 构造与 Provider 图、go_router、前后台生命周期桥接；根容器关闭 Provider 构建失败自动重试 |
| `lib/core`、`lib/domain` | 纯 Dart Result/Failure、CancellationSignal、PageSlice、Freezed Session/Video/Settings 与仓储接口；不依赖 Flutter、Riverpod、Dio 或 Drift |
| `lib/data` | 明确命名的 FakeCatalogRepository、游客内存会话、LocalSettingsRepository、SharedPreferencesAsync 与安全存储适配器、Drift v1、Dio 超时与日志白名单 |
| `lib/ui` | TV 深色主题、焦点按钮/卡片/懒加载网格、空/错/加载状态、封闭弹窗焦点；Riverpod 生成的 AsyncNotifier/Notifier + Freezed 页面状态 |

默认 `lib/main.dart` 已替换计数器模板。`lib/m0_main.dart` 和 `lib/m0/` 保留为独立技术探测入口，不把探测代码混入正式 Repository。

已实现发现、搜索、我的、设置、详情、登录说明、播放器预览路由。发现与搜索使用 72 条明确标注“演示”的合成内容；游客“我的”提供可操作空状态。登录说明不会获取二维码，播放器预览不会创建媒体引擎。

设置页实际保存“减少动态效果”“记住播放位置”偏好；后者目前只保存开关，实际进度写入和续播属于 M2/M5。简单设置作为一份 JSON 写入偏好存储，写入失败保留已提交状态。凭据适配器不接入 UI，也不将凭据写入偏好。

## 状态与生命周期约定

- 应用级网络、数据库、会话、路由、设置使用 keepAlive，启动显式订阅；销毁时关闭 client、数据库、流和 router。
- 内容 Provider 使用 `section + pageId + ownerKey + query` 参数。相同参数共享，不同页面、账号、关键词隔离；详情以路由实例 pageKey 加内容 ID/ownerKey 定位。
- 初次加载/失败使用 AsyncValue；刷新、加载更多、局部失败留在 CatalogState；设置保存有独立 saving/message，避免整页闪回 loading。
- 刷新取消旧分页，通过取消信号与请求代次丢弃迟到结果；Provider 依赖失效或销毁取消在途任务。IndexedStack 隐藏分支保留数据和焦点，但暂停任务；应用退后台不因迟到结果自动重启请求，回前台再恢复。
- FocusNode、滚动控制器和焦点书签仅属于 UI。书签按账号/页面/分区/查询分隔，存稳定 ID、索引回退和滚动位置；网格只为已挂载项持有节点，离屏目标先滚动再取节点。
- Data/Domain 通过构造函数接收依赖，不接收 Ref。尚无需要跨仓储编排的业务，M1 不创建空 UseCase 层；后续按实际流程添加。

## 验证结果

本机 `flutter test` 共 21 项通过：M0 回归 5 项，M1 数据/基础设施 4 项、Catalog ViewModel 4 项、Settings ViewModel 1 项、TV Widget 7 项。

覆盖了 Provider 参数隔离、依赖失效、自动释放、过期响应、设置失败回退与重试、Drift schema v1、账号进度主键隔离、日志不泄露 URL/Cookie/Authorization/响应载荷，以及遥控器网格、分页、搜索、空/错状态、弹窗、详情返回和后台取消。

代码生成、Flutter MCP 静态分析与格式检查通过。`test/generated_migrations/` 为 Drift 生成的 schema 辅助代码，单独排除其生成的 raw-type 诊断，手写代码仍使用 strict casts/inference/raw-types 检查。

原生集成测试入口为 `integration_test/m1_shell_test.dart`，Host Driver 独立写入 [native-shell.json](m1-evidence/native-shell.json)，不会覆盖 M0 的媒体证据。它验证真实启动、SQLite schemaVersion=1、方向键进入详情与焦点恢复、偏好实际读写，并恢复测试前设置。

当前设备 `emulator-5554`，Android 16/API 36、x86_64、1920×1080、density 320（逻辑 960×540）。调试构建不能用于帧率或启动性能结论。

默认 `lib/main.dart` 的调试 APK 已独立构建、安装并通过 LEANBACK_LAUNCHER 冷启动。包信息、大小和 SHA-256 见 [debug-apk.json](m1-evidence/debug-apk.json)，产物为 `build/app/outputs/flutter-apk/app-debug.apk`；这是包含多 ABI 和调试资源的开发包，发布体积优化与正式签名留到 M7。

ADB 实际注入方向/确认/Android 返回键，复核启动器进入、卡片进入详情、单次返回恢复焦点、设置和弹窗；截图均经查看：

- [TV 启动器中的 MambaTV](m1-evidence/launcher.png)
- [发现页与卡片焦点](m1-evidence/home.png)
- [详情页默认播放预览焦点](m1-evidence/detail.png)
- [Android 单次返回恢复原卡片](m1-evidence/back-restored.png)
- [设置页](m1-evidence/settings.png)
- [根页退出确认](m1-evidence/exit-dialog.png)

Flutter MCP 已连接应用 DTD，执行热重载、Driver 健康检查与运行错误检查。开发入口 `tool/m1_app.dart` 才启用 Driver，默认产品入口不启用。

## 本次修复

1. 新建导航分支会自动请求分支 FocusScope；选中分支后将焦点保留在对应导航项，右键再显式进入内容。搜索进入时定位输入框，提交后定位搜索按钮。
2. 详情异步数据插入时，autofocus 无法可靠覆盖已聚焦的返回按钮；主操作挂载后显式请求一次焦点。
3. Android 同时发送 goBack 键事件和系统 popRoute 回调。最初两条路径都触发路由回退，导致详情返回后又弹退出框；去除 goBack 快捷键绑定，Android 使用系统回退，Escape 保留键盘回退。回归测试组合发送逻辑返回键与平台回调，实际 ADB 单次返回也复核通过。
4. 页面请求在后台完成取消后，不能仅依据分支 visible 立即 resume；恢复同时检查前台状态，补充后台请求计数回归。
5. TV 输入法显示时保持应用壳尺寸，避免整个侧栏因键盘 inset 缩小溢出；完整遥控器输入法交互和候选词在 M4 继续验收。

一次 Driver 等待详情按钮超时，是连续注入按键尚未进入目标页导致的等待目标错误；后续按页面状态等待后重新执行。该工具超时与业务运行异常分开记录，最终运行错误检查无异常。

## 数据库与后续迁移

v1 建立 `watch_progress_rows(owner_key, video_id, part_id)` 和 `search_entries(owner_key, query)`，已导出 `test/drift_schemas/drift_schema_v1.json`，测试验证导出 schema 与实际数据库一致。当前只有 v1，尚无跨版本升级可测试；新增 v2 时必须补迁移实现和 v1→v2 数据保持测试，不修改既有 v1 快照。

```powershell
dart run drift_dev schema dump lib/data/services/local/app_database.dart test/drift_schemas
dart run drift_dev schema generate test/drift_schemas test/generated_migrations
```

日志仅输出方法白名单、状态码、类别和耗时；不记录请求地址/查询、请求头、请求体、响应体。M1 没有增加实际 B 站业务请求、网络自动重试或播放恢复策略。

## 重现

设备 ID 以 `flutter devices` 为准：

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter drive --driver=test_driver/m1_integration_test.dart --target=integration_test/m1_shell_test.dart -d emulator-5554
flutter build apk --debug
flutter run -d emulator-5554
```

MCP 调试可将最后一条命令改成 `flutter run --machine -d emulator-5554 --target tool/m1_app.dart`，再发现并连接对应 DTD。

## 未覆盖的验收

M0 账号确认仍按用户选择暂缓；M1 完成不意味着账号协议验收通过。M2 接入游客真实内容到播放流程；M3 接入真实会话恢复；M4 完善内容/输入法；M5 接入完整续播与播放器。

物理 TV/ARM、低内存和长时运行、正式 banner/应用图标、release 签名与发布尚未验收。当前 banner 为临时矢量图；M1 不声称已经可以日常观看 B 站。
