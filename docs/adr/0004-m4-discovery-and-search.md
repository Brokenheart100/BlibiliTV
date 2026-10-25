# ADR 0004：M4 内容发现、搜索与详情

日期：2026-10-24。状态：已实施，设备结果见 [M4 验收记录](../m4-validation.md)。

继续使用 Flutter + Riverpod + Freezed + MVVM + 整洁架构和深色 iOS 风格。View 仅持有焦点、输入、滚动及导航状态；业务页面使用 AsyncNotifier 和不可变快照，仓储负责协议、缓存与本地存储。

## 数据与状态边界

- 首页“为你发现”调用经固定上游和真实游客请求核对的 WBI 推荐接口，“热门视频”使用独立热门接口。游客明确标注游客推荐。推荐第一页仅在鉴权／权限失败时降级热门并提示；网络、限流和契约错误保留为错误。后续分页失败不混入另一种来源。
- 分页游标包含推荐／降级来源，热门与搜索仍遵循各自的结束字段。CatalogViewModel 对第一页和追加页均按 BVID 去重，重复命令不重叠；刷新取消追加请求。重复游标或连续两页无新增内容时停止追加并提示刷新，避免无限消耗请求。局部失败保留旧内容和游标，追加失败可在页尾重试。
- 搜索框的编辑／输入法组合态属于 View，仅显式提交后更新按 ownerKey 隔离的 SearchQuery。新查询同步取消旧结果请求，页面以 ownerKey、pageId、query 区分 Provider 和焦点记忆；迟到旧结果不能覆盖新查询。输入法候选词未确认时不发送搜索。
- SearchHistoryRepository 使用已有 Drift v1 SearchEntries 表，不升级 schema。历史按 ownerKey 隔离、去空白和精确去重，最多 12 条；清空只作用于当前 owner。命令串行化，重复关键词先在事务内删除再插入，以 updatedAt＋rowid 确保同一秒内仍按最近提交排序。
- ProgressRepository 新增 latestForVideo，查询当前 owner 的最近分 P；有效、未临近结尾且启用续播时，详情显示继续播放。进度写入改为同一事务中的删除／插入，并以 updatedAt＋rowid 排序，避免同秒内切回旧 P 后误选另一分集；零／无效进度仍不覆盖有效记录。
- VideoDetailViewModel 替换旧详情 FutureProvider，提供详情与续播快照；UP 信息和简介来自同一详情响应。相关视频以独立 Provider 加载、单独重试，失败不隐藏详情。个人列表入口明确显示尚未开放；远端收藏／稍后再看读写仍属于 M6，不自动发起写操作。
- BilibiliApi 增加列表响应适配，复用既有账号代次、Cookie 范围、WBI、取消与 Talker 脱敏规则。M4 当时的详情 Map 缓存（24 项、三分钟）于 2026-10-25 被 [ADR 0005](0005-scoped-http-cache.md) 的按会话隔离 HTTP 缓存替代；相关视频仍最多显示 20 项。

## TV 与图片约束

首页分类、搜索历史、页尾重试、播放／续播、长分 P、相关视频和简介展开均提供遥控器路径。横向长列表虚拟化，方向键先滚动再定位；播放返回恢复原分集焦点并重新读取本地续播。相关视频返回原卡片。加载结果不会无故抢走当前焦点；仅首次详情就绪定位主播放动作。

CachedNetworkImage 继续提供占位和失败替代。B 站返回的 HTTP／协议相对封面统一转 HTTPS；自定义缓存需混入 ImageCacheManager，支持磁盘缩图。封面内存／磁盘解码目标不超过 640×360，头像内存目标 96×96；磁盘缓存最多 120 个文件、七天未用清理，Flutter 解码图片缓存最多 120 项／48 MiB。网格仅额外构建两行邻近内容，没有无限预加载；这些约束不代表整进程或视频解码内存预算。

系统输入法与 Flutter 测试文本注入分别验收。原生 Gboard TV 的中文候选、方向键／确认输入、Back 收起和再次提交需实际观察；合成 viewInsets 测试只验证受键盘压缩时的布局和焦点，不冒充原生输入法证据。

原生 P2 回归发现媒体装载竞态：`Player.open` 仅完成 loadfile 排队，立即执行 audio-add 时，主文件与 on_load 请求头配置可能尚未就绪。适配器现在等待主文件提供有效 duration（有 20 秒上限）再挂载独立音轨，随后等待首帧；没有加入自动重放、换源或 Cookie 到 CDN。依据已安装 media_kit 1.2.6 的 on_load／setAudioTrack 实现核对，短路径实际 P2 音视频已通过，完整验证单列记录。M2 的 Android 销毁监听与锁排空兼容处理保持原逻辑。

## 固定协议来源

- [PiliPlus video.dart](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/video.dart)：Web 推荐请求参数、相关视频列表。
- [PiliPlus api.dart](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/058794483080f5bf3d760e005118c0bd4698c51b/lib/http/api.dart)：推荐与相关视频路径。
- [固定推荐协议资料](https://github.com/replace5/bilibili-API-collect-mirror/blob/271b123a083698bf576101c21f534b3418768a43/docs/video/recommend.md)：Web WBI 推荐参数及响应形态。

这些是社区协议资料和上游实现，不是 B 站官方稳定性保证。真实请求仅保存字段名、公开内容标识、数量和安全状态；签名、Cookie、二维码和媒体 URL 不进入仓库或 Talker 历史。
