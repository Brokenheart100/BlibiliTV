import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../ui/features/auth/view_models/qr_login_view_model.dart';
import '../../ui/features/auth/view_models/personal_home_view_model.dart';
import '../../ui/features/catalog/view_models/catalog_view_model.dart';
import '../../ui/features/library/view_models/library_view_model.dart';
import '../../ui/features/player/view_models/player_view_model.dart';
import '../../ui/features/settings/view_models/settings_view_model.dart';

/// Uses the official observer lifecycle, replacing raw payloads before logging.
/// Truncation is not redaction: even provider.toString() contains family args.
final class SafeRiverpodObserver extends TalkerRiverpodObserver {
  SafeRiverpodObserver(this.destination)
    : super(
        talker: destination,
        settings: const TalkerRiverpodLoggerSettings(enabled: false),
      );

  final Talker destination;
  static const _providers = {
    'sessionProvider',
    'qrLoginViewModelProvider',
    'catalogViewModelProvider',
    'playerViewModelProvider',
    'libraryViewModelProvider',
    'personalCollectionProvider',
    'personalProfileProvider',
    'settingsViewModelProvider',
  };

  String _failure(Object? error) =>
      error is AppFailure ? error.kind.name : 'unexpected';

  Map<String, Object> _summary(Object? value) {
    if (value is AsyncValue) {
      if (value.isLoading) return {'phase': 'loading'};
      if (value.hasError) {
        return {'phase': 'failed', 'failure': _failure(value.error)};
      }
      return _summary(value.value);
    }
    return switch (value) {
      PlayerState() => {
        'phase': value.phase.name,
        'buffering': value.snapshot.buffering,
        'seeking': value.seekTarget != null,
        'quality': value.quality,
        'rate': value.rate,
        if (value.failure != null) 'failure': value.failure!.kind.name,
      },
      QrLoginState() => {
        'phase': value.phase.name,
        if (value.failure != null) 'failure': value.failure!.kind.name,
      },
      Session() => {'phase': value.status.name},
      CatalogState() => {
        'phase': value.refreshing
            ? 'refreshing'
            : value.loadingMore
            ? 'loadingMore'
            : 'ready',
        'count': value.items.length,
        if (value.failure != null) 'failure': value.failure!.kind.name,
      },
      LibraryState() => {
        'phase': value.mutating
            ? 'mutating'
            : value.loading
            ? 'loading'
            : 'ready',
        'count': value.items.length,
        if (value.failure != null) 'failure': value.failure!.kind.name,
      },
      PersonalCollectionState() => {
        'phase': value.loading ? 'loading' : 'ready',
        'count': value.items.length,
        if (value.failure != null) 'failure': value.failure!.kind.name,
      },
      SettingsState() => {
        'phase': value.saving ? 'saving' : 'ready',
        'theme': value.settings.theme.name,
      },
      _ => {'phase': 'ready'},
    };
  }

  void _record(
    ProviderObserverContext context,
    String event, {
    Object? value,
    Object? error,
  }) {
    final name = context.provider.name;
    if (!destination.settings.enabled || !_providers.contains(name)) return;
    final fields = <String, Object?>{
      'event': event,
      'provider': name,
      if (event != 'disposed' && event != 'failed') ..._summary(value),
      if (event == 'failed') 'failure': _failure(error),
    };
    final failed = event == 'failed' || fields.containsKey('failure');
    destination.logCustom(
      TalkerLog(
        jsonEncode(fields),
        title: 'Riverpod',
        key: failed
            ? TalkerKey.riverpodFail
            : switch (event) {
                'added' => TalkerKey.riverpodAdd,
                'disposed' => TalkerKey.riverpodDispose,
                _ => TalkerKey.riverpodUpdate,
              },
        logLevel: failed ? LogLevel.error : LogLevel.debug,
      ),
    );
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    super.didAddProvider(context, value);
    _record(context, 'added', value: value);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    if (!destination.settings.enabled ||
        !_providers.contains(context.provider.name)) {
      return;
    }
    // Native positions, cache progress and QR countdown do not change summary.
    if (jsonEncode(_summary(previousValue)) == jsonEncode(_summary(newValue))) {
      return;
    }
    _record(context, 'updated', value: newValue);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    super.didDisposeProvider(context);
    _record(context, 'disposed');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    super.providerDidFail(context, error, stackTrace);
    _record(context, 'failed', error: error);
  }
}
