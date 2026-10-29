# 搜索类型 Tabs 与导航液态玻璃

后续交互调整（2026-10-29）：按用户要求，点击当前类型或切回已访问类型均刷新第一页／首屏；仅从详情返回仍恢复卡片位置。下文“已分页结果保留”是本轮初始交互快照，以 [详情与刷新记录](detail-layout-and-refresh.md) 为当前行为。

日期：2026-10-29。状态：已实现，295 项本机测试及模拟器界面检查通过；本轮不提交、推送或发布。

## 用户流程

复用现有搜索入口，类型为“视频／番剧／影视／直播”。提交关键词后可切换类型，输入草稿不会在切换时被自动提交；最近搜索仍共享当前账号的关键词历史。空关键词不请求新类型接口。视频保留排序和时长筛选，其他类型不附带视频筛选参数；返回视频时保留筛选。

番剧／影视使用 3:4 竖版海报，以 season_id 打开既有季详情／选集；播放仍验证当前权限。直播使用 roomid 打开既有播放器，显示主播头像和直播中／未开播，未开播条目不创建引擎。不伪造播放数或点播时长。

左右移动类型焦点，确认切换；向下进入结果，最左列向左返回侧栏。选集／直播退出后恢复卡片位置。输入法、历史、刷新和分页失败重试继续可用。

## 架构与隔离

保持 Flutter＋Riverpod＋Freezed＋MVVM／整洁架构。新增 Domain 的 SearchCategory、ContentSearchItem 联合类型和 ContentSearchRepository；Data 负责查询与映射，ContentSearchViewModel 暴露不可变状态和命令。视频保留已有 CatalogRepository／CatalogViewModel，避免复制逻辑。季、房间、BVID 分别处理，不把新类型编号写入普通视频路由。

状态按账号代次、类型和已提交关键词隔离。当前页只持有访问过的类型，新关键词释放旧查询；切类型／后台／隐藏取消请求，取消标志与 epoch 拦截迟到响应。已成功分页的结果在返回类型时保留；类型游标、去重及连续无增量保护避免重复分页。失败保留卡片并允许重试。

## 接口

依据固定参考提交 `affac5334fc41744894618d9fb53b7101db9532a` 的 search.dart／api.dart 定位，复用 BilibiliApi 的账户作用域、签名和错误处理：

| 类型 | GET 路径 | search_type | 结果身份 |
| --- | --- | --- | --- |
| 番剧 | api.bilibili.com/x/web-interface/wbi/search/type | media_bangumi | result[].season_id |
| 影视 | 同上 | media_ft | result[].season_id |
| 直播 | 同上 | live_room | result[].roomid |

参数为 keyword、page、page_size=20、platform=pc。沿用一分钟白名单 HTTP 缓存，键包含类型／关键词／页码，不新增全局缓存规则。按 numPages 分页，仅 numResults=0 时接受缺失 result。v_voucher 风控、类型错误、无效身份和坏数据明确失败，不显示成正常空结果。高亮标签映射为纯文本，图片地址规范化为 HTTPS。

这些是经样本验证的 Web 协议，不是稳定官方 SDK 承诺。公共只读探测命令为 `dart run tool/search_protocol_probe.dart`；[接口证据](search-glass-evidence/interface-spike.json) 仅保留公开 ID、计数与状态，原始响应在本机忽略目录 `.m0/search-glass/`。

## 视觉边界

首页、我的主页、搜索共用 TvCapsuleTabs：外层 LiquidGlassCard，选中胶囊为透明渐变／高光边缘，保留 Cue 弹簧及减少动态效果。左侧栏复用同一玻璃材质，图标按钮使用透明高光，维持选中／焦点边框、Tooltip 和导航顺序。

只使用有边界的 BackdropFilter、静态渐变和圆角；无新依赖、循环动画、逐帧模糊半径或自定义折射着色器。胶囊在父玻璃内绘制，避免叠加全栏模糊；未改变播放器和弹幕绘制，不代表 M8 持续帧性能或 ARM 真机已验收。

## 验证

新增 17 项数据／组件回归，全量 295／295 通过；`flutter analyze --fatal-infos` 无问题，格式检查 298 文件、0 调整，build_runner 生成成功。覆盖旧视频搜索、IME、筛选、导航和既有播放器回归，以及类型／关键词／账号迟到响应、分页失败重试、640×360／960×540 深浅色与减少动态效果。

公共只读接口实测：番剧 11 条、影视 1 条、直播第 1／2 页各 20 条，远端写入 0。API 36 x86_64 `Mamba_TV_API36` 的只读隔离调试包加载四类真实结果；用方向键进入番剧季详情并返回，Flutter MCP 热重载成功，最后未发现运行时错误。已查看截图：[深色番剧](search-glass-evidence/bangumi-dark.png)、[浅色影视](search-glass-evidence/cinema-light.png)、[浅色直播](search-glass-evidence/live-light.png)。

结构化结果见 [验证记录](search-glass-evidence/validation.json)，本机日志在 `.m0/search-glass/`。未测物理 ARM TV／玻璃帧性能，未重跑长播、远端 CI 或发布。影视索引完整分类与直播推荐 -352 仍未解决；搜索属于独立读取路径。历史 M9 的 900 秒与 20 次切换报告保持原样。
