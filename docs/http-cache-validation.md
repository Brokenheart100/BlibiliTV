# HTTP 缓存接入验收

日期：2026-10-25。状态：按接口白名单实施，单元／Widget、真实游客请求和 TV 模拟器页面验证通过；不改变 M5 尚未开始的状态。

使用 `dio_cache_interceptor 4.0.7` 和传递依赖 `http_cache_core 1.1.4`。具体接口、账号作用域、固定寿命、容量与错误处理见 [ADR 0005](adr/0005-scoped-http-cache.md)。原仓储详情 Map 已移除，缓存统一在 Data 层。

## 结果

- 全量单元／Widget **113 项通过**：原有 89 项与新增 24 项缓存测试；既有会话隔离测试还增加了真实 Riverpod 替换后旧 Store 清空断言，分页刷新测试增加了 forceRefresh 传递断言。
- 新增测试通过真实 Dio 拦截器与内存 HTTP Adapter，覆盖四端点命中、刷新替换、业务键／WBI 签名、账号／代次隔离、固定 1／3 分钟寿命、GET／HTTPS 源站检查、默认旁路、HTTP 200 业务错误、HTTP 错误、no-store／Set-Cookie／Vary、契约 envelope、离线新鲜读取／过期失败、取消、关闭后晚到响应、LRU／单条容量与日志字段。
- Flutter CLI 静态分析无问题，Flutter MCP 静态分析无错误；模拟器热重启成功，热门切换／刷新、详情进入／返回、搜索“纪录片”呈现后运行错误检查为空。
- 真实游客探测共 9 次网络请求：四个白名单端点各一次冷请求及一次主动刷新，另一次 nav 用于 WBI key。四者第二次读取都没有新增网络请求、缓存命中为 true；每次主动刷新都新增 1 次请求，见 [guest-network-probe.json](http-cache-evidence/guest-network-probe.json)。
- 模拟器搜索输入使用 Flutter Driver 文本输入，此次没有重复操作系统中文输入法；系统 IME 的独立结果保留在 M4 历史记录。

![热门页刷新后](http-cache-evidence/popular.png)

![搜索结果](http-cache-evidence/search.png)

## 复现

```powershell
flutter pub get
dart run build_runner build
flutter test
flutter analyze
dart run tool/http_cache_probe.dart
flutter run -d emulator-5554 -t tool/m4_app.dart
flutter build apk --debug
```

`http_cache_probe.dart` 创建全新的游客 API，不读取产品数据库或安全凭据。报告只写端点类别、计数、状态和缓存限制标记，不包含响应正文、签名、URL、账号或 Cookie。内存缓存不会跨进程保存；产品搜索历史继续由 Drift 管理。

最终默认入口构建／安装结果与汇总见 [verification.json](http-cache-evidence/verification.json)。该记录不等同于物理 TV、ARM 或正式发布验收，也没有重新验证真人账号登录。
