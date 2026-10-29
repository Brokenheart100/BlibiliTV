# ADR 0011：M9 类型化内容、PGC 与直播

日期：2026-10-28。状态：已采用；设备验证见 [M9 验收](../m9-validation.md)。

## 决策

保持 Flutter、Riverpod、Freezed、MVVM／整洁架构。`PlaybackTarget` 用 UGC、PGC、Live 联合类型携带稳定 ID；PGC 的 cid／bvid 从季详情解析，不能把 episodeId 或 roomId 交给 UGC 接口。`StartPlayback` 按类型调用领域 Repository，所有内容仍通过同一 `PlaybackCoordinator` 获取唯一引擎租约。新增 Repository 按需装配，普通视频的测试／调用不提前创建 PGC、本地数据库或直播服务。

`PlaybackPlan` 保存解析目标、能力与短期 `PlaybackSource`，不另外引入功能重叠的 ResolvedPlayback。Source 显式标记 DASH／HLS 等传输并保留内存请求头；URL 不进入路由、Drift、默认打印与公开报告。Android 沿用 Better Player 1.29.0／Media3 1.11.0；Windows／构建回退继续 media_kit。本轮没有更换播放器或新增依赖。

`PlaybackCapabilities` 控制菜单和命令。UGC 保留原有功能；PGC 支持本地续播、选集、倍速及有实际 cid 的覆盖层，不发送 UGC 心跳。直播仅提供播放／返回／音量／清晰度，隐藏 seek、倍速、时长、选集和点播字幕／弹幕；暂停或后台释放，恢复重新解析并进入直播边缘。断流最多重连三次，退避 1／3／10 秒；手动重试重置预算，退出／后台取消等待，下播、权限或协议不支持立即停止。

## 协议与权限

PGC 使用 Web 季详情与播放接口，读取实际的 `result.video_info` DASH。明确拒绝 `is_preview`／`PLAY_PREVIEW` 和不受支持的 DRM，不能把会员试看当完整剧集。正片与附加分组分别保留顺序，自动下一集不跨组。当前公共发现仅验证番剧索引；影视可由已有追剧入口或季链接进入，未宣称完整影视分类／关键词搜索。

直播解析短号为真实 roomId，首批仅接已验证的 HTTPS HLS／TS／AVC。推荐列表实测返回 -352，显示可重试错误，保留房间号／链接入口；不伪造推荐、不绕过风控。HLS 分片 404 是可能恢复的线路故障，按有限预算重新解析；首次原生失败报告保留。返回的备用 CDN 保留于 Source，本轮未实现独立 CDN 手动选择或证明其切换可用。

直播 `accept_qn` 不是当前游客一定能取得的权限承诺。实测请求 250 而 current_qn=150，因此以实际档位展示，并明确提示服务端回退；不能把这个结果记为切换到更高清晰度成功。PGC 依旧拒绝权限不足或试看，不因该直播规则放宽权限。

固定上游 PiliPlus 提交 `affac5334fc41744894618d9fb53b7101db9532a` 的 HTTP 文件只用于核对协议字段，实际公共只读 spike 与合成契约分别留证。PGC／直播不加入通用 HTTP 缓存白名单，媒体 URL 每次解析，不持久化。

## 存储与兼容

实施前 Drift 已是 v3（作者头像），因此本次为 **v4**，不是原计划的 v2→v3。进度键 `(ownerKey, contentKind, videoId, partId)`、历史元数据键 `(ownerKey, contentKind, videoId)`，旧行默认 UGC。实际 SQLite 测试覆盖 v1／v2／v3→v4，保留头像、搜索与既有记录；不同内容类型相同数字 ID 不相互覆盖或误删。

PGC 按季／集记录本地续播。直播只记房间访问，duration／position 为零，不参与有效点播续播。账号范围随现有会话代次取消；列表翻页和播放迟到回调不能写回新账号。不增加下载或多账号空表。

## 范围与后果

本次实现 M9-0／M9-1 和 M9-2 的基础观看；投屏、离线、多账号、直播聊天室仍独立延期。M8 最高密度弹幕持续帧性能未通过，此决策不关闭该缺口。模拟器、真实账号权限、物理 ARM、人工听感与公共发布分别验收，不用接口返回成功替代原生播放证据。
