import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app.dart';
import 'app/logging/app_container.dart';
import 'ui/core/images/tv_image_cache.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TvImageCache.configure();
  MediaKit.ensureInitialized();
  runApp(const AppProviderScope(child: MambaApp()));
}
