import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PlatformPreferencesStore implements PreferencesStore {
  PlatformPreferencesStore() : _preferences = SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  @override
  Future<String?> read(String key) => _preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

abstract interface class CredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureCredentialStore implements CredentialStore {
  const SecureCredentialStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
