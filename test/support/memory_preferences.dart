import 'package:mambatv/data/services/local/local_stores.dart';

class MemoryPreferencesStore implements PreferencesStore {
  final values = <String, String>{};
  bool failWrites = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('synthetic storage failure');
    values[key] = value;
  }
}
