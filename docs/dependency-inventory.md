# MambaTV 依赖清单（更新至 M8）

日期：2026-10-28。下表来自实际 pubspec.lock。Pub 托管直接依赖固定精确版本；弹幕使用官方托管的 canvas_danmaku 0.3.3，不修改全局 Pub 缓存，也不使用 dependency_overrides 或浮动 Git 分支。

| 依赖 | 已解析版本 | 范围 |
| --- | --- | --- |
| audio_session | 0.2.4 | direct main |
| better_player | 1.29.0 | direct main；Android Media3 适配 |
| build_runner | 2.16.2 | direct dev |
| cached_network_image | 4.0.5 | direct main |
| canvas_danmaku | 0.3.3 | direct main；pub.dev 官方托管版 |
| crypto | 3.0.7 | direct main |
| cupertino_icons | 2.0.0 | direct main；Better Player 的版本要求 |
| dio | 5.11.1 | direct main |
| dio_cache_interceptor | 4.0.7 | direct main |
| drift | 2.35.3 | direct main |
| drift_dev | 2.35.2 | direct dev |
| drift_flutter | 0.3.1 | direct main |
| fixnum | 1.1.1 | direct main |
| flutter | 0.0.0 | direct main |
| flutter_cache_manager | 3.4.5 | direct main |
| flutter_driver | 0.0.0 | direct dev |
| flutter_lints | 6.0.0 | direct dev |
| flutter_riverpod | 3.4.3 | direct main |
| flutter_secure_storage | 11.2.0 | direct main |
| flutter_test | 0.0.0 | direct dev |
| freezed | 4.0.3 | direct dev |
| freezed_annotation | 3.1.0 | direct main |
| go_router | 18.1.1 | direct main |
| integration_test | 0.0.0 | direct dev |
| json_annotation | 4.12.0 | direct main |
| json_serializable | 6.15.2 | direct dev |
| media_kit | 1.2.6 | direct main |
| media_kit_libs_video | 1.0.7 | direct main |
| media_kit_video | 2.0.1 | direct main |
| package_info_plus | 10.2.2 | direct main |
| pointycastle | 4.0.0 | direct main |
| pretty_qr_code | 3.6.0 | direct main |
| protobuf | 6.1.0 | direct main |
| protoc_plugin | 25.0.0 | direct dev |
| riverpod_annotation | 4.0.7 | direct main |
| riverpod_generator | 4.0.9 | direct dev |
| shared_preferences | 2.5.6 | direct main |
| talker | 5.2.0 | direct main |
| talker_flutter | 5.2.0 | direct main；TV 日志界面与 Flutter 输出 |
| talker_riverpod_logger | 5.2.0 | direct main；经过脱敏的生命周期观察器 |
| xml | 7.1.0 | direct main；内存 DASH MPD 构建 |

2026-10-27：Better Player 解析 Android 插件 1.9.0／Media3 1.11.0；保留 media_kit 作为回退和 Windows 后端。cupertino_icons 按 Better Player 要求升到 2.0.0；xml 原已为传递依赖，本次提升为直接依赖。192 项锁定依赖与 148 项运行依赖已重新汇集许可；AndroidX Media3 1.11.0 的 Apache 2.0 原文加入应用原生许可。试用与验收边界见 [Better Player 记录](better-player-trial.md)。

## 原生组件与许可证记录

2026-10-28：接入 Talker Flutter 与 Riverpod 扩展后，当前锁定依赖共 202 项，运行依赖 158 项。包含 talker_flutter 引入的分享等传递依赖，许可清单已从实际包 LICENSE 重新生成；未添加 talker_dio_logger，网络元数据仍通过既有脱敏拦截器写入共享 Talker。见 [诊断日志](diagnostics-logging.md)。

- media_kit_libs_video 1.0.7 实际解析 Android 原生包 media_kit_libs_android_video 1.3.8、Windows 包 1.0.11；本次 Android 构建下载 libmpv-android-video-build v1.1.7 的 ABI JAR。
- Flutter／Android 与 flutter_secure_storage 的本地源码要求最低 API 24，构建配置已显式固定。
- 本地包 LICENSE 检查：Riverpod、Freezed、Drift、media_kit Dart 包为 MIT；json_serializable 为 Dart 项目的 BSD 风格许可；flutter_secure_storage 为 BSD 3-Clause。
- Dart 包许可证不能替代 FFmpeg／libmpv 等原生二进制的许可清单；正式发布前仍需完整收集 NOTICE 与原生组件来源。
- PiliPlus 仅作协议参考，固定提交和许可证记录见 ADR 0001；未引入其 Git 定制依赖。

M0 只验证实际使用到的能力。路由、Drift 迁移、图片缓存和设置等库虽然已解析，尚不表示对应业务已实现或完成运行验收。

M3 新增 PointyCastle 4.0.0，用于协议要求的 RSA-OAEP SHA-256 公钥加密，不存放私钥。已检查本地包的实际构造器，并通过 Node/OpenSSL 独立解密合成密文验证互操作；见 [crypto-interoperability.json](m3-evidence/crypto-interoperability.json)。真实账号续期仍需服务端实际要求刷新时补验。

M3 后续日志更新：引入 Talker 5.1.21（同时解析 talker_logger 5.1.21、ansicolor 2.0.3），通过 Riverpod 应用级 Provider 注入。继续使用既有 SafeLoggingInterceptor 的字段白名单；调试模式输出控制台、最多保留 200 条内存历史，profile/release 默认关闭。参见 [日志约定](logging.md) 和 [Talker 包文档](https://pub.dev/packages/talker/versions/5.1.21)。

M4 将已存在的传递依赖 flutter_cache_manager 3.4.5 提升为精确直接依赖，使用实际 ImageCacheManager／Config API 配置封面缩图和文件数上限；没有升级 cached_network_image 4.0.5 或原生播放库。

2026-10-25 HTTP 缓存补充：精确直接依赖 `dio_cache_interceptor 4.0.7`，新增传递依赖 `http_cache_core 1.1.4`，现有锁定包未升级。仅使用有容量限制的内存 Store；没有增加持久化缓存插件。策略与实际源码核对见 [ADR 0005](adr/0005-scoped-http-cache.md)。

M5 新增精确直接依赖 `audio_session 0.2.4`（MIT），使用现有 rxdart 依赖，没有升级原生 media_kit 系列。实际读取源码确认配置、焦点、中断及耳机事件 API；Android 设备回归与边界见 [M5 验收](m5-validation.md)，平台策略见 [ADR 0006](adr/0006-playback-controls-and-recovery.md)。


M8 新增 protobuf 6.1.0、fixnum 1.1.1、开发期 protoc_plugin 25.0.0 与固定官方 protoc 36.2。弹幕使用官方 canvas_danmaku 0.3.3；先前 30／15 fps 本地补丁未通过模拟器持续负载，已退出应用依赖。`third_party/canvas_danmaku/` 与既有压力报告只作为该试验的历史证据，不进入本次构建。应用仍有 40／20／10 条密度保护和持续超预算自动暂停；正式性能结论以 M8 验收为准。运行期声明与完整许可见 release/dependencies.json 及随包 notices。
