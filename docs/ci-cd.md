# CI/CD：GitHub Actions 与 Android APK 发布

2026-10-29 本轮：修复移除 media_kit 后原生许可测试的旧断言，候选版本采用 `1.1.0-rc.1+3`／`v1.1.0-rc.1`。先通过 master 的托管 CI，再推送同一已通过提交的标签，由现有流程重新检查、签名并发布 Pre-release。签名身份保持不变；物理电视与人工播放验收边界不因 CI 通过而改变。

日期：2026-10-25。仓库 `Brokenheart100/BlibiliTV`，默认分支 `master`；仓库 ID 与原 `Brokenheart100/mambatv` 相同，本地远端已更新为新地址。应用与工作流提交 `c7f0c9226376e49c083f15af17daa9a47936a5f9` 的[首次托管 CI](https://github.com/Brokenheart100/BlibiliTV/actions/runs/40179970843)已通过：工作流检查、质量检查和 Android APK 构建全部成功，覆盖率与三架构 Debug APK 已上传。本次没有创建 tag 或 Release；自动打包不等同于 M7 真机／正式发布验收。验证结果见 [ci-cd-validation.json](ci-cd-validation.json)。

## 流程与触发

```mermaid
flowchart TD
    A[PR 或推送 master] --> B[工作流语法检查]
    B --> C[依赖锁定 / 代码生成 / 格式 / 分析 / 测试]
    C --> D[三个 ABI 的 Debug APK 与校验文件]
    E[推送 v* 标签或手动选择现有标签] --> F[标签版本与 master 历史校验]
    F --> G[对该提交完整重跑 CI]
    G --> H[正式密钥签名构建两个 ARM APK]
    H --> I[包名 / 版本 / ABI / 证书 / SHA256 校验]
    I --> J[创建草稿并上传全部资产]
    J --> K[发布 GitHub Release]
```

| 入口 | 行为 | 签名／写权限 |
| --- | --- | --- |
| 任意 PR，包括 fork | actionlint、流水线守卫测试、Flutter 检查与 Debug APK | 无发布密钥，仓库只读 |
| 推送 `master` | 同上，生成可下载的 Actions artifacts | 仓库只读 |
| 手动运行 CI | 检查当前选择的提交 | 仓库只读 |
| 推送 `v*` tag | 检查既有 tag 与版本；完整 CI 后签名并发布 | 构建步骤读取签名 Secrets；仅发布 job 为 contents:write |
| 手动 Release Android | 从 `master` 发起，填写已存在的 tag；不创建 tag | 与 tag 发布相同 |

工作流：[CI](../.github/workflows/ci.yml)、[Release Android](../.github/workflows/release-android.yml)。复用同一个 CI，通过预检输出的确切提交 SHA 构建；手动发布也不会误用当前分支代码。tag 指向的提交必须属于 `origin/master` 历史。

同一个 PR 的旧运行自动取消；发布按 tag 串行，不取消正在签名／上传的运行。发布不覆盖已有 Release；若上传中断留下草稿，先检查并处理草稿再重跑，流水线不会自动删除或替换历史安装包。

## 工具链与检查

唯一工具链清单是 [toolchain.json](../tool/ci/toolchain.json)：Flutter 3.47.5 stable、框架修订 `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`、Dart 3.13.4、Temurin JDK 21、Android API 36、Build Tools 36.0.0、NDK 28.2.13676358；Gradle 9.3.1 使用官方分发 SHA256。官方 stable 的框架修订与本机自定义分支所指提交一致。Windows 本地构建使用 JDK 25；Ubuntu 24.04／Temurin 21 的托管构建也已单独通过，并非用本机结果代替。

直接引用的 Actions 固定完整提交 SHA，版本注释用于人工升级。Flutter／Pub／Gradle 使用缓存，Gradle 仅允许 `master` 写缓存；依赖仍通过 `flutter pub get --enforce-lockfile` 校验，不以缓存代替锁文件。

检查顺序：

1. actionlint 1.7.12 验证工作流；Python 标准库测试验证发布守卫。
2. 还原锁定依赖，运行 `build_runner` 和独立的 `python3 tool/proto/generate.py`。已有生成文件出现 diff 或新增生成文件未提交即失败，覆盖 Riverpod、Freezed、JSON、Drift 和 protobuf 的 pb／pbenum／pbjson 三类文件。protoc 36.2 的官方下载校验和与 protoc_plugin 25.0.0 均固定，Windows／Linux 生成走同一 schema 与 zip 提取路径。
3. `dart format --output=none --set-exit-if-changed`、`flutter analyze --fatal-infos`、`flutter test --coverage`。
4. 从默认产品入口 `lib/main.dart` 构建拆分 Debug APK，校验产物；覆盖率保留 14 天，Debug APK artifacts 保留 14 天。

Flutter 会在干净检出时补充被模板忽略的 Gradle wrapper 脚本／jar；不在工作流提前对不存在的 `android/gradlew` 执行 chmod。Gradle 分发校验和已写入 wrapper properties，setup-gradle 同时检查已存在的 wrapper jar。

默认 CI 不访问 B 站账号、不扫码、不读取本机安全凭据，也不运行依赖外部媒体和人工听感的 TV 测试。M5 的模拟器与人工边界继续见 [M5 验收](m5-validation.md)。M7 按用户要求完成 15 分钟模拟器稳定性与临时证书升级验证；真实 TV／ARM 和人工音画验收仍待完成。

## 配置正式签名

首次发布使用维护者授权生成的长期签名密钥，保存在仓库外并限制本机访问权限；正式密钥配置到以下 GitHub Actions Secrets，后续发布复用：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | 正式 JKS／PKCS12 文件的 Base64 内容 |
| `ANDROID_KEYSTORE_PASSWORD` | 密钥库密码 |
| `ANDROID_KEY_ALIAS` | 用于发布的 alias |
| `ANDROID_KEY_PASSWORD` | 对应私钥密码 |

已经有发布密钥就继续使用；不要为每次构建重新生成。后续安装升级需要保持签名身份一致。若尚无密钥，可以自行执行 keytool 并交互输入密码，路径应在仓库之外：

```powershell
keytool -genkeypair -keystore D:\private-keys\mambatv-release.jks -alias mambatv -keyalg RSA -keysize 4096 -validity 10000
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\private-keys\mambatv-release.jks')) | gh secret set ANDROID_KEYSTORE_BASE64 --repo Brokenheart100/BlibiliTV
gh secret set ANDROID_KEYSTORE_PASSWORD --repo Brokenheart100/BlibiliTV
gh secret set ANDROID_KEY_ALIAS --repo Brokenheart100/BlibiliTV
gh secret set ANDROID_KEY_PASSWORD --repo Brokenheart100/BlibiliTV
```

后三条命令交互录入值，不把密码写到命令历史或文档。Base64 是编码，仍须按秘密保管。CI 将密钥独占写入 runner 临时目录，仅向 Gradle 构建步骤注入必要环境变量，`always()` 清理临时密钥；产物只上传 APK、公开证书指纹和构建说明。

本地正式签名可复制 [key.properties.example](../android/key.properties.example) 为被忽略的 `android/key.properties`，或设置 `MAMBA_KEYSTORE_PATH`、`MAMBA_KEYSTORE_PASSWORD`、`MAMBA_KEY_ALIAS`、`MAMBA_KEY_PASSWORD`。相对 storeFile 路径以 `android/` 为基准，Windows 建议使用 `/`。

缺少／不完整签名配置、密钥不存在、错误密码会使 Release 失败；不回退到 Debug key。校验脚本还拒绝 Debug 证书、Debug 标志、验证包 ID、缺少 TV 启动入口、错误 ABI 和 APK 证书不一致。Debug／profile 构建不需要正式密钥。已有 Debug 安装与正式 Release 通常不是同一证书，不能把二者视为可直接覆盖升级；流水线不会替用户卸载应用或删除观看记录。

## 版本与首次运行

当前 `pubspec.yaml` 是 `1.1.0-rc.1+3`，对应标签 **`v1.1.0-rc.1`**；`+3` 是基础 build number。预发布版本自动标为 prerelease。拆分 APK 的实际 versionCode 由 Flutter 按 ABI 生成，逐包记录；本批 ARM32／ARM64 预期为 1003／2003。

先提交完整代码并确认该提交的 CI 通过，再创建标签。以下命令会触发签名与公开候选发布；不覆盖已有标签或 Release：

```powershell
git tag -a v1.1.0-rc.1 -m 'MambaTV v1.1.0-rc.1'
git push origin refs/tags/v1.1.0-rc.1
```

仅在本地创建 tag 不触发 CD；普通分支 push 只做 CI。使用完整 `refs/tags/...` 避免同名分支造成歧义。版本不符、tag 不存在或不属于 master 历史都会在预检阶段失败。GitHub Actions 页面可手动运行 `Release Android` 并填写已有 tag，以复测失败运行。

## 产物与校验

- `mambatv-<version>+<build>-arm64-v8a-release.apk`
- `mambatv-<version>+<build>-armeabi-v7a-release.apk`
- `SHA256SUMS`、`build-metadata.json`、`release-notes.md`

公开 Release 仅提供 ARM64／ARM32，选包依据系统 ABI，不能只凭 CPU 位数判断。Release 构建显式指定 `--target-platform android-arm,android-arm64`，打包守卫仅收集两个 ARM 包，即使构建目录残留 x86_64 也不会上传。三 ABI Debug 构建仍保留，x86_64 供模拟器验证。每批还附带六份依赖、许可、源码、安装与已知限制文档。

先通过 aapt 和 apksigner 校验，再计算所有上传文件的 SHA256；发布 job 下载同一次运行的签名 artifacts 后再次核验校验和。构建信息记录提交、版本、工具链清单、实际构建宿主／Java、锁文件 SHA256、ABI、实际 versionCode 和公开证书指纹；托管 CI 构建若修改来源文件则拒绝产物。签名 artifacts 保留 30 天，成功后在 GitHub Release 发布。

M7 的本机 Release 验证使用一次性测试密钥，验证结束删除，不作为用户下载／升级渠道；正式发布另用长期保管的密钥。托管检查和发布结果分别以对应 Actions 运行及 GitHub Release 为准，本机证据不替代托管结果。

## 官方依据

- [Flutter SDK archive](https://docs.flutter.dev/install/archive) 与 [flutter-action](https://github.com/subosito/flutter-action)：固定 SDK 版本与修订。
- [Flutter Android 签名与 APK 构建](https://docs.flutter.dev/deployment/android)：本地签名配置、拆分 ABI 与升级边界。
- [GitHub 可复用工作流](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)：同一 CI 检查用于发布提交。
- [upload-artifact](https://github.com/actions/upload-artifact)、[setup-gradle](https://github.com/gradle/actions/tree/main/setup-gradle) 和 [gh release create](https://cli.github.com/manual/gh_release_create)：产物、缓存和草稿发布接口。


## M7 本轮补充

本轮新增依赖／原生许可清单与锁文件一致性检查；实际 versionCode 必须等于锁定 Flutter ABI 偏移加基础 build number。打包必须包含依赖清单、Dart／原生许可、安装、限制、来源和变更说明，全部纳入校验和。以上代码的本机验证与托管 CI 分开，尚未将本轮 M6／M7 推送或创建新标签。M7 稳定性目标已按用户要求调整为 15 分钟。


M8 弹幕使用 pub.dev 托管的官方 canvas_danmaku 0.3.3，由 pubspec.lock 固定包版本与哈希。先前本地补丁和 `tool/ci/check_vendor.py` 保留作历史试验记录，不再作为应用依赖或 CI 门槛。画布生命周期测试和原生压力测试覆盖实际使用路径；应用源码的 fatal-infos 和既有守卫保持启用。
