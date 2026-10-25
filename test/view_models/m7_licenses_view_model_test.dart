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
      final c = ProviderContainer.test();
      addTearDown(c.dispose);
      c.listen(licenseNoticesProvider, (_, _) {});
      final notices = await c.read(licenseNoticesProvider.future);
      expect(notices, hasLength(13));
      expect(
        notices.any(
          (n) =>
              n.packages.contains('FreeType') &&
              n.text.contains('The FreeType Project LICENSE'),
        ),
        true,
      );
      expect(
        notices.any(
          (n) =>
              n.packages.contains('COPYING.LGPLv3') &&
              n.text.contains('GNU LESSER GENERAL PUBLIC LICENSE'),
        ),
        true,
      );
      expect(
        notices.every((n) => n.text.startsWith('Source: https://github.com/')),
        true,
      );
    },
  );
}
