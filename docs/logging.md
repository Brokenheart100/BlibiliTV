# Talker 日志约定

日期：2026-10-24。M3 后续更新，使用精确版本 Talker 5.1.21；[包文档](https://pub.dev/packages/talker/versions/5.1.21)，实际 API 已通过 Flutter MCP 检查本机解析源码。

`appTalkerProvider` 在 App 层持有唯一 Talker 实例，由 Riverpod 注入 API 客户端，释放时清空历史并禁用日志。领域层不依赖 Talker。`app/logging/app_talker.dart` 管理构造与 HTTP 等级映射。

- Debug：控制台输出＋最多 200 条内存历史；不自动写文件或上传。
- Profile/Release：通过 `kDebugMode` 默认关闭，避免持续诊断输出与历史收集。
- 请求成功记 info，取消记 debug，4xx／网络错误记 warning，5xx 记 error。
- 保留 `SafeLoggingInterceptor`，仅把 event、method、status、category、elapsedMs 五个字段交给 Talker。现有业务调用无需逐个替换。
- 原始 URL／查询、Cookie／Set-Cookie／Authorization、请求与响应体、DioException、扫码内容、媒体地址不传给日志。应用自己的新诊断同样只记录固定事件与枚举状态。

没有接入会自动记录完整请求或 Provider 状态的通用拦截器／观察器。需要扩展时，先定义字段白名单和合成秘密回归测试；尤其不能直接打印包含二维码挑战或凭据的数据状态。

开发期读取历史：`ref.read(appTalkerProvider).history`。该更新没有增加 TV 日志查看页面、导出或远程采集入口；用户界面和遥控器导航保持现有流程。

`test/app/logging/app_talker_test.dart` 验证成功／失败均不泄露合成秘密、HTTP 级别、200 条上限和关闭配置；既有 HTTP 脱敏测试保留。原始 M3 验收报告保持当时快照，后续日志接入结果见 [talker-verification.json](talker-verification.json)。

最终 67 项单元／Widget 回归通过，Flutter CLI 与 MCP 静态分析无问题。TV 模拟器已观测到 Talker 的脱敏 HTTP 输出，热重载成功，运行错误检查为空；默认产品入口的调试 APK 已重新构建、安装并冷启动。Release 关闭配置由工厂配置及单元测试覆盖，本次未构建 release 包。
