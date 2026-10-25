# ADR 0006：M5 播放控制、切换与受限恢复

日期：2026-10-25。状态：已实施，本机与 TV 模拟器自动验收通过；人工音画和真机待补验，见 [M5 记录](../m5-validation.md)。继续使用 Riverpod + Freezed + MVVM + 整洁架构、深色 iOS 风格和 D-pad 导航。

## 分层

- Domain：PlaybackSource 只存临时资源，toString 始终脱敏；PlaybackOption 为不可变菜单项，PlaybackFocus 描述申请、释放和中断。StartPlayback 负责校验 CID 属于视频、重新解析资源、读取设置／进度及生成计划。
- Data：BilibiliPlaybackRepository 解析实际 DASH 列表与支持格式；MediaKitEngine 封装平台播放、倍速／音量、错误分类及 Android 销毁兼容；AudioSessionFocus 封装 audio_session 0.2.4 和遥控器连接事件。
- App：PlaybackAdapter 装配原生引擎、画面和音频焦点；PlaybackCoordinator 串行管理引擎租约。测试替换 Adapter／Repository，不把原生类型放进 ViewModel。
- UI：PlayerViewModel 维护 Freezed 快照、播放意图、串行命令和代次；View 仅维护控制条计时、焦点、弹层与路由。进度显示单独 select，时间轴变化不重建画面和玻璃面板。

## 资源与能力

默认继续选择服务实际返回的较低带宽 AVC＋AAC，优先兼容已验证设备。画质菜单列出实际 AVC 轨道；support_formats 中未提供相应 AVC 资源的档位保留解释，不把服务声明等同于当前账号可播放。非 AAC 音轨、HEVC／AV1、DRM／HDR 不据此宣称支持。

选择画质／AAC 音轨时重新请求 playurl，校验指定 ID 确实在响应中，不能静默降档。音轨标签显示编码与带宽，不伪称不同语言。只接受 HTTPS 主／备用资源；签名地址、请求头不入数据库、缓存、业务状态菜单或日志。playurl 继续绕过 HTTP 缓存。

本阶段的“设备能力”是已经验证的 AVC／AAC 客户端策略，不代表已经完整探测每台电视的 profile、level、HDR 或硬件分辨率上限。物理解码能力继续在设备矩阵验收。

## 操作和并发

原生操作串行执行；新视频／分 P／清晰度意图立即取消旧代次，排队工作检查代次后才创建引擎。等待打开／解析可响应取消，迟到结果不允许重播。每次先保存、释放旧租约，再取得新租约；在发布租约时更新 surfaceGeneration，确保原生画面先挂载再等待首帧。

同一分 P 换画质或音轨保留位置、倍速、音量及播放／暂停意图；连续快速切换使用固定的目标位置，不能读到新引擎的初始零覆盖原位置。换 P 从零开始；正常重新打开读取该 P 的有效本地进度。控制条提供 0.5–2.0×、播放器音量、画质、音轨、选集、连播和下一集。

Android 使用已验证的 mediacodec_embed／mediacodec 配置。继续等待主文件有效 duration 后挂载独立音轨，保留 M4 的装载时序修复。暂停打开时不为首帧而短暂播放：确认暂停时间轴后就绪；该输出模式可能等到用户继续播放才解码新帧，不能把暂停就绪等同于已看到新画面。

M2 的 Android 兼容处理保留：停止 widListener／视频参数监听，排空视频控制器锁，再销毁 Player。切换、正常退出和 Provider 释放都通过同一租约关闭；onDispose 只作兜底，不承担正常退出的唯一保存路径。

原生验收构建须添加 `--dart-define=MAMBA_VALIDATION_APP=true`，Gradle 仅在此开关存在时把 applicationId 改为 `app.mamba.mambatv.validation`，默认产品构建命令保持原值。当前 Flutter SDK drive_service.stop 会卸载包，且仍可能读取主清单 ID，必须同时使用 `--keep-app-running --no-uninstall-first`，结束后按验证包 ID 显式 force-stop。独立数据库无法防止卸载删除主包数据，因此安装和停止边界都需隔离。

## 恢复上限

每次用户主动播放／切换重置预算，同一次自动恢复不会重置：

| 失败 | 策略 |
| --- | --- |
| 识别出的过期资源（403／410） | 只允许一次重新解析 |
| CDN／连接失败 | 至多一次成对备用资源，再至多一次重新解析 |
| 网络／超时 | 至多一次重新解析 |
| 账号、权限、风控、契约、解码不支持 | 停止自动恢复，提供人工操作 |

原生错误只在适配器内分类，原始字符串立即丢弃。缺少明确 HTTP 状态的“failed to open”按受限线路故障处理；不能把底层信息不足的错误伪称已准确识别原因。重新解析仍受 Web API 的账号和错误边界限制，不自动重新登录、循环签名或降档。全局缓存和 Provider 都不承担重放播放命令。

## 进度和完成

只接受至少 1 秒、duration 为正且 position 不超过 duration 的有效进度。按位置差或单调时间约 5 秒节流，倒退 seek 也能写入；暂停、seek、换源、后台和正常退出显式保存并等待串行存储。适配器在 seek 命令返回后等待位置事件，避免后续相对跳转或保存读取旧时钟。打开时先确认续播位置，零／无效时间轴不能覆盖旧记录。正常关闭／挂起已排空存储时，Provider 销毁不再追加重复写入。

完成事件将进度归到有效 duration，详情的既有规则排除最后 10 秒内的自动续播。自动下一 P 默认关闭，当前播放会话可开启／关闭；最后一 P 结束后停止，不能绕回第一 P。倍速、音量和暂停意图在切换／后台恢复中保留；跨会话默认偏好与设置页仍按 M6 继续。

## 生命周期与焦点

audio_session 申请 MEDIA／MOVIE 焦点，并要求 duck 时暂停。焦点拒绝不打开引擎；中断、耳机拔出、遥控器断开、Home／后台、休眠和路由遮挡都保存位置并关闭引擎。返回、焦点恢复或遥控器重连后不自动播放，用户确认才重新申请焦点并解析／打开资源。

焦点申请／释放串行且带调用方所有权，旧路由的迟到释放不能撤销新路由的焦点。Android InputManager 监听 D-pad／gamepad 断开，只传连接布尔值，不传设备名称或标识。系统屏幕休眠测试记录生命周期事件；不能依赖屏幕关闭时产生渲染帧。

控制条播放时 5 秒自动隐藏，暂停／失败保持可见。画面区的左右负责 seek，确认负责播放／暂停，上下调出控制；控制条方向键只移动焦点；弹层吸收左右键并虚拟滚动长选集。Back 先关闭弹层，否则显式关闭播放器返回。退出中的按键／按钮不再发起新操作。

## 来源

- [audio_session 0.2.4](https://pub.dev/packages/audio_session/versions/0.2.4)：实际配置、setActive、中断和 becomingNoisy API 已通过 Flutter MCP 核对解析源码。
- [Android 音频焦点](https://developer.android.com/media/optimize/audio-focus)：焦点申请、丢失处理及后台限制。
- [InputDeviceListener](https://developer.android.com/reference/android/hardware/input/InputManager.InputDeviceListener)：设备增减事件。
- [media_kit](https://github.com/media-kit/media-kit)：核对本地 1.2.6 的 setRate／setVolume／open 与 2.0.1 视频控制器生命周期；未改依赖包源码或引入 fork。
- [mpv 属性](https://mpv.io/manual/stable/#properties)：原生音画时差的诊断依据，不能替代人工听看。
