# M9 核心内容验收

2026-10-29 详情增量：视频详情纵向网格与自动续载、Tabs 点击刷新、番剧大封面与真实资料／分组选集完成。深浅主题、遥控器跨范围、Android 单次返回及只读接口验证见 [详情记录](detail-layout-and-refresh.md)；用户选择长评／短评后续再做。

2026-10-29 搜索增量：现有搜索增加视频／番剧／影视／直播 Tabs，并统一 Tabs／侧栏玻璃。类型化状态、接口样本与本轮结果见 [搜索记录](search-types-and-glass.md)。下文保留 2026-10-28 的历史验证范围；其中“关键词搜索待补”不覆盖本次新增能力。

日期：2026-10-28。范围：M9-0 类型化基础、M9-1 PGC、M9-2 基础直播观看。实现已落地，本机基础回归、20 次混合切换、PGC 续播／下一集、900 秒直播和原生控制验证通过；最终 272 项本机回归、静态分析、格式及生成一致性检查通过。未提交、推送或发布；M8 弹幕性能缺口继续保留。

## 工作包状态

| 工作包 | 当前范围 |
| --- | --- |
| M9-0 | 类型化目标／能力／v4 迁移已实现并本机验证 |
| M9-1 | PGC 基础观看已实现；免费真实播放验证，会员与完整搜索／分类仍待补 |
| M9-2 | 基础房间观看已实现；推荐列表 -352；900 秒与原生控制验证通过，物理／人工仍待补 |
| M9-3／4／5 | 投屏／下载／多账号保持后续独立模块，未实施 |
| M9-6 | 本轮核心交叉回归；物理、人工、正式升级、远端 CI 与发布未完成 |

## 已实现

- UGC／PGC／Live 类型化目标、内容能力及唯一引擎；兼容旧 UGC 路由。
- 首页“番剧／影视”、季链接／ID、正片与附加分组选集、焦点滚动与返回恢复；个人追番／追剧直达季详情。
- PGC 完整 DASH、实际 cid 覆盖层、本地续播、同组自动下一集；试看／DRM 拒绝，不发送远端 UGC 心跳。
- 首页直播页、房间号／链接直达、短号解析、HLS／AVC、清晰度；无虚假进度／倍速，暂停／后台释放，恢复重取源，有限重连。
- Drift v4 类型化历史；直播只记访问；v1／v2／v3 实际迁移与账号／内容类型隔离。

## 接口证据

[公共只读报告](m9-evidence/interface-spike.json) 由 `tool/m9_protocol_probe.dart` 生成。游客、零远端写入：番剧索引 24 项；季 28320 有 22 集正片、2 个附加分组；280924 返回完整 DASH，285889 为会员试看并拒绝；直播短号 6→7734200，HTTPS HLS 清单实际可读。

直播推荐接口返回 -352，因此发现列表未完成真实验收，页面明确报错并保留直接打开入口。目录关键词搜索、完整影视分类、账号专属会员内容、地区／下架真实样本未验收；权限、下播、受限、协议和坏数据由合成契约补充，不能冒充真实账号结果。

## 本机与原生验证

本机覆盖类型化路由／能力、真实响应结构、权限拒绝、HLS 主机限制、三代迁移、头像保留、内容与账号隔离、附加分组序列、长列表遥控、三次重连预算、后台取消和不显示接口缺失的观看次数。最终 **272 项**全量通过（含既有 255 项）；静态分析无问题、285 文件格式无变化、47 个生成文件二次生成不变、13 项流水线守卫及依赖许可清单通过，见 [本机检查](m9-evidence/local-checks.json)。

原生使用 API 36 x86_64 `Mamba_TV_API36`／`emulator-5556`、Better Player／Media3、profile；隔离包 `app.mamba.mambatv.validation`、独立验证库和游客会话，不改原应用数据。关闭字幕与弹幕，独立验证 M9 内容链路，不替代 M8 最高密度弹幕验收。

首轮在混合切换第 15 次遇到 HLS 分片 404，被旧分类误判为不支持，未自动重连。保留 [原始失败报告](m9-evidence/rejected-native-before-cdn-fix.json)，已补 404→线路故障分类及回归，再跑完整原生流程。允许明确记录的可恢复线路错误；每次进入仍须实际原生播放／尺寸／位置，长播仍检查时间推进和卡死。

原生脚本 `integration_test/m9_content_test.dart` 依次执行 20 次 UGC／PGC／直播切换、PGC 暂停／seek／续播／自然下一集／权限拒绝、直播释放／恢复和 900 秒长播；检查最多一个引擎、退出归零、远端写入为零。[成功报告](m9-evidence/native-validation.json)：20 次切换、900 秒、1743 次位置变化、25／25 引擎释放、最多 1 个、应用收到的原生错误与远端写入均为 0；PGC 续播误差 0 ms，下一集 285888，试看未创建引擎。

MCP 实际界面检查通过：首页进入番剧索引、输入季编号打开选集页、直播页展示风控错误且保留直接输入；空闲页面热重载成功，无 Flutter 运行时错误。索引未提供观看次数，因此内容卡片不显示虚构的零观看数；普通 UGC 保留原样。截图在本机忽略目录 `.m0/m9/`。

## 尚未验收与延期

[原生控制报告](m9-evidence/live-controls-passed.json)另验证 150→250 实际档位变化，Flutter 生命周期 inactive／paused／resumed 驱动真实引擎释放及显式恢复，3／3 引擎释放，零远端写入。首轮 250 请求实际回到 150 而未通过，见 [原始失败](m9-evidence/live-controls-failed.json)；已补服务端降档说明与合成回归，未把回退当作切到更高档成功。此生命周期测试不是实物遥控器的 Home／休眠验收。

物理 ARM TV、人工声音／口型、PGC 真实会员账号、直播推荐解除风控、真实网络中断／CDN 备源切换、直播其余清晰度与长时弱网仍待补充。直播重连／后台取消的合成测试及本轮原生生命周期验证不等于这些真实条件全部通过。未执行正式证书设备覆盖升级或新一轮托管 CI。

投屏、下载、多账号、直播聊天室为后续独立模块。M9 核心实现与部分本机／模拟器验证不等于全部 M9 或发布验收完成。

## 复验命令与快照

生产输入及 profile APK 摘要见 [快照](m9-evidence/production-snapshot.json)，对应含 M8／M9 未提交改动的工作区，不能仅凭 baseCommit 复现新功能。原始运行日志与签名媒体地址留在忽略目录 `.m0/m9/`；公开报告只含 ID、计数与安全错误类型。

```powershell
flutter test --concurrency 2 --reporter expanded
flutter analyze --fatal-infos
flutter drive --profile --driver test_driver/m9_content_test.dart --target integration_test/m9_content_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --no-uninstall-first --keep-app-running
flutter drive --profile --driver test_driver/m9_live_controls_test.dart --target integration_test/m9_live_controls_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --no-uninstall-first --keep-app-running
```

Flutter build／test／drive 顺序执行，原生长播期间不热重载或重启播放器；收尾在空闲调试页面执行 MCP 热重载。模拟器端不使用墙钟累计冒充媒体推进；HLS 原生位置会随滑动窗口重置，因此长播检查持续位置变化与最长停滞，同时保留每分钟原生采样，不要求点播式单调时间。
