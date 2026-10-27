# Talker 日志约定

日期：2026-10-28。当前 talker、talker_flutter、talker_riverpod_logger 均固定 5.2.0，实际 API 已通过 Flutter MCP 检查本机解析源码。TV 界面与完整接入记录见 [诊断日志](diagnostics-logging.md)。

`createAppContainer` 在 App 层统一装配唯一 Talker 实例、`appTalkerProvider` 和状态观察器，由 Riverpod 注入 API 客户端；主应用根组件持有容器，释放时清空历史并禁用日志。领域层不依赖 Talker。`app/logging/app_talker.dart` 使用 TalkerFlutter.init 管理构造与 HTTP 等级映射。

- Debug：控制台输出＋最多 200 条内存历史；不自动写文件或上传。
- Profile/Release：默认关闭；专用诊断构建可通过 `--dart-define=MAMBA_DIAGNOSTICS=true` 开启。
- 请求成功记 info，取消记 debug，4xx／网络错误记 warning，5xx 记 error。
- 保留 `SafeLoggingInterceptor`，仅把 event、method、status、category、elapsedMs 五个字段交给 Talker。现有业务调用无需逐个替换。
- 原始 URL／查询、Cookie／Set-Cookie／Authorization、请求与响应体、DioException、扫码内容、媒体地址不传给日志。应用自己的新诊断同样只记录固定事件与枚举状态。

SafeRiverpodObserver 复用官方观察器生命周期并替换原始输出，按固定 Provider 名称与状态字段白名单记录；播放进度和倒计时未改变摘要时不输出。family 参数、账号资料、原始状态／异常／堆栈不进入 Talker。需要扩展时继续补充合成秘密回归测试。

开发期读取历史：`ref.read(appTalkerProvider).history`。用户入口为设置 → 诊断日志；支持遥控器阅读、筛选、暂停显示更新和清空。使用 TalkerBuilder 订阅同一份内存历史。

`test/app/logging/app_talker_test.dart` 验证 HTTP 脱敏、级别和容量；SafeRiverpodObserver 回归覆盖 family 参数、原始对象、账号和异常秘密、高频去重及关闭配置。组件回归覆盖筛选、长列表、焦点和深浅主题。原始 M3 验收报告及 [talker-verification.json](talker-verification.json) 保持当时快照，当前结果见 [validation.json](diagnostics-evidence/validation.json)。

当前完整 250 项单元／Widget 回归通过，Flutter MCP 静态分析无诊断；TV 模拟器已显示实际脱敏记录，热重载成功，最终运行错误检查为空。Release 关闭配置由工厂配置及单元测试覆盖，本次未构建或发布 release。
