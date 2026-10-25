# 安装、版本与发布候选包

当前包名 `app.mamba.mambatv`；最低 Android API 24。应用以 Android TV／盒子和遥控器为目标，不提供触屏手机适配保证。

## 选包

| ABI | 选择依据 | 当前设备证据 |
| --- | --- | --- |
| arm64-v8a | `adb shell getprop ro.product.cpu.abi` 为 arm64-v8a | 构建／打包检查；物理 ARM 待验证 |
| armeabi-v7a | 32 位 ARM 设备，检查设备的 abilist | 构建／打包检查；物理 ARM 待验证 |

公开 Release 仅提供以上两种 ARM 包。`x86_64` 保留在 Actions 的 Debug artifacts，供本项目 Android TV 模拟器验证。选包以系统的 `ro.product.cpu.abilist` 为准；64 位 CPU 也可能运行 32 位 Android 系统。

先核对来源、`SHA256SUMS`、包名、版本、ABI 与公开签名指纹。Debug 使用开发证书；M7 的一次性测试签名 Release 用于合成验收，不是供用户持续升级的发行渠道。

## 安装与升级

```powershell
adb devices -l
adb -s <device> shell getprop ro.product.cpu.abi
adb -s <device> shell getprop ro.product.cpu.abilist
Get-FileHash -Algorithm SHA256 <apk-path>
adb -s <device> install -r <apk-path>
```

`-r` 保留应用数据；要求同包名和兼容签名；正式发行递增 versionCode，开发期可以同版本覆盖测试。遇到签名不一致，先核对现有安装与新包的来源和证书，不使用卸载作为自动修复；卸载会清除本机观看记录、偏好和账号。

当前源版本为 `1.0.0+1`。后续正式发布统一更新 pubspec 版本并递增 build number，标签精确匹配版本名；不要反复沿用相同 versionCode。公开 ARM 包的实际 code 分别为 1001（armeabi-v7a）和 2001（arm64-v8a）；以同批构建元数据为准。开发用 x86_64 的偏移为 4000 加基础 build number。

主应用与验证包分开安装。原生测试需要同时加 `MAMBA_VALIDATION_APP=true`、`--no-uninstall-first` 和 `--keep-app-running`；不得因 drive 的默认卸载行为破坏主应用数据。

## 首次使用与数据

- 游客可以发现、搜索和播放可用公开视频，本地记录按游客身份保存。
- 扫码由用户在手机确认。账号凭据保存在 Android 安全存储，本地进度、搜索按账号隔离。
- “我的 → 观看记录与个人列表”进入历史、收藏与稍后再看；设置可以管理偏好、缓存和许可文本。
- 观看进度同步默认关闭；只有明确开启才向当前账号提交心跳。收藏／稍后再看由明确操作触发，结果待确认时只重查，不重复提交。
- 清理临时缓存保留账号、偏好与观看记录。断网可读取本地记录；在线播放仍需要网络，不提供离线下载。

## 发行前复核

使用持续保管的正式签名密钥配置 [CI/CD](../ci-cd.md)，后续升级始终保持同一签名身份。当前发布已获维护者授权；目标物理 TV、人工音画同步和真实账号写入尚未验收，下载前请阅读 [已知限制](known-limitations.md) 和 [M7](../m7-validation.md)。原生依赖的许可及对应源码见随包声明与 sources.md。
