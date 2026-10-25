# ADR 0005：按会话隔离的 HTTP 内存缓存

日期：2026-10-25。状态：已实施。使用 `dio_cache_interceptor 4.0.7`，实际解析 `http_cache_core 1.1.4`。本决策替代 ADR 0004 的详情仓储内存 Map，图片缓存与 Drift 本地数据仍各自管理。

## 边界

缓存只在 Data 层使用。App 装配 `BilibiliCacheInterceptor`；每个 `BilibiliApi` 拥有独立 `BilibiliCacheScope`，选项通过 Dio 请求 extra 传递。Domain／ViewModel 不依赖 Dio 或缓存库，列表仓储只暴露 `forceRefresh` 这一业务意图。

| 白名单 GET 接口 | 自响应收到起的固定最长寿命 |
| --- | --- |
| `/x/web-interface/wbi/view` | 3 分钟 |
| `/x/web-interface/archive/related` | 3 分钟 |
| `/x/web-interface/popular` | 1 分钟 |
| `/x/web-interface/wbi/search/type` | 1 分钟 |

只接受 `https://api.bilibili.com:443` 的这些路径；默认不缓存。推荐、nav／会话检查、二维码、退出、playurl、其他新端点以及非 GET 请求始终绕过缓存。缓存不承诺离线播放。

使用库的 `MemCacheStore` LRU，每个当前 API 实例最多 4 MiB、单条 512 KiB，超大条目跳过；这是库估算的响应内容／头字节预算，不是进程总内存上限。没有接入磁盘 Store、额外数据库、清库迁移或通用 DTO 缓存。

## 键与失效

缓存键是 scopeKey（ownerKey＋generation）、方法、源站、路径及排序后的业务查询参数的 SHA-256。查询保留关键词、页码、视频等差异，仅排除 `wts`／`w_rid`，避免时间戳让同一业务请求永不命中。原始网络请求继续正常 WBI 签名；不把 Cookie、CSRF、刷新令牌放入键或日志。

每个 BilibiliApi 自己持有 Store，因此同账号的新代次也从空缓存开始。原有 Riverpod 会话替换会释放旧 API：取消旧请求、同步标记 Store 关闭、清空内存；晚到响应不能重新写入。`-101`／HTTP 401 还会清空当前 Store，并保留原来的身份失效处理。

已移除 BilibiliCatalogRepository 的 24 项／3 分钟 `_details` Map。详情重用由 HTTP 缓存统一负责，Riverpod 继续管理页面生命周期和已呈现状态。

## 读取、刷新与错误

普通读取使用 `forceCache`，只在固定寿命内命中；主动刷新使用 `refreshForceCache`，每次访问网络并以成功响应替换。CatalogViewModel 的刷新／重复搜索提交，经 CatalogRepository 的 forceRefresh 传递到底层；追加页正常缓存，取消／迟到响应保护保留。

已核对 4.0.7 源码：单独使用 maxStale 会在命中时向后延长，forceCache 也会强制保存服务端 no-store。因此保留库的 LRU 与序列化，在轻量适配中额外限制：

- 寿命以 CacheResponse.responseDate 为锚点，每次读取检查，写入时固定 maxStale；反复命中不续期。
- 仅保存 HTTP 200、JSON envelope 的 code 为 0、data 为 Map／List 的响应。
- 服务端 `Cache-Control: no-store`、`Vary: *` 或 Set-Cookie 出现时不保存，并清除该键旧条目。
- HTTP 错误、业务错误、取消继续向上返回；不配置 HTTP 错误或过期网络失败兜底，避免掩盖鉴权／权限／风控。新鲜条目可以在断网时直接读取；显式刷新失败仍显示失败，由既有页面状态保留旧列表。
- Talker 仍只接收既有五个安全字段，不记录缓存键、身份、URL／查询、头或正文。

这里采用明确的短期应用缓存，不启用 ETag／304 条件重新验证，也不承诺过期离线内容。遇到 no-store 等限制时，真实请求可能连续两次都走网络，探测报告必须如实记录。

## 依据与验证

- [锁定版本包文档](https://pub.dev/packages/dio_cache_interceptor/versions/4.0.7)
- [CachePolicy API](https://pub.dev/documentation/dio_cache_interceptor/4.0.7/dio_cache_interceptor/CachePolicy.html)
- 已通过 Flutter MCP 的 read_package_uris／rip_grep_packages 核对本地解析源码，包含拦截器、CacheOptions、CacheResponse、CacheStrategyFactory 与 MemCacheStore。
- 回归、真实游客探测和模拟器结果见 [HTTP 缓存验收](../http-cache-validation.md)。
