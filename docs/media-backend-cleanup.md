# 移除 media_kit，统一 Better Player

日期：2026-10-29。用户已确认移除；工作区改动，不提交、推送或发布。

## 当前装配

应用、M0 验证入口和现有辅助入口统一 Better Player 1.29.0。Android 插件 1.9.0 使用 Media3 1.11.0。没有 media_kit 初始化、旧适配器或 MAMBA_PLAYBACK_ENGINE 回退开关；每次播放仍由现有 PlaybackCoordinator 持有一个引擎。UI、弹幕、字幕、Riverpod／Freezed／MVVM 与 Domain 播放端口保持不变。

独立音视频仍通过真实 DASH 元数据组成 MPD，由一个原生播放器统一调度；不改播放权限、Cookie、CDN 请求头或账号隔离。错误分类移动到 `native_playback_failure.dart`；真实缓冲条和跳转就绪逻辑继续来自 Better Player 原生数据。

删除三个直接 media_kit 依赖及不再可达的传递包，更新 lockfile、Windows 生成注册文件、依赖许可清单和 Android Media3 原生许可。历史报告不删除；旧试用文档已注明回退命令失效，当前架构与计划同步更新。

## 测试与工具

M0 保留接口、播放、暂停、跳转和安全存储验证，复用正式 DASH 映射。M2–M7 的引擎计数／释放和业务流程继续保留，缓冲／跳转测试迁至 Better Player；M8／M9 删除旧初始化。原生 API 不提供的音频 PTS、采样率、音频输出和速度校正数据记为不可用，不能用视频位置推进代替人工音画同步或杂音验收。

移除专用于旧 mpv 的 OpenSL ES／AudioTrack 参数试听测试及其驱动、Windows 直接 mpv 试听脚本，以及旧缓冲 JSON 解析器和 3 项单元测试。因此原 307 项本机测试变为 **304 项**，保留的测试全部通过。

新证据写入 `docs/media-backend-evidence/`，不覆盖旧后端的 native-validation 报告。本机日志与 APK 清单在 `.m0/media-kit-removal/`。

## 平台与验收边界

Android TV 使用 Media3，移除旧 Dart 包不影响这一选择。Windows 现在也走 Better Player 的联邦插件，但该插件本身仍使用 libmpv，且 pub 包不附 mpv DLL；本轮没有下载或分发 Windows 媒体 DLL，Windows 原生播放不在本轮已通过范围。未来 Windows 发行需补 DLL、来源许可及实际播放验证。

本机 304 项回归通过。API 36 x86_64 TV 模拟器、游客、隔离包 `app.mamba.mambatv.validation` 的三套原生专项通过：实际 DASH 播放／缓冲条／暂停／倍速与 9 次跳转采样、真实缓冲范围与前后 seek 清空重建、13 次原生位置跳转（含暂停及 1.5 倍速）。这不是新的长时或人工音画验收。

静态分析零问题、295 文件格式无变化、代码生成和 13 项流水线守卫通过，依赖许可清单与 lockfile 一致。正式应用入口 `lib/main.dart` 的 ARM32／ARM64 Debug APK 均构建成功，产物均未包含旧 mpv／media_kit 原生库；这里只验证构建，未安装到物理 ARM 设备。迁移后的 M0 与 M2–M7 整套原生流程尚未重新执行，历史报告不作为当前后端的新增通过证据。

当前依赖图与平台插件注册不含 media_kit；新模拟器 APK 中没有 libmpv／media_kit 原生库。旧基线包包含三个 ABI 的 libmpv.so，但两次包的入口／ABI 选择不同，不以整体包大小差异宣称精确节省量。产物与最终检查见 [结构化报告](media-backend-evidence/cleanup-validation.json)。

无新版本、签名、远端 CI 或发布操作；物理 ARM TV、人工杂音／口型、M8 性能和长时播放验收继续沿用原有边界。
