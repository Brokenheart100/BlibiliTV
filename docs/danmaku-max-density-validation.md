# 仅弹幕／最高密度专项验证

日期：2026-10-28。本轮按用户要求暂停字幕验收，只测试当前 Better Player／Media3 的只读弹幕。源码是在 `af884a5` 上的工作区增量。

## 固定条件

- 字幕关闭，不创建合成字幕 fixture；字幕 Repository 的轨道和正文调用数必须为 0，画面不得出现字幕控件。
- 当前最高密度档为 **40 条**，覆盖区域设为 **100%**。测试容器覆盖负载策略，禁止 40→20→10 自动降档；正式应用默认仍保留负载保护。
- 官方 `canvas_danmaku 0.3.3` 保留轨道避碰和对象数上限。最高档是准入上限，不等于每一帧强行画满 40 条；报告另记长播期间的实际在屏峰值和均值。
- 真实公开弹幕叠加每媒体秒 20 条合成输入，模式包含滚动、顶部和底部。合成输入有 20 个重复文本，结果代表该混合负载，不能当作全部不同长文本的极限。视频 `BV1wR4Xz6EqG`，连续播放及自然换 P，不做新的账号登录或远端写入。
- API 36 x86_64、`Mamba_TV_API36`／`emulator-5556`、1920×1080、density 320，复用运行中的本项目 AVD。本轮 ADB 仅检测到这一台模拟器；测量期不并行构建或跑整套测试。

## 验证规则

先做 2 次进入／退出，再在相同位置、解码配置、隐藏控制条条件下比较“弹幕关闭”和“仅弹幕”。各预热 18 秒、采样约 10 秒，保持 build／raster P95≤16.7 ms、相对关闭 raster P95 增量≤3 ms 的原门槛。

随后单独计满 **900 秒**。每 500 ms 左右检查活动调度器的密度必须为 40，降密度次数必须为 0，字幕请求必须为 0；每分钟验证原生进度、画布绘制时钟及新弹幕继续推进。长播实际在屏峰值必须达到 40，退出时引擎、覆盖层、调度器和字形缓存归零。任何性能门槛失败仍保留失败状态，不靠降密度通过。

## 初始化问题修复

首轮仅弹幕短窗口 raster P95 为 2.931 ms，密度为 40，但严格检查发现仍请求过一次字幕轨道，因此没有进入长播，报告保留为 [fixed40-rejected-subtitle-prefetch.json](m8-performance-evidence/fixed40-rejected-subtitle-prefetch.json)。它不是有效的完整验收。

原因是异步偏好未加载时，覆盖层先使用默认的“字幕开启”配置。现改为等待偏好加载完成后创建覆盖层；新增 Widget 测试检查等待期间没有字幕或弹幕请求，加载“字幕关闭”偏好后只请求弹幕。这不会改动字幕内容、时序或样式功能。

修复后 **255 项 Flutter 测试**、Flutter MCP 分析、`flutter analyze --fatal-infos` 和格式检查通过。

运行截图见 [fixed40-soak.png](m8-performance-evidence/fixed40-soak.png)。底部原片自带的文字属于视频纹理内容，不是本应用加载或绘制的字幕。当前源码与 profile APK 的指纹见 [fixed40-build.json](m8-performance-evidence/fixed40-build.json)。

## 结果

**连续运行及密度约束通过，持续帧性能暂不验收通过。**

- 连续段计满 900 秒，累计媒体推进 **899.833 秒**；报告含清理的总计时为 902 秒。第 436 秒自然切到第二 P。
- **1740 次**活动调度检查全部保持最高 **40 档**，实际在屏峰值 **40 条**、采样均值 **38.73 条**；覆盖区域 100%，降档 **0 次**、自动停用 **0 次**。
- 字幕轨道／正文请求 **0**，原生错误 **0**，远端写入 **0**。5 个原生引擎全部释放，覆盖层创建／销毁 6／6，退出后引擎、覆盖层、采样器和字形缓存均为 0。

| 正式 A/B | build P95 | raster P95 | raster P99 | 帧数／窗口 |
| --- | ---: | ---: | ---: | --- |
| 弹幕关闭 | 0.767 ms | 3.655 ms | 12.916 ms | 559／10.032 秒 |
| 仅弹幕、固定 40 档 | 1.399 ms | 3.534 ms | 4.681 ms | 600／10.033 秒 |

短窗口满足原预算，但**不能推广为整段 15 分钟帧性能通过**。原报告末尾 4096 帧 raster P95 为 **17.627 ms**；复核发现该字段还包含退出／返回首页的帧，因此不能作为精确的纯播放末段 P95。

独立的覆盖层稳态记录排除了控制条和预热，并在实际播放时按 120 帧一个窗口记录慢帧。900 秒采样保留的最后 64 个窗口，超过 **16667 微秒（约 16.7 ms）**的帧占比均值为 **21.00%**，最高 **29.17%**；更早多次分钟采样也持续偏高。这说明长播慢帧确实存在，不能仅归因于退出动画。

原始报告 [fixed40-danmaku-native-15-minute.json](m8-performance-evidence/fixed40-danmaku-native-15-minute.json) 的 `status=passed` 仅反映原脚本的短 A/B 门槛和连续性断言；它漏检了长播帧预算。原文件保留，独立审计结论 [fixed40-validation-summary.json](m8-performance-evidence/fixed40-validation-summary.json) 明确为 `not-accepted`。

已补充逐分钟 P95 记录和持续帧预算断言，并在退出之前冻结最终帧样本，避免后续重跑出现同样的漏检。这个验收脚本补充发生在此次 900 秒运行之后，只完成静态分析，未再跑第二轮 900 秒；应用生产源码保持与实测 APK 一致，构建指纹中单列该脚本后续变更。

本轮只评价无字幕、固定最高密度的混合负载。与此前组合测试相比，字幕、覆盖区域、降档策略及并存模拟器状态均有变化，不能把成绩差异单独归因于字幕。

## 复现

```powershell
$env:M8_RUN_LABEL='fixed40'
flutter drive --profile --driver test_driver/m8_stability_test.dart --target integration_test/m8_stability_test.dart -d emulator-5556 --dart-define=MAMBA_VALIDATION_APP=true --dart-define=MAMBA_READ_ONLY_VALIDATION=true --dart-define=M8_DANMAKU_ONLY=true --dart-define=M8_FIXED_MAX_DANMAKU=true --dart-define=M8_PRESSURE_DENSITY=40 --dart-define=M8_RESOURCE_CYCLES=2 --dart-define=M8_SOAK_SECONDS=900 --no-uninstall-first --keep-app-running
```

主机驱动从实际报告读取仅弹幕模式，不再依赖重复设置同名环境变量。产物写入 `docs/m8-performance-evidence/fixed40-danmaku-*.json`，失败报告与有效 15 分钟报告分开命名。字幕组合性能、物理 ARM TV 和人工音画验收本轮均不执行。
