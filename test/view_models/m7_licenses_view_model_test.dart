import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/ui/features/settings/view_models/licenses_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'packaged native notices retain upstream source and full license terms',
    () async {
      LicenseRegistry.reset();
      addTearDown(LicenseRegistry.reset);
      final c = ProviderContainer.test();
      addTearDown(c.dispose);
      c.listen(licenseNoticesProvider, (_, _) {});
      final notices = await c.read(licenseNoticesProvider.future);
      expect(notices, hasLength(1));
      expect(
        notices.any(
          (n) =>
              n.packages == 'AndroidX Media3 1.11.0 (Android native)' &&
              n.text.contains('Apache License') &&
              n.text.contains('END OF TERMS AND CONDITIONS'),
        ),
        true,
      );
      expect(
        notices.any(
          (n) => RegExp(
            r'media_kit|mpv|ffmpeg|freetype|COPYING.LGPLv3',
            caseSensitive: false,
          ).hasMatch(n.packages),
        ),
        false,
      );
      expect(
        notices.every(
          (n) => n.text.startsWith(
            'Source: https://github.com/androidx/media/tree/1.11.0\n',
          ),
        ),
        true,
      );
    },
  );
}
