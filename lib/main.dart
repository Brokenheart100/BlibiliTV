import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/logging/app_container.dart';
import 'ui/core/images/tv_image_cache.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TvImageCache.configure();
  runApp(const AppProviderScope(child: MambaApp()));
}
