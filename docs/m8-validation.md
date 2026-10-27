# M8：字幕、只读弹幕与内容发现验收

日期：2026-10-26。基线提交 `7eef332cc19caad9759b760a05bcd1bd4011be38`，本轮为未提交的 M8 工作区增量。**结论：必交功能已实现，本机回归和真实账号只读检查通过；持续弹幕性能未通过，M8 尚未完成验收。** 详细范围见 [总开发计划第 11 节](development-plan.md#11-m8m9详细开发计划)，实现决策见 [ADR 0010](adr/0010-m8-media-overlays-and-discovery.md)。短测不列为完整验收。

## 实现范围

- UGC 字幕：可用语言／AI 轨、自动选择、关闭／切换、字号、底部安全区、±5 秒偏移（正值延后）；重叠 cue 最多两行，样式变更不重新请求轨道。独立字幕选择随播放器路由保留，切画质释放旧引擎时仍保留同分 P 的选择。
- 只读弹幕：默认关闭，支持滚动／顶部／底部、区域／透明度／字号／密度／本机关键词，媒体时间调度、seek 清空、窗口取消与淘汰、低负载降级；不提供发送或互动入口。
- 内容发现：详情 UP 按钮进入公开视频页，最新／最多播放排序；首页关注分页及游客登录回跳；搜索排序／时长的显式应用与重置；设置页的全局观看增强默认值。
- 分层继续使用 Riverpod＋Freezed。领域契约与数据解码隔离，正文 URL 仅驻留 Data；偏好使用独立键，Drift 保持 v2。点赞／投币按既定可拆分边界延期，M9 未实施。

## 证据与方法

| 检查 | 当前证据与边界 |
| --- | --- |
| 公开协议 | `m8-evidence/interface-spike.json`：实际元数据／分段解析，不保存签名 URL 或内容正文 |
| 登录账号只读 | `m8-evidence/real-readonly.json`：176 cue、三组弹幕／UP 列表、关注首屏及下一页、筛选搜索通过；remoteWrites=0 |
| 真实画面 | `m8-evidence/real-overlay-menu.png`、`real-subtitle-frame.png`，在原生视频上看到字幕并操作菜单 |
| 分层与回归 | 切回官方画布后 202 项 Flutter 单元／Widget 测试、`flutter analyze --fatal-infos`、13 项 Python 守卫、锁文件验证、依赖许可清单和 actionlint 均通过。37 份生成文件重复生成无变化的既有记录见 `generation.json`；新远端 CI 尚未运行 |
| 原生 profile | 最终 1080p 冷启动／20 次进出通过，退出后引擎及覆盖层／采样器归零；A/B 期间弹幕自动暂停，原断言拒绝，未进入 900 秒连续压力。见 `native-final-summary.json`／`rejected-final-retained-cap.json` |
| 官方画布单独弹幕 | 官方 `canvas_danmaku 0.3.3` 已构建并在 1080p TV 模拟器运行。20 条／秒合成压力下自动暂停，见 `danmaku-rejected-native.json`。仅公开真实分段在原两窗口保护下中途暂停，见 `danmaku-real-rejected-two-window.json`；延长最低密度观察期后，A/B 窗口未暂停，但 raster P95=17.514 ms 超过 16.7 ms，见 `danmaku-real-rejected-native.json`。三次均未进入完整 900 秒验收 |
| ARM 候选 | `1.1.0+2` ARM32／ARM64 正式签名本地测试候选构建、包名／ABI／版本／签名核对通过；共 11 份资产，位于 `.local/m8-candidate/`。它在切回官方画布之前构建，已与当前源码不一致；元数据 `releaseQualified=false`，见 `arm-candidate.json`。未创建新公共 Release |

真实账号恢复沿用已存在登录与只读授权，未发起新扫码或远端操作。旧 `5554` 是另一个项目的 `Mamba_TV_Verify_API36`，报告中的设备时钟落后主机，原 recordedAtUtc 原样保留。完成该检查后仅停止本项目包，没有修改该 AVD／账号数据。完整稳定性使用本项目 `Mamba_TV_API36` 在 `5556` 冷启动；不加载或保存旧 snapshot，不 wipe 数据。

原生压力用独立 `.validation` 包、游客内存会话和 M8 专用数据库，编译期启用只读写入守卫。字幕为两轨合成 fixture，弹幕为真实公开分段叠加每媒体秒 20 条合成输入；它们证明时序与负载，不替代多轨真实字幕／真实账号压力。每次进入／返回检查引擎和覆盖层释放，最多一个引擎。15 分钟过程中不同时运行构建或全量测试。

A/B 使用相同视频位置、解码配置和隐藏控制条的稳态，分别全关／字幕／字幕＋弹幕；frame policy 为 fullyLive。记录帧数、P95／P99、超 16.7 ms 比例，原目标保持 build／raster P95≤16.7 ms、弹幕相对关闭 raster P95 增量≤3 ms。字幕时序读取画面 cue 和原生 time-pos，误差上限 250 ms；纯领域索引另测边界与重叠。媒体累计推进与 Stopwatch 差值上限仍为 30 秒，不用脚本运行时长替代有效播放。

## 原生性能结论

以下为切回官方包之前的本地补丁源码（包含画布保留对象硬上限）在 API 36 x86_64、host GPU、1920×1080／density 320 下的结果。预先构建 APK、冷启动本项目 AVD，停止本项目闲置 Gradle 进程，不同时进行构建或额外 timeline 追踪。该历史源码及 profile APK 摘要见 `source-manifest.json` 和 `native-final-summary.json`。

| 对照 | build P95 | raster P95 | 结论 |
| --- | --- | --- | --- |
| 全关 | 0.497 ms | 3.529 ms | 该窗口通过 |
| 仅字幕 | 0.609 ms | 13.987 ms | 该窗口通过 |
| 字幕＋弹幕 | 0.485 ms | 4.421 ms | **无效的弹幕性能成绩**：弹幕已自动暂停一次，必须拒绝 |

20 次进出全部退出后 liveEngines=0；测试清理后覆盖层 created=disposed=22、active=0、activeSchedulers=0、maximum=1。它们证明资源生命周期回归通过，不证明持续弹幕达标。

另一次修复前的 1280×720／density 213 对照在短窗口通过（raster P95 3.958／4.513／6.894 ms），随后约两分钟连续播放期间仍自动暂停，见 `rejected-720p-continuous.json`。该次 0.5／1／2 倍速 seek 后的三次可见字幕采样均落在对应 cue 内；样本有限，不代表全程同步。720p override 已恢复，最终复验仍为原生 1080p。

原版库、离屏透明合成、picture-cache、Skia、30／15 fps 调度及无并行构建的排查记录保留。当前应用依赖已回到官方 Pub 包，本地补丁不参与构建；`source-manifest.json` 是回退前的历史源码摘要，不能用作当前构建指纹。新包锁定的 SHA256 见 `pubspec.lock`。当前尚未确定单一根因，不能直接归咎模拟器或推断 ARM 真机会通过。没有有效的 `native-15-minute.json`；`native-smoke.json` 仅是此前一次带额外追踪条件的 60 秒短测，不能据此关闭性能问题。

## 发现并处理的问题

1. isolate 闭包曾隐式捕获 Repository／Dio，在 Android 抛出不可发送对象异常。改为顶层仅字节参数解码，真实 176 cue 正文复验通过。
2. 首次短测在旧模拟器出现约 60 秒 Stopwatch 对应 111.2 秒媒体推进，按原断言拒绝；保存 `rejected-smoke-clock.json`。后续改为本项目冷启动 AVD 并使用 fullyLive，时钟复测恢复一致；两项条件同时改变，未宣称已确定单一根因或修复 M7 的人工音画问题。
3. 原覆盖层第二个 vsync ticker 对仅字幕场景也持续触发渲染；改为有界 50 ms 时间轴采样并隔离视频／文字绘制。`baseline-overlay-smoke.json` 保留优化前结果。
4. 短测“每分钟有新增弹幕”不足以证明持续压力，自动暂停后仍可能蒙混通过；补充整段 disabledTransitions 不增加的断言。性能对照窗口先等控制条隐藏，持续降级统计排除菜单／控制条动画。
5. Flutter attach／热重启必须保留只读 dart-define。开发探测入口缺该标记会直接拒绝；此运行期检查不替代产品网络写入守卫。最终源代码经 Flutter MCP 热重启成功，随后只读探测通过、运行期错误为零，见 `mcp.json`。
6. 媒体时间推进时，画布动画／清理可能落后。仅限制“尚未到期的准入时间”会使降级后的实际对象数量超限；增加库中保留对象的硬上限，并补充模拟慢画布的 Widget 回归。手动调整密度会重新设置官方库的面积／字号等选项；旧补丁的库内帧率档位已移除。这个修复不能单独证明持续性能通过。
7. 原有最低密度两次短窗口就暂停弹幕，公开真实分段中也会被模拟器短时卡顿误触发。现在仍以 raster >16.7 ms 和单窗口慢帧占比 >10% 判定过载；40／20 条档位连续两个坏窗口降密度，最低 10 条连续 15 个坏窗口才暂停。A/B 的 raster P95≤16.7 ms 门槛未改；最新仅弹幕实测未通过该门槛。

## 重现

先以 `adb -s <serial> emu avd name` 确认归属；不要假设 5554 属于本项目。使用工具链固定版本，构建／测试串行执行。

```powershell
flutter pub get --enforce-lockfile
dart run build_runner build
python tool/proto/generate.py
dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
flutter analyze --fatal-infos
flutter test --coverage --concurrency 2 --reporter expanded
python -m unittest discover -s tool/ci -p 'test_*.py' -v
python tool/release/dependencies.py --check
flutter drive --profile --driver test_driver/m8_stability_test.dart --target integration_test/m8_stability_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --no-uninstall-first --keep-app-running
```

短测可额外设 `M8_SOAK_SECONDS=60`／`M8_RESOURCE_CYCLES=2`，报告明确区分短测和 900 秒结果。仅弹幕诊断再加 `M8_DANMAKU_ONLY=true`，只用公开真实分段时加 `M8_SYNTHETIC_PER_SECOND=0`，并在驱动进程设置同名环境变量以分开命名报告。失败报告分别写入 `rejected-native.json`、`danmaku-rejected-native.json` 或 `danmaku-real-rejected-native.json`；原始本地日志位于被忽略的 `.m0/`，不提交私人内容。

## 尚未验收

2026-10-27 连续性修复：后续准入仅按画布实际接收数量限流；降密度不再整屏清空，最低 10 条档位不再自动停用。上文第 7 项的“连续 15 个坏窗口后暂停”是修复前策略，已被替换。时间轴另修复回调延迟误判跳转；详见 [弹幕连续性修复](danmaku-continuity.md)。性能门槛与历史失败报告不改，连续性改善不代表下述 M8 压力阻塞项通过。

**M8 必交阻塞项**：弹幕单独 A/B 已在原 raster P95 门槛失败；字幕和弹幕同时启用的 900 秒原生压力亦未验收。下一步以最小“原生视频纹理＋画布”复现定位 raster 等待／绘制负载，优化渲染后重跑相同 A/B、20 次进出和 15 分钟；门槛保持不变，不能靠关闭弹幕或扩大阈值通过。若新增设备对照，需独立记录设备结果，保留当前 API 36 失败。

本地测试候选采用原正式证书，ARM32 versionCode=1002、ARM64=2002，证书 SHA256 为 `e65f1bd643af9093c491fe0880bb875c2d46a400e92a317b15f9eb527c694183`。仅完成构建和离线包校验，没有安装到物理 ARM TV；正式身份的设备升级也未验收。候选有签名不代表获得性能或发布验收资格。未提交、推送、创建新标签或运行新远端 CI。

物理 ARM TV、实际遥控器、人工字幕清晰度／听看口型、多轨真实字幕、权限受限字幕、自然凭据续期及真实写入仍待补。自动 avsync 数值只是原生指标；即使本轮正常，也不构成人工音画通过。正式身份的实际设备覆盖升级与独立介质密钥备份没有新验收证据。M9／可选点赞投币均不列为已交付。
