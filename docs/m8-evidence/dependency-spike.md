# M8 依赖与生成验证

日期：2026-10-26。实际依赖取自 `pubspec.lock`，API／许可通过 Flutter MCP 的包源码读取核对。

| 依赖 | 用途 | 本地许可 |
| --- | --- | --- |
| canvas_danmaku 0.3.3（官方 Pub 包） | 原生视频上的 Flutter 画布；addDanmaku／pause／resume／clear／updateOption | MIT |
| protobuf 6.1.0 | Web 分段解码与未知字段兼容 | Dart BSD 3-Clause |
| fixnum 1.1.1 | 生成代码 int64 类型 | 随锁定依赖收集 |
| protoc_plugin 25.0.0 | 开发期 Dart 生成器 | Dart BSD 3-Clause |
| protoc 36.2 | 开发／CI 编译器，官方 GitHub Release | 编译工具，不进入 APK |

未升级 media_kit／原生播放器，未增加 gRPC、WebSocket、下载或投屏插件。字幕 JSON 使用 Dart 标准库与 Flutter 文本。运行依赖许可由 Flutter 许可页自动汇集；完整版本、原文与摘要见 `docs/release/dependencies.json` 和 `THIRD_PARTY_NOTICES.txt`。

`python tool/proto/generate.py` 从工具链清单取版本并验证官方 zip SHA256；Windows／Linux 使用相同 schema 和锁定插件。该脚本编译原生 `protoc-gen-dart`，避免 Windows batch stdin 问题；编译时使用项目 package_config，避免上游工作区 pubspec 干扰。zip 输出只允许预期三份 Dart 文件，不随意解压路径。

画布自身管理动画 ticker 与字图像释放；业务层控制最大送入条数、媒体时间、窗口、取消与低负载处理，库不承担账号或 B 站网络职责。生产层可更换画布而不改变 Repository／领域模型。实际性能结果与限制以 M8 验收为准。

原版 0.3.3、文字 alpha 优化、picture 缓存试验、Skia 对照与本地 30／15 fps 调度试验的失败证据分别保留。当前依赖改回官方包；本地补丁及来源记录位于 third_party/canvas_danmaku，仅用于历史核查，不参与构建。正式性能结果以最终 M8 报告为准。
