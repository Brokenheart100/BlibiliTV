# ADR 0001：M0 工具链、接口体系与播放器候选

日期：2026-10-24。状态：部分验证通过，播放与账号确认结果见 M0 验收记录。

## 决策

- 首发 Android TV，applicationId／namespace 为 `app.mamba.mambatv`。
- 构建最低 Android API 为 24：本机 Flutter Gradle 扩展和实际安装的 flutter_secure_storage Android 工程都要求 24。当前运行目标为 API 36 模拟器，不因此宣称 API 24 真机已通过。
- 使用现有 Flutter 3.47.5（框架提交 `6a19cca564`）、Dart 3.13.4；记录 SDK 自定义频道，不切换用户全局 SDK。
- 使用 Flutter + Riverpod + Freezed + MVVM + 整洁架构；M0 的 `lib/m0` 是隔离验证代码，M1 再将已验证能力整理为正式 Repository、端口和应用装配。
- 对全部新增直接依赖固定具体版本，并提交 pubspec.lock。Riverpod runtime、annotation 和 generator 的主版本不同不等于冲突，兼容性以依赖解析、实际生成与编译为依据。
- 选择 Web 扫码 Cookie + Web/WBI 内容接口作为首个协议体系。TV 界面并不强制使用 TV access_token 协议；不引入上游 app 签名密钥或混用凭据。
- media_kit 官方发布版本作为唯一首选验证引擎，不引入 PiliPlus 的 Git overrides；备选 Media3 尚未接入。
- M0 Android 采用该库已有的 `vo=mediacodec_embed`／`hwdec=mediacodec` 配置。默认 gpu 输出在当前 API 36 模拟器发生 EGL 黑屏，换为该输出后确认画面可见并通过暂停／seek。它使用虚拟 MediaCodec，不据此确定真实电视上的硬解／回退策略。
- M0 账号凭据只保留于内存。安全存储使用合成非秘密数据做独立读写验证；正式账号持久化、刷新和启动恢复仍属于 M3。
- 本机首次 Android 构建出现 Kotlin 2.4 跨 C: 插件缓存与 D: 项目路径的增量缓存错误。在本项目 gradle.properties 配置 `kotlin.incremental=false`；保留正常编译校验，不更改全局 PUB_CACHE。代价是 Kotlin 全量编译耗时增加，可由后续同盘环境验证后重新启用。
- 用户已选择先做本机和 TV 模拟器验证。物理电视硬解、实际扬声器声音、遥控器兼容性与休眠行为延后到真机阶段，不阻碍当前范围继续验证。

## 上游固定版本与复用边界

PiliPlus：[`058794483080f5bf3d760e005118c0bd4698c51b`](https://github.com/bggRGjQaUbCoE/PiliPlus/tree/058794483080f5bf3d760e005118c0bd4698c51b)，提交时间 2026-10-24 02:05:23 UTC。

参考内容包括 api.dart、video.dart、wbi_sign.dart 的端点、字段和协议行为，未复制上游项目、页面或账号系统。协议适配实现保留来源索引；上游 LICENSE 原文为 GNU GPL version 3，正式引入文件或资源时继续记录其来源和适用许可证。

Web 扫码资料参考 API-collect 镜像固定提交 [`271b123a083698bf576101c21f534b3418768a43`](https://github.com/replace5/bilibili-API-collect-mirror/tree/271b123a083698bf576101c21f534b3418768a43)。镜像属于社区协议资料，不作为官方稳定性承诺；本地直接请求 B 站服务得到的结果另存为脱敏证据。

## 已证实与仍待验证

- 依赖解析成功；Riverpod、Freezed、JSON 序列化和 Drift 生成器已共同执行。
- Windows Dart CLI 已验证游客热门、搜索、详情、DASH 资源和二维码申请／未扫描状态；见 [接口证据](../m0-evidence/guest-api.json)。
- 已配置 Android TV Manifest、最低 API、联网权限、横屏和临时 banner；安装与运行验收单独记录。
- [模拟器音视频证据](../m0-evidence/tv-playback.json) 与 [可见截图](../m0-evidence/tv-playback-embed.png) 已确认；[扩展契约](../m0-evidence/extended-contracts.json) 验证了多 P 资源与画质／有效期元数据。
- 正式签名、ARM 真机、长期播放、账号刷新、受限清晰度等尚不在当前验证结论内。

## 资料

- [Riverpod Provider 与状态类型](https://riverpod.dev/docs/concepts2/providers)
- [Riverpod 自动重试](https://riverpod.dev/docs/concepts2/retry)：根 ProviderScope 关闭构建失败重试，避免与网络层叠加。
- [Freezed 官方包说明](https://pub.dev/packages/freezed)
- [media_kit 官方包说明](https://pub.dev/packages/media_kit)
- [AGP 9.1 兼容要求](https://developer.android.com/build/releases/agp-9-1-0-release-notes)
- [Kotlin 编译与缓存配置](https://kotlinlang.org/docs/gradle-compilation-and-caches.html)
