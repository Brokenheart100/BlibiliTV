# 我的主页与侧栏历史记录

日期：2026-10-27。

「我的」登录后显示真实头像、昵称、UID，以及「我的投稿／收藏夹／追番／追剧／稍后再看」栏目。投稿只显示空间里公开发布的内容，可进入现有视频详情与播放流程；收藏夹显示封面和数量，可进入夹内视频。追番和追剧显示竖版封面、名称、更新信息，确认后可查看观看进度及会员标识。本次交付列表与只读详情，PGC 正式播放仍未接入。

侧栏时钟图标「历史记录」位于第二位，提供本地观看与 B 站历史两个栏目，沿用已有续播、分页和个人列表能力。路由分支标识保持不变，显示与遥控器顺序统一为发现、历史记录、搜索、我的、设置。游客仍可查看本地记录，账号列表提供登录提示。

## 架构和隔离

新增 PersonalHomeRepository、独立个人内容领域模型，以及 Riverpod／Freezed 的 PersonalCollection ViewModel。投稿和收藏复用已有 CatalogRepository／LibraryRepository；追番和追剧使用独立 PersonalSeason，不将 season_id 伪装成 UGC 视频 BV 号。

头像通过当前身份的 `/x/web-interface/nav` 读取，核对返回 mid 与当前账号，图片使用 HTTPS 与已有封面缓存。追番／追剧核对参考项目 [PiliPlus FavHttp](https://github.com/bggRGjQaUbCoE/PiliPlus/blob/main/lib/http/fav.dart) 的 `/x/space/bangumi/follow/list`，分别使用 type=1／2、当前 vmid 和 pn；响应字段核对其 FavPgcData／FavPgcItemModel。接口是现有 Web 协议适配，不是第三方稳定性承诺。

个人资料和列表没有加入普通内容 HTTP 缓存白名单。Provider、页面实例和焦点记忆都包含账号会话代次；账号变化取消旧请求并重建页面。列表分页去重、无新增时停止；单独刷新失败保留当前账号已有内容。收藏夹详情在账号变化时清除旧夹 ID。

首页现有视频网格提取为通用 TvItemGrid，复用同一套遥控器、惰性构建、滚动、分页与焦点恢复；TvGrid 保持原调用接口。个人视频复用带作者头像的 TvVideoCard；收藏夹和剧集保留独立卡片，剧集展示竖版海报。卡片统一液态玻璃表面，五个栏目复用首页胶囊 Tabs。深浅主题沿用现有上下文配色，详见 [卡片与导航调整](glass-cards-and-navigation.md)。

## 验证

完整本机 **236 项测试通过**，Flutter MCP 分析无诊断，格式检查通过。新增仓储、ViewModel 和组件用例覆盖头像身份校验、本人投稿、收藏夹、追番／追剧类型和分页、退出后不残留旧内容、旧请求取消、历史入口与返回焦点，以及 640×360／960×540 布局。

用户扫码确认后，在 API 36 x86_64 TV 模拟器以只读验证包验收通过：头像实际渲染；投稿首两页各 30 条；收藏夹 17 个、一个非空夹内读取到 4 个视频；追番与追剧首两页各 15 条，分页重叠均为 0；B 站历史首批 24 条。这里均为当次页采样数量，不代表内容总数。稍后再看当次为空，正常显示空态。远端账号写请求为 **0**。

模拟器完成收藏夹进入／返回、追番／追剧网格、历史记录展示、界面重启后的登录恢复；Flutter MCP 热重载／热重启成功，无应用运行时异常。真实资料、头像、UID 和私人列表截图仅用于本机检查，不写入验收报告；脱敏报告见 [account-readonly.json](personal-home-evidence/account-readonly.json) 与 [validation.json](personal-home-evidence/validation.json)。物理电视、ARM 本轮未验证；未发布或推送。
