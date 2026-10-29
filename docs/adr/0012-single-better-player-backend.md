# ADR 0012：统一 Better Player，移除 media_kit

日期：2026-10-29。状态：实施。依据：用户明确要求“那就移除”。

Android TV 已经默认采用 Better Player／Media3；并存的旧适配器、入口初始化和原生库增加依赖与维护成本。本次删除 media_kit、media_kit_video、media_kit_libs_video 和不再可达的传递包；删除 MAMBA_PLAYBACK_ENGINE 构建开关，应用装配统一 BetterPlayerEngine／BetterPlayerSurface。

保留 Domain 的 PlaybackEngine、Riverpod、Freezed、MVVM／整洁架构、播放器租约、TV 操作层、DASH 元数据与回环 MPD、真实缓冲范围和原生时钟采样。原生错误分类抽为独立 Data 服务，不依赖旧适配器。M0 复用正式 DASH 解析和新引擎。

M2–M7 的资源追踪、播放流程、缓冲与跳转集成测试迁移到当前后端；M8／M9 移除旧初始化。删除 OpenSL ES／AudioTrack 参数对照、Windows 直接 mpv 试听和旧 mpv JSON 缓冲解析及其 3 项单元测试。这些能力已不属于当前后端；不在新测试中伪造 audio PTS、采样率或声道信息。

历史报告保留，不改写历史后端结论；新报告另写 `docs/media-backend-evidence/`。Windows 由 Better Player 的联邦插件负责；该插件仍需外部 libmpv DLL，未在本轮下载或分发，不能将移除 Dart 包等同于 Windows 底层也改用 Media3。

验证范围和结果见 [清理记录](../media-backend-cleanup.md)。本轮不增加新播放器依赖，不提交、推送或发布。
