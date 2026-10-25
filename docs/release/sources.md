# 第三方来源与许可记录

依赖版本来自本机锁定的 pubspec.lock 与 pub deps，清单见 dependencies.json；Dart／Flutter 包许可原文见 THIRD_PARTY_NOTICES.txt。runtimeGraph 指从直接运行依赖可达的包图，不等于对 APK 链接器裁剪结果的完整判定；开发依赖单列，不假称全部进入成品。

Android 原生媒体包装层为 media_kit_libs_android_video 1.3.8，其实际 Gradle 配方下载 libmpv-android-video-build v1.1.7 的 default ABI JAR。固定来源为 [fe8c3ac1a91c09aa6fb1deccbc833f1bafa54768](https://github.com/media-kit/libmpv-android-video-build/tree/fe8c3ac1a91c09aa6fb1deccbc833f1bafa54768)。

| 组件 | 配方记录的版本／来源 | 许可依据 |
| --- | --- | --- |
| mpv | 78d43740f52db817d98bcf24fb30a76ab6fa13ff | [Copyright](https://github.com/mpv-player/mpv/blob/78d43740f52db817d98bcf24fb30a76ab6fa13ff/Copyright) 与 LICENSE.LGPL；构建脚本明确 -Dgpl=false |
| FFmpeg | n6.0 | [LICENSE.md](https://github.com/FFmpeg/FFmpeg/blob/n6.0/LICENSE.md)；default 配方 --disable-gpl、--disable-nonfree、--enable-version3，附 LGPLv3 及其引用的 GPLv3 文本 |
| libass | 0.17.1 | 上游 COPYING，ISC |
| HarfBuzz | 7.2.0 | 上游 COPYING，Old MIT |
| FriBidi | 1.0.12 | 上游 COPYING，LGPL 2.1 |
| FreeType | 2.13.0 | 上游 docs/FTL.TXT；本软件包含使用 FreeType 的组件 |
| mbedTLS | 3.4.0 | 上游 LICENSE，Apache 2.0 |
| dav1d | 1.2.0 | VideoLAN 上游 COPYING |
| libxml2 | 2.10.3 | GNOME 上游 Copyright |

原文及各自固定链接见 NATIVE_NOTICES.txt，应用设置中的开源许可同时展示这些文本与 Flutter 自动汇集的字体／包声明。组件版本来自 [depinfo.sh](https://github.com/media-kit/libmpv-android-video-build/blob/fe8c3ac1a91c09aa6fb1deccbc833f1bafa54768/buildscripts/include/depinfo.sh)，获取与补丁对应 [download-deps.sh](https://github.com/media-kit/libmpv-android-video-build/blob/fe8c3ac1a91c09aa6fb1deccbc833f1bafa54768/buildscripts/include/download-deps.sh)、同提交的 patches 与 flavors/default.sh。

包装层及构建仓库自身许可不替代被链接原生组件许可。本记录提供来源和许可文本，不宣称已完成所有成品分发材料审核；正式发布前应对实际二进制、对应源码／补丁、可重建与适用许可材料做最后复核。此项目本身没有在本轮被擅自指定开源许可证。

TV 图标与 banner 为本项目自制几何路径，无外部图片或字体；源文件在 assets/brand，重现脚本为 tool/release/brand_assets.py（PNG 生成需要 Pillow）。Android TV 品牌规格依据 [官方检查清单](https://developer.android.com/training/tv/publishing/checklist)。
