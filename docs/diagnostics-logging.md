# TV 诊断日志与 Riverpod 状态记录

日期：2026-10-28。

## 入口与操作

设置 → 诊断日志。支持深浅主题、全部／网络／状态／错误筛选、清空确认。上下选择日志，向右或确认进入详情，上下滚动详情，向左返回列表；返回键回到设置并恢复原按钮焦点。进入列表阅读时暂停显示更新，避免新记录挤走当前内容；“继续更新”可读取最新历史。日志仍在后台按上限收集，页面冻结不影响播放和业务。

最近 200 条记录仅保存在当前进程内存，清空、进程退出或容器释放后不保留。没有增加账号数据持久化或外部日志上传。调试构建默认记录；普通 profile/release 默认关闭，可为专用诊断构建添加 `--dart-define=MAMBA_DIAGNOSTICS=true`，关闭时页面说明当前构建未启用日志。

## 装配与脱敏

talker、talker_flutter、talker_riverpod_logger 均固定 5.2.0。talker_flutter 的 TalkerFlutter.init 提供 Flutter 输出，TalkerBuilder 订阅日志历史；页面使用现有 TV 控件和独立详情区。没有直接使用面向触摸操作的默认工具栏。

createAppContainer 为主入口、只读验证入口和组件测试统一装配共享 Talker、appTalkerProvider 与 SafeRiverpodObserver；主应用由 AppProviderScope 持有并释放容器。网络记录沿用 SafeLoggingInterceptor，只记录方法、状态码、耗时和类别，同一请求没有增加第二套拦截器。

SafeRiverpodObserver 继承官方 TalkerRiverpodObserver，禁用其原始负载输出，再将回调投影为允许字段的 TalkerLog。只把输出设为截断仍会暴露 family 参数，无法替代这一步。日志不持有原始 Provider、状态、异常或堆栈对象，不调用它们的 toString。

观察范围为账号状态、扫码、内容列表、播放器、个人列表和设置。只记录固定 Provider 名称、生命周期、状态阶段、数量、错误分类和少量播放设置；不记录 family 参数、搜索词、昵称／UID、二维码、Cookie、视频标题／地址、分段弹幕或字幕文本。播放器位置／缓冲进度和扫码倒计时如果没有改变摘要，不产生更新日志。字幕／弹幕调度和未入选 Provider 不记录。

播放器原生日志与 Flutter 的所有未捕获异常不会因安装扩展自动变为安全日志；当前仍通过已有业务错误分类进入诊断，不能将原始异常直接交给 Talker.handle。

## 验证

单元测试覆盖共享实例、1000 次原生进度更新不刷屏、关键状态变化、Provider 销毁、family 参数／账号资料／异常消息与堆栈不进入历史，以及关闭诊断后不留记录。组件测试在 640×360 与 960×540 检查深浅主题、27 条日志滚动、筛选、阅读冻结、清空和设置焦点恢复。

原生 API 36 x86_64 TV 模拟器安装隔离验证包，方向键从设置进入日志、选择记录、进入详情并返回；实际 HTTP 和 Riverpod 元数据已显示。Flutter MCP 热重载与静态分析成功。首次自动化等待因焦点尚未进入内容区而超时，重新按焦点状态逐步操作通过；本轮结束检查无新增应用运行时错误。完整回归与许可检查结果见 [validation.json](diagnostics-evidence/validation.json)，[深色界面预览](diagnostics-evidence/logs-dark.png)。物理电视与 ARM 本轮未验收。
