# Better Player Android 播放试用

> 2026-10-29 更新：用户已确认移除 media_kit，构建回退开关和 Windows 的旧适配器现已删除。下文是 2026-10-27 的历史试用记录，其中回退命令不再有效；当前装配及验证见 [后端清理](media-backend-cleanup.md)。

日期：2026-10-27。目的是对比 TV 模拟器在快进／快退后短暂杂音的表现；自动播放成功不等于人工听感通过。

## 装配与边界

Android 默认使用锁定的 `better_player 1.29.0`，实际 Android 插件 `better_player_android 1.9.0` 使用 Media3 1.11.0。使用包公开导出的 `PlayerEngineController`／`PlayerEngineView`，接入现有 `PlaybackEngine` 接口；保留 Riverpod、Freezed、MVVM、播放器租约、电视遥控器、iOS 风格控制层和弹幕层。未使用面向触屏的内置播放器控制界面。

B 站 DASH 的视频和 AAC 音频仍是不同 CDN 资源，由单个 Media3 播放器统一调度。仓储保留选定轨道的 codecs、带宽、SegmentBase 初始化与索引范围；适配器生成静态 MPD。仅在进程内存和绑定 `127.0.0.1` 的随机端口／随机路径上提供 MPD，随播放器释放关闭，不落盘、不写日志。CDN 媒体请求使用 HTTPS，继承 B 站 Referer／User-Agent；Android 明文例外仅允许回环地址。

缓冲条读取原生 `VideoPlayerValue.buffered`，选择覆盖当前播放位置的范围终点；跳转期间清空旧缓冲。Android 插件 1.9.0 虽声明 onSeek，实际未发出该回调，因此跳转核对原生实际位置、可播放缓冲范围和缓冲状态，连续两次采样就绪后才完成，不能以 Dart 的乐观位置更新作为完成。播放时每 100ms 获取原生时钟，为既有弹幕／字幕时间线提供采样；最多一个采样请求在途。

倍速、音量在新数据源初始化后重新应用。资源释放等待原生 `dispose()`，然后关闭回环服务。原生日志回调关闭，错误继续映射成脱敏的 AppFailure。

## 运行与回退

正常 Android 构建默认启用 Better Player：

```powershell
flutter run -d emulator-5554
```

构建时回到原来的 media_kit：

```powershell
flutter run -d emulator-5554 --dart-define=MAMBA_PLAYBACK_ENGINE=media_kit
```

Windows 继续使用 media_kit；两套原生依赖目前同时保留，尚未缩减 APK。切换原生插件需要重新构建安装。已发布的 Release 不受本地试用改动影响。

## 验证入口

单元测试：`test/data/better_player_engine_test.dart`、`test/data/dash_manifest_test.dart`、`test/data/m5_playback_repository_test.dart`。覆盖 DASH 元数据、XML 转义、回环服务生命周期、真实缓冲范围、暂停跳转、配置恢复和等待原生释放。

真实 TV 模拟器测试使用隔离验证包、游客会话与独立数据库：

```powershell
flutter drive --profile --driver test_driver/better_player_test.dart --target integration_test/better_player_test.dart -d emulator-5554 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --no-uninstall-first --keep-app-running
```

原生报告写到 `docs/better-player-evidence/native-validation.json`，仅记录位置、缓冲、画面尺寸和状态。听感、口型同步、物理电视及 ARM 验收需要单独记录；Media3 位置前进不能证明音画同步或消除杂音。

API 36 x86_64 TV 模拟器 profile 实测通过：真实公开视频 `BV1wR4Xz6EqG` 输出 640×360；暂停前进 60 秒／后退 45 秒保持暂停；播放中依次跳转 +240／−180／+60／−30／+120／−90 秒，每次恢复时间前进，原生缓冲与界面比例一致；原生释放正常。Windows G7u HDMI 对模拟器进程的 100 次电平采样中 65 次非零，峰值 0.6512，仅说明宿主实际有音频输出，人工听感仍待确认。

完整本机回归 220 项通过；Flutter MCP 静态分析无诊断，普通验证应用热重载成功、运行时错误为 0。普通应用恢复播放后另取 100 次宿主电平，全部非零、峰值 0.9584。自动结果汇总见 [validation.json](better-player-evidence/validation.json)。尚未重新验证历史 15／30 分钟长时场景、画质／音轨完整切换、真实账号、ARM 及物理电视；未创建新 Release 或推送本次改动。

API 来源：[Better Player](https://pub.dev/packages/better_player)、[平台说明](https://jhomlala.github.io/betterplayer/platform_support/)、[Media3 DASH](https://developer.android.com/media/media3/exoplayer/dash)。实现同时核对实际锁定包源码，不修改 Pub 缓存或使用 dependency_overrides。

2026-10-27 用户选择“暂不试听，先保留这个版本”：继续保留 Android 默认 Better Player，不再启动本轮试听对照；人工听感验收记为用户暂缓。自动报告中的 pending 是当时的采样状态，不能视为杂音已消除。
