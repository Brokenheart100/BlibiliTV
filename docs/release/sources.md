# 第三方来源与许可记录

依赖版本来自本机锁定的 pubspec.lock 与 pub deps，清单见 dependencies.json；Dart／Flutter 包许可原文见 THIRD_PARTY_NOTICES.txt。runtimeGraph 指从直接运行依赖可达的包图，不等于对 APK 链接器裁剪结果的完整判定；开发依赖单列，不假称全部进入成品。

2026-10-29 起不再依赖 media_kit 系列。Android 原生包装层是锁定的 better_player_android 1.9.0，其本地 `android/build.gradle` 声明 Media3 1.11.0。当前生效的原生声明见 `assets/licenses/native-notices.json` 与 NATIVE_NOTICES.txt；Media3 的 Apache 2.0 原文来自 [1.11.0 上游 LICENSE](https://github.com/androidx/media/blob/1.11.0/LICENSE)。Dart 包声明按更新后的 lockfile 重新生成。

历史 media_kit APK 的 mpv／FFmpeg／字体与字幕库配方及声明保存在先前 Git 版本中，不再作为当前 Android 产物的组成清单。Windows 的 Better Player 插件仍使用外部 mpv DLL，包自身未附该 DLL；当前未新增下载、打包或分发该二进制。未来若发行 Windows 包，应按实际 DLL 重建对应来源和许可清单，不能复用旧 Android 构建配方。

包装层许可不替代被链接原生组件许可，Dart 依赖图也不等同于最终成品链接器结果；以实际 APK 检查和 [后端清理](../media-backend-cleanup.md) 为准。本项目本身未在本轮指定开源许可证。

TV 图标与 banner 为本项目自制几何路径，无外部图片或字体；源文件在 assets/brand，重现脚本为 tool/release/brand_assets.py（PNG 生成需要 Pillow）。Android TV 品牌规格依据 [官方检查清单](https://developer.android.com/training/tv/publishing/checklist)。


M8 弹幕采用 pub.dev 托管的官方 canvas_danmaku 0.3.3（MIT）。原始官方归档 SHA256 为 `1ff071d027b1cf3320d4b58ff1aee6811de51ce39b5b5773c2e0d7693e02d401`；`third_party/canvas_danmaku/` 保存先前未通过持续压力的本地调度试验来源与差异，仅用于历史核查，不参与当前构建。protobuf／fixnum 的 BSD 原文和版本由本批依赖清单汇集；protoc 与 Dart 生成器是开发工具，不把开发工具二进制附入 APK。
