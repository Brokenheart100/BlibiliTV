# M4：内容发现、搜索、详情与分 P

日期：2026-10-24。状态：功能已实现，本机与 API 36 x86_64 Android TV 模拟器核心流程验证通过。继续使用 Riverpod + Freezed + MVVM + 整洁架构、Talker 脱敏日志和深色 iOS 风格。

本次真实服务验收使用游客；没有重新读取、导入或确认个人账号。M3 的账号验收结果保留于原记录。物理 TV／ARM、完整播放器恢复、个人列表写入与发布签名不属于本次完成范围。

## 实现

- 首页区分“为你发现”和热门。游客可获取推荐；鉴权／权限不可用时，第一页降级热门并提示，后续游标固定来源。网络、限流和契约失败显示可重试状态。
- 初始加载、刷新、追加、空结果和局部失败分开展示。初始／追加均去重，重复追加命令不重叠，刷新和新查询取消旧请求；重复游标／连续无新增页停止追加。
- 搜索仅主动提交，编辑／输入法组合阶段不请求。历史按账号保存在既有 Drift v1 表，最多 12 条，可重复使用与清空；同秒提交仍保持正确最近顺序。输入法隐藏期间保留结果 Provider 和分页。
- 详情使用 AsyncNotifier 与 Freezed 状态，增加 UP 信息、可展开简介、最新有效分 P 的续播入口、长分 P、相关视频及局部重试。播放返回更新续播，并恢复原选集焦点；相关视频返回原卡片。
- 个人列表入口明确告知尚未开放，并可前往账号页；没有实施收藏／稍后再看网络写入，实际列表能力仍在 M6。
- 图片有占位、错误替代、HTTPS 规范化、磁盘缩图与缓存上限；仅构建可见及邻近两行内容。配置说明见 [ADR 0004](adr/0004-m4-discovery-and-search.md)。

## 真实设备与服务结果

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| Web WBI 推荐 | 游客返回 12 项混合卡片，仓储仅保留 UGC；本次响应没有 has_more 字段 | [discovery-contracts.json](m4-evidence/discovery-contracts.json) |
| 相关视频 | 数组响应实测 40 项，页面过滤当前视频并最多展示 20 项 | 同上及原生流程报告 |
| 真实连续分页 | 10 页热门，120 条唯一内容；通过遥控器页尾追加 | [native-discovery.json](m4-evidence/native-discovery.json) |
| 真系统中文输入法 | Gboard TV 17.3.11，启用简中，全部通过方向键／确认输入 j i l u、提交候选“记录”、Back 收起后下移并确认搜索 | [native-chinese-ime.json](m4-evidence/native-chinese-ime.json) |
| 中文搜索与历史 | 原生 IME 的“记录”结果已呈现；自动原生流程另以测试输入提交“纪录片”，分页后 36 条唯一内容，新历史仓储从真实 SQLite 恢复关键词 | 原生 IME 报告与原生流程报告分别记录输入方式 |
| 产品入口冷启动 | 默认 `lib/main.dart` 安装包覆盖安装、强制结束并从 TV Launcher 冷启动后，搜索历史“记录”仍存在 | [cold-search-history.json](m4-evidence/cold-search-history.json) |
| 分 P 原生播放 | 公开样本 BV1wR4Xz6EqG，103 P 中选择第二 P，实际 640×360、44.1 kHz 音轨、播放位置超过 3 秒 | [native-discovery.json](m4-evidence/native-discovery.json) |
| 返回与错误 | 播放返回恢复第二 P 焦点与续播入口；相关视频 20 项；无效视频有返回路径 | 同上 |
| 另一条多 P 样本 | BV15b411573D，19 P 中第二 P 实际 640×360、48 kHz；短路径记录只有一页，未冒充 10 页验证 | [native-discovery-short.json](m4-evidence/native-discovery-short.json) |

原生中文输入与自动化原生流程是分段验证：前者关闭 Flutter Driver 文本仿真，真实操作系统候选词；后者明确使用 Flutter 测试文本输入，不据此声称操作了系统中文输入法。临时 Gboard 语言配置已恢复原来的 Use system languages／English (US)，报告记录恢复成功。

![首页推荐](m4-evidence/home.png)

![中文搜索结果](m4-evidence/chinese-search-results.png)

默认产品入口另用公开 BV 号搜索并以方向键选择第二 P，实际画面与播放位置 00:03 如下；本次未进行人工听感验收。

![默认安装包第二 P 实际画面](m4-evidence/p2-playing.png)

## 测试与问题修复

本机完整单元／Widget 回归 **89 项通过**，包含原有 67 项和 M4 新增 22 项。新增覆盖推荐混合卡片过滤、来源降级、分页来源隔离、限流、相关数组、空分 P、封面协议、搜索历史上限与排序／隔离、最新分 P、十页去重与并发、追加失败重试、重复游标、查询 A/B 迟到、中文组合态、输入法布局／焦点、长选集、相关失败与续播。

实际验证修复了以下问题：

1. 推荐封面返回 HTTP 地址，统一转 HTTPS；自定义缩图缓存必须混入 ImageCacheManager，修正后已观察到真实封面画面。
2. Drift DateTime 的同秒记录排序不足，历史与有效进度写入采用事务，新增 rowid 次序作为排序补充，不修改 v1 schema。
3. 多 P 的独立音轨过早挂载。`Player.open` 返回时主文件只完成排队，现等待有效 duration 后再 audio-add。修正前网络 Range 探测均为 206，但原生 audio-add 打开失败；修正后原始 103 P 样本及另一 19 P 样本均播放通过。见 [网络探测](m4-evidence/p2-network-probe.json) 和 ADR 的时序说明。

由于修改触及播放适配器，另外重跑既有 M2 暂停／seek／续播与 20 次切换回归，结果单独写到 [native-playback-regression.json](m4-evidence/native-playback-regression.json)，不覆盖旧 M2 的历史证据。最终静态分析、热重载／运行错误、APK 信息汇总于 [verification.json](m4-evidence/verification.json)。

该回归已通过：22 个引擎全部释放、最大同时存活 1 个、返回后存活 0 个；保存与实际恢复位置均为 13.433 秒，并返回原卡片。

## 重现

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
dart run tool/m4_contract_probe.dart
flutter drive --driver=test_driver/m4_integration_test.dart --target=integration_test/m4_discovery_flow_test.dart -d emulator-5554
flutter drive --dart-define=M4_PLAYBACK_REGRESSION=true --driver=test_driver/m4_playback_regression_test.dart --target=integration_test/m2_playback_flow_test.dart -d emulator-5554
flutter build apk --debug
flutter run -d emulator-5554
```

真实原生测试使用独立 `mambatv_m4_validation` 数据库与显式游客 Session；播放回归使用独立 M2 验证数据库。测试代码仅清理各自的验证库；产品入口另外验证了覆盖安装与强制结束进程后的历史恢复。`tool/m4_app.dart` 仅为 Flutter MCP 开启开发 Driver，默认产品入口仍为 `lib/main.dart`。最终已构建、覆盖安装并启动该默认入口的 Debug APK，摘要见 [debug-apk.json](m4-evidence/debug-apk.json)。

## 后续边界

登录后的个性化推荐当前依赖已完成的 M3 身份绑定与合成契约验证，本次没有使用真人账号重新验证推荐排序。相关视频与搜索随服务变化，不保证固定内容排序。缓存的 48 MiB 限制只针对 Flutter 解码图片，不代表进程总内存；性能 P95、长时播放、物理电视解码器、系统休眠和正式签名仍待 M5/M7。播放器换源、画质、倍速、自动下一 P 与音频焦点由 M5 继续；远端个人列表由 M6 继续。
