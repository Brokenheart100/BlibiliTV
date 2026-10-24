import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app.dart';
import 'ui/core/images/tv_image_cache.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TvImageCache.configure();
  MediaKit.ensureInitialized();
  runApp(ProviderScope(retry: (_, _) => null, child: const MambaApp()));
}
