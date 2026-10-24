import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../ui/features/settings/view_models/settings_view_model.dart';
import 'providers/infrastructure_providers.dart';
import 'providers/repository_providers.dart';

part 'bootstrap.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  ref.watch(apiClientProvider);
  ref.watch(credentialStoreProvider);
  await Future.wait<void>([
    ref.watch(sessionProvider.future).then((_) {}),
    ref.watch(settingsViewModelProvider.future).then((_) {}),
    ref.watch(appDatabaseProvider).initialize(),
  ]);
}
