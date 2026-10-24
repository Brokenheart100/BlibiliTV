# ADR 0002：M2 游客播放流程与 iOS 风格

日期：2026-10-24。状态：已实施；证据见 [M2 验收记录](../m2-validation.md)。

## 决策

- 保留 Flutter + Riverpod + Freezed + MVVM + 整洁架构。领域层新增 PlaybackEngine、PlaybackRepository、ProgressRepository、StartPlayback 与 PlaybackCoordinator；纯 Dart，不暴露播放器/Flutter 类型。
- 默认装配正式 BilibiliCatalogRepository/BilibiliPlaybackRepository，访问 M0 已验证的 Web/WBI 普通 UGC 接口。M0 探测器继续独立保留；Fake 通过 overrides 用于自动测试，不作为默认产品数据。
- M2 使用游客请求，不发起扫码，也不读取其他应用凭据。先验证 AVC + AAC DASH；从实际返回的 AVC 中选择较低带宽资源，画质标识取实际响应，不显示未取得的 HD 权限。
- 每轮打开使用新的原生引擎实例；全局协调器先等待上一实例释放，再创建下一实例。打开是页面进入/重试/重播事件触发的显式命令，Provider build 和重建仅产生 idle 状态。
- 同一引擎实例负责命令与 VideoController 渲染。平台装配同时提供引擎工厂和画面构建器，ViewModel 不引用 media_kit，页面不引用具体原生引擎实现。
- Android 沿用 M0 已验证的 mediacodec_embed/mediacodec 输出，其他平台使用库默认配置；没有引入 fork 或新播放依赖。
- 已安装的 media_kit_video 2.0.1 在快速销毁时存在 widListener 迟到 seek。适配器在销毁 Player 前移除新的 Surface 监听、取消视频参数订阅，并通过 Android 控制器自身的锁排空已排队回调。该兼容处理需要一个局部 `implementation_imports`，只留在适配器中；升级库时必须复核此 API 和原生切换回归。
- 续播通过 Media.start 设置加载起点；首帧后若位置未到达，再发送 seek。准备完成前的 seek 可能被原生加载过程重置，不能只验证 UI 的续播提示。恢复位置确认前，不写入新的低进度。
- 使用既有 Drift v1 进度表，每 5 秒及暂停/退出时提交有效进度；进度至少 1 秒且不超出时长，0 不覆盖旧值。接近片尾 10 秒内的记录重播时从头开始。切换前完成排队写入，再读取下一轮的续播点。
- 按用户要求采用深色 iOS 风格：系统字体回退、Cupertino 图标、大标题、连续圆角、半透明面板与细边框；白色焦点提供明显对比。毛玻璃仅用于有裁剪边界的侧栏和播放控制面板，不对整页/每个卡片叠加模糊，不内置 Apple 字体文件。
- 遥控器优先：方向键选择、确认执行、Android 返回使用系统回退。进度只重建控制条，视频宿主与页面布局不随每次位置更新重建。M2 控制条保持可见，自动隐藏与完整 OSD 留在 M5。

## 当前边界

测试范围为本机和 API 36 x86_64 TV 模拟器；不将虚拟 MediaCodec 结果当作 ARM 真机硬解结论。账号确认、受限内容、完整清晰度/倍速、换源恢复、系统音频焦点、休眠和长期稳定性仍按 M3–M7 验收。

网络业务失败只向 UI 暴露安全分类和可执行提示，不把原始 Dio/mpv 错误、签名 URL 或请求头直接写入状态、日志和报告。M2 不自动循环重新解析或重建播放器。
