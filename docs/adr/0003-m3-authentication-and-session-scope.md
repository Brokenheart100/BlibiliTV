# ADR 0003：M3 Web 登录、持久会话与账号范围

日期：2026-10-24。状态：已实施；实测范围与待验收项见 [M3 记录](../m3-validation.md)。

沿用 Web Cookie + WBI 协议，不读取浏览器登录态。保持 Flutter + Riverpod + Freezed + MVVM + 整洁架构：领域只定义 AuthRepository、SessionRepository、Session 与扫码挑战；Dio、Cookie、PointyCastle 和平台安全存储留在数据层，View 负责 FocusNode 和导航效果。

- `WebAuthService` 负责固定来源的扫码申请、轮询、nav 校验、Cookie 检查／续期／确认与退出。二维码目标仅允许 HTTPS 的 passport.bilibili.com、account.bilibili.com；后者已在本次真实响应观测。成功凭据从 Set-Cookie 白名单获取，忽略携带凭据的跳转 URL，所有鉴权 HTTP 请求禁止自动跟随重定向。
- `PersistentSessionRepository` 单独协调恢复、校验、更新与退出。会话状态和 generation 只有此处能改变；相同已校验身份不增加 generation，避免 Provider 重建循环。鉴权失败合并为一次校验，30 秒内限制同代自动触发；前台普通校验有 5 分钟节流，显式重试绕过节流。业务失败请求不自动重放。
- 安全存储键为 `auth.web.session.v1`，包含 Cookie、刷新令牌、owner、名称和可选待确认旧令牌。偏好键 `auth.web.blocked.v1` 仅为布尔标记：更新前阻止恢复，完整保存后解除；退出时先置位后删除凭据。异步写入串行化，取消或账号代次变化会回滚迟到写入。安全存储失败时不发布新登录；清除失败显示可重试状态。若系统连标记也无法保存，不能承诺跨进程退出已持久化，必须重试清理。
- 续期顺序为 cookie/info → correspond 页面 → cookie/refresh → nav 身份比对 → 保存新凭据和待确认旧令牌 → confirm/refresh → 保存干净记录。RSA 使用协议公钥和 OAEP SHA-256，已通过独立 OpenSSL 实现验证合成消息互操作。网络失败保留凭据并暂停鉴权使用；确认中断后重启优先继续确认，避免重复刷新。
- `RequestIdentity` 将当前 Cookie 固定到一个 Session generation；API Provider 重建会取消旧实例，不能把旧 ownerKey 的请求迁移到新账号。详情缓存包含 ownerKey。进度继续用既有 ownerKey 隔离的 Drift 记录；本阶段没有远端个人列表或写操作。
- 登录 ViewModel 按页面 ID 自动释放；显式 start 创建挑战，一次最多一个 poll。默认成功轮询间隔 2 秒，连续网络错误退避，第三次停止等待人工重试；不对写操作通用重试。倒计时最多 180 秒，服务端过期立即生效。刷新、返回、后台和释放立即取消；前台创建新挑战。二维码／key 不输出到日志，只有活跃页面内存持有。
- 回跳只允许本站有限路径；播放器目标转到详情，用户再次确认播放。一次成功效果只消费一次。账号变化关闭已有播放器并展示重新选择操作；不能让隐藏的旧播放器弹走新登录页面。清空焦点记忆防止新账号沿用旧内容位置。
- 账号页与登录页延续深色 iOS 风格、Cupertino 图标、连续圆角和玻璃面板，焦点保持高对比，所有主要动作可由方向键／确认／返回完成。

协议为社区逆向资料与上游实现，不是 B 站官方稳定性承诺。固定来源：

- [二维码协议](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/login/login_action/QR.md)
- [Cookie 续期协议](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/login/cookie_refresh.md)
- [退出协议](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/login/exit.md)
- [PiliPlus 登录实现](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/login.dart)

实际 Set-Cookie 形态、跨进程恢复和服务端退出需要真人确认后单列验证；合成网关测试及新仓储实例恢复不能冒充真实账号验收。正式签名、备份迁移、ARM 物理 TV 和长期续期留在设备与发布验收阶段。
