import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

import '../../data/services/local/app_database.dart';
import '../../data/services/local/local_stores.dart';
import '../../data/services/network/safe_logging_interceptor.dart';
import '../logging/app_talker.dart';

part 'infrastructure_providers.g.dart';

@Riverpod(keepAlive: true)
Talker appTalker(Ref ref) {
  final talker = createAppTalker();
  ref.onDispose(() {
    talker.cleanHistory();
    talker.disable();
  });
  return talker;
}

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final talker = ref.watch(appTalkerProvider);
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  client.interceptors.add(
    SafeLoggingInterceptor((entry) => recordHttpMetadata(talker, entry)),
  );
  ref.onDispose(() => client.close(force: true));
  return client;
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(() {
    database.close();
  });
  return database;
}

@Riverpod(keepAlive: true)
PreferencesStore preferencesStore(Ref ref) => PlatformPreferencesStore();

@Riverpod(keepAlive: true)
CredentialStore credentialStore(Ref ref) => const SecureCredentialStore();
