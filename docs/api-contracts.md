# B 站接口契约与实测记录

日期：2026-10-24。协议方向：Web Cookie + WBI；M3 已验证真实登录态，账号在验收后按授权退出。M0 探测入口：`lib/m0/data/bilibili_probe_service.dart`；正式实现：`lib/data/services/bilibili/`、`lib/data/services/auth/` 与 `lib/data/repositories/`。

参考上游固定提交及复用边界见 [ADR 0001](adr/0001-stack-and-playback.md)。下列是实际采用并验证的服务地址，不是对 B 站官方公开 SDK 的声明。

## 请求公共规则

- API 主机为 `https://api.bilibili.com`，扫码主机为 `https://passport.bilibili.com`。
- 使用常规浏览器 User-Agent 和 `Referer: https://www.bilibili.com/`；按 HTTPS 访问。
- 游客请求不含账号 Cookie；登录确认后同一 Cookie 用于 nav、列表和播放资源验证。
- WBI 参数包含秒级 wts 和 w_rid。签名所需 img/sub key 来自 nav 的 wbi_img；参数排序、字符过滤与编码以已验证实现为准。样本不记录当前签名。
- CDN 媒体只附带必要的 User-Agent／Referer，不向 CDN 自动发送账号 Cookie。
- M0 不自动重试接口；超时和业务错误报告状态类别，不输出请求头、二维码、签名或完整播放链接。

## 已执行的游客能力

| 能力 | 方法与路径 | 最小参数／响应字段 | 当前结果 |
| --- | --- | --- | --- |
| 热门 | GET `/x/web-interface/popular` | pn=1、ps=20；data.list、no_more | 成功，返回 20 项 |
| WBI key／用户 | GET `/x/web-interface/nav` | data.isLogin、wbi_img.img_url/sub_url | 游客业务码 -101，但 wbi_img 可用；不能把它识别成已登录 |
| 搜索 | GET `/x/web-interface/wbi/search/type` | search_type=video、keyword=Flutter、page=1、WBI；data.result | 成功，返回 20 项 |
| 详情／分 P | GET `/x/web-interface/wbi/view` | bvid、WBI；data.cid、pages | 成功；本次样本为单 P |
| UGC 资源 | GET `/x/player/wbi/playurl` | bvid、cid、qn=32、fnval=4048、fnver=0、fourk=1、WBI | 成功，dash.video/audio 独立资源；实际可用画质以响应为准 |

详情和资源接口来源：[PiliPlus video.dart 固定版本](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/video.dart)。路径来源：[api.dart 固定版本](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/api.dart)。WBI 来源：[wbi_sign.dart 固定版本](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/utils/wbi_sign.dart)。

完整脱敏运行记录见 [guest-api.json](m0-evidence/guest-api.json)。BVID/CID 是公开内容标识，可以用于重现样本；临时媒体 URL 不入库。扩展验证见 [extended-contracts.json](m0-evidence/extended-contracts.json)：搜索首项发现 103 P 视频，验证首／次 CID 不同且 P2 有独立视频与音轨；普通样本返回画质 ID 16、32，媒体 URL 含 deadline，本次观测 TTL 7199 秒。完整内容切换、所有档位解码、不同分页与真实过期恢复另行验收。

## Web 扫码契约

资料来源：[固定版本二维码协议资料](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/login/login_action/QR.md)。

| 能力 | 方法与路径 | 响应／语义 | 当前证据 |
| --- | --- | --- | --- |
| 生成二维码 | GET `/x/passport-login/web/qrcode/generate` | data.url、qrcode_key，资料给出的有效期 180 秒 | 实测生成成功；秘密值不保存 |
| 轮询 | GET `/x/passport-login/web/qrcode/poll`，参数 qrcode_key | data.code：86101 未扫描、86090 已扫待确认、86038 过期、0 成功 | M3 实测等待与成功；完整状态映射有合成契约／原生测试 |
| 成功凭据 | 轮询响应 Set-Cookie | 需要 SESSDATA 等 Web Cookie；随后 nav 必须返回 isLogin=true | M3 用户手机确认后验证、持久化与跨进程恢复通过 |

实现中一次只允许一个轮询，采用 2 秒间隔，不重叠；这是本项目初始策略，仍需长期使用时观察限流。取消、后台和销毁会取消请求并增加代次；返回的旧挑战不能恢复已取消状态。二维码有效期上限由本机计时和服务过期响应共同约束。

M3 真实申请返回的二维码目标为 HTTPS `account.bilibili.com`；实现只允许该域名及 `passport.bilibili.com`，不把跳转域名扩展成通配符。成功响应 data.url 可能带凭据，完全忽略；只从已知接口响应的 Set-Cookie 白名单读取 SESSDATA、bili_jct、DedeUserID、DedeUserID__ckMd5、sid，Cookie domain 必须为空或 bilibili.com。所有鉴权调用禁止自动跟随重定向。

## M3 恢复、续期与退出

主机为 `passport.bilibili.com`，下表特别标注的主机除外。固定来源与持久化顺序见 [ADR 0003](adr/0003-m3-authentication-and-session-scope.md)。

| 能力 | 方法与路径 | 参数／响应要点 | 验证层级 |
| --- | --- | --- | --- |
| 会话验证 | GET `api.bilibili.com/x/web-interface/nav` | Cookie；isLogin=true、mid 与 ownerKey 一致 | 真实登录、冷启动恢复、业务 API 身份比对通过 |
| 是否续期 | GET `/x/passport-login/web/cookie/info` | Cookie、query csrf；data.refresh | 真实启动恢复走过检查；服务端要求刷新分支采用合成响应 |
| 换取刷新 CSRF | GET `www.bilibili.com/correspond/1/{path}` | Cookie；path 为公钥 RSA-OAEP SHA-256 加密 refresh_毫秒时间戳；HTML id=1-name | 固定协议、合成传输、独立 OpenSSL 互操作通过 |
| 续期 | POST `/x/passport-login/web/cookie/refresh` | form csrf、refresh_csrf、source=main_web、refresh_token；新 Set-Cookie／refresh_token | 合成传输和并发／故障恢复测试；自然续期待实测 |
| 确认续期 | POST `/x/passport-login/web/confirm/refresh` | **新** Cookie、form 新 csrf、**旧** refresh_token | 合成测试验证先保存新凭据再确认，失败后继续确认 |
| 退出 | POST `/login/exit/v2` | Cookie、form **biliCSRF**；根 code=0、status=true | 用户授权下真实成功；本机清除并再次冷启动为游客 |

真实账号下热门、详情／分 P、WBI 与 DASH 使用同一捕获身份，nav 匹配。AVC/AAC 资源已在原生播放器实际播放；报告仅保留公开 BVID 与安全布尔值，见 [real-account.json](m3-evidence/real-account.json)。服务端自然续期、真正过期后重新扫码及长期限流表现未据合成测试宣称完成。

## M4 推荐与相关视频

固定上游路径／参数与协议资料见 [ADR 0004](adr/0004-m4-discovery-and-search.md)，本次真实请求使用游客，无 Cookie。

| 能力 | 方法与路径 | 参数／响应 | 实测 |
| --- | --- | --- | --- |
| Web 推荐 | GET `/x/web-interface/wbi/index/top/feed/rcmd`，WBI | version=1、feed_version=V8、homepage_ver=1、ps=12、fresh_idx／brush 从 1 递增、fresh_type=4；data.item | 游客成功 12 项；保留 goto=av 的有效 UGC，剔除直播／广告卡片，BVID 去重 |
| 相关视频 | GET `/x/web-interface/archive/related` | bvid；data 为数组 | 成功 40 项；独立列表适配，排除当前视频、去重并最多展示 20 项 |

本次推荐未返回 has_more，不能虚构服务端结束字段；页面以非空页继续取下一页，同时防重复游标／连续无新增结果。热门支持布尔或数值 no_more；搜索按 numPages 结束。推荐第一页仅鉴权／权限失败会降级热门并提示，后续分页不能跨来源拼接，限流和网络错误不隐式降级。

推荐／相关封面存在 HTTP 或协议相对地址，统一转 HTTPS，不开放 Android 明文流量。详情补充 UP 名称／mid／face 与已有简介、pages。UP mid 是公开视频元数据，不是当前登录账号标识。

真实热门 10 页 120 条唯一结果、中文搜索两页去重后 36 条、103 P 样本第二 P 的实际 640×360／44.1 kHz 播放和返回见 [native-discovery.json](m4-evidence/native-discovery.json)。系统输入法使用“记录”的实测与自动测试输入“纪录片”分别记录，见 [原生 IME](m4-evidence/native-chinese-ime.json)。媒体地址仍不持久化。原生播放修正了主文件未就绪时过早 audio-add 的时序问题，说明见 ADR。

## M2 正式仓储补充

已重新通过固定提交的上游源文件核对，并用正式 Repository 实测热门、搜索、详情与 DASH，见 [guest-contracts.json](m2-evidence/guest-contracts.json) 与 [完整播放验收](m2-validation.md)。本次不申请二维码、不轮询、不使用浏览器 Cookie。

- 热门使用 pn/ps，普通页样本 12 项；`no_more` 控制下一页。
- 搜索按服务的 `numPages` 判断下一页；结果并非全部 UGC，已观察 `type=ketang`、空 bvid/空 duration。只将有效 BV 的 video 项送入 DTO，保留课程等类型为不支持范围，不用伪造字段填补。
- 搜索时长可为超过 60 分钟的 `分钟:秒`，同时兼容 `时:分:秒` 与热门中的秒数；标题去掉搜索高亮标签，图片支持协议相对地址。
- 详情 pages[].cid 映射为字符串分 P ID；播放前重新校验指定 CID 属于当前视频，不直接相信路由参数。
- DASH 同时兼容 baseUrl/base_url；M2 选择服务实际返回的较低带宽 AVC 和 AAC，优先兼容当前设备；不承诺请求 qn=32 就一定播放 480P。
- WBI key 在内存按一小时上限缓存；请求取消连接到 Dio CancelToken，监听在请求结束后移除。权限/风控失败可清除 key，下一次显式重试重新获取；不自动循环重签或重开播放器。
- CDN 的视频与外部音轨均绑定 User-Agent/Referer；不发送账号 Cookie，不持久化签名媒体 URL。
- 权限、限流、超时、网络故障、契约/编码不支持分别映射为安全 Failure；自动测试以合成响应覆盖，真实服务所有错误码的完整语义仍待逐项观测。

## 仍未完成的契约

- nav／启动恢复／刷新／退出的实现与证据见 M3；自然续期和真实过期场景仍待补验。
- 真实账号个人列表 GET 已在 M6 验证；写入与心跳本次按只读授权保留。
- 字幕／弹幕和受限内容按后续计划接入。
- 权限不足、资源失效、风控／限流等真实故障与契约变更样本，不伪造已实测结果。

## 重现

2026-10-25 缓存更新：热门与搜索最多 1 分钟、详情与相关视频最多 3 分钟；按会话隔离，HTTP 200 的非零业务 code 不保存。nav、推荐、登录和播放地址不经过缓存，真实签名仍正常生成。固定寿命、服务端 no-store 与强制刷新策略见 [ADR 0005](adr/0005-scoped-http-cache.md)，原验收数据保留为历史快照。

执行 `dart run tool/m0_probe.dart` 可重现游客与二维码未扫描探测，写出脱敏报告。运行 M0 应用时，扫码需要用户在手机上主动确认；本项目不会从浏览器或其他应用读取已有 Cookie。

## M6 账号列表与进度

2026-10-25，来源：[PiliPlus 固定提交的 API 定义](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/api.dart)、同提交 `lib/http/{user,fav,video}.dart` 及稍后再看 controller。补充完整列表语义见[固定协议资料](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/historytoview/toview.md)。这些属于第三方 Web 协议实现依据，不是 B 站官方稳定 SDK。

主机 `api.bilibili.com`，均绑定当前账号 Cookie／代次，私有数据绕过通用缓存。固定 User-Agent／Referer 沿用内容接口。真实账号验证仅 GET，见 [只读报告](m6-evidence/real-readonly.json)。

| 能力 | 方法与路径 | 关键字段／分页 | 验证 |
| --- | --- | --- | --- |
| 远端历史 | GET `/x/web-interface/history/cursor` | type=archive、ps=24、max／view_at／business；下页取最后原始行 history.oid／view_at／history.business，相同游标停止 | 真实首／下一页 |
| 收藏夹 | GET `/x/v3/fav/folder/created/list` | up_mid、pn、ps=24；list／has_more | 真实首屏；页码合成 |
| 夹内视频 | GET `/x/v3/fav/resource/list` | media_id、pn、ps=24、order=mtime、type=0、tid=0、platform=web；medias／has_more | 真实读取 |
| 稍后再看分页 | GET `/x/v2/history/toview/web`，WBI | pn、ps=24、viewed=0、key 空、asc=false、need_split=true、web_location=333.881；list／count | 真实首屏；下一页合成 |
| 收藏状态 | GET `/x/v3/fav/folder/created/list-all` | up_mid、rid=aid、type=2；list[].fav_state=1 为选中 | 真实读取 |
| 完整稍后列表 | GET `/x/v2/history/toview` | list[].aid／bvid 与目标匹配；count 大于已返回条数且未找到目标时，拒绝把缺失当作未加入 | 真实读取／不完整合成 |
| 加入稍后再看 | POST `/x/v2/history/toview/add` | form bvid、csrf=bili_jct | 合成传输，真实未执行 |
| 移出稍后再看 | POST `/x/v2/history/toview/v2/dels` | form resources=aid 字符串、csrf；不是 `aid:2` | 合成传输，真实未执行 |
| 收藏夹变更 | POST `/x/v3/fav/resource/batch-deal` | resources=`aid:2`、add_media_ids／del_media_ids、csrf | 合成传输，真实未执行 |
| 观看进度 | POST `/x/click-interface/web/heartbeat` | bvid、cid、played_time 秒、type=3、csrf | 合成传输／时钟，真实未执行 |

详情没有 aid 时先读取已验证的 WBI view 解析真实 aid，不能由 BVID 猜测。空 list 兼容 null；不支持的历史 business／空 BVID 保留为不可播放条目。权限、鉴权、限流、网络、超时、契约错误使用安全 Failure，不展示服务端原始响应或个人内容。

所有个人列表命令都先读当前状态，最多发出一次 POST，再读确认。响应丢失但目标状态已观察到时确认成功；未确认时保留原始意图，关闭／重开弹层也不会在同一会话盲目重放。账号替换销毁原 API scope，旧请求取消；不将未确认命令持久化或排队到新账号。
