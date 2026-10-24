import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// M0 Android fallback: the emulator's EGL path can report frames but stay black.
/// MediaCodec in an emulator is virtual and is not evidence of physical HW decode.
VideoControllerConfiguration probeVideoConfiguration() =>
    defaultTargetPlatform == TargetPlatform.android
    ? const VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
      )
    : const VideoControllerConfiguration();
