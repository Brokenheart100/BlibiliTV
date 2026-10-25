import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'licenses_view_model.g.dart';

class LicenseNotice {
  const LicenseNotice(this.packages, this.text);
  final String packages, text;
}

@riverpod
Future<List<LicenseNotice>> licenseNotices(Ref ref) async {
  final values = <LicenseNotice>[];
  final native = jsonDecode(
    await rootBundle.loadString('assets/licenses/native-notices.json'),
  ) as List<dynamic>;
  for (final item in native) {
    final row = item as Map<String, dynamic>;
    values.add(
      LicenseNotice(
        row['package'] as String,
        'Source: ${row['source']}\n\n${row['text']}',
      ),
    );
  }
  await for (final entry in LicenseRegistry.licenses) {
    if (!ref.mounted) return const [];
    values.add(
      LicenseNotice(
        entry.packages.join(', '),
        entry.paragraphs.map((p) => p.text).join('\n\n'),
      ),
    );
  }
  values.sort(
    (a, b) => a.packages.toLowerCase().compareTo(b.packages.toLowerCase()),
  );
  return List.unmodifiable(values);
}
