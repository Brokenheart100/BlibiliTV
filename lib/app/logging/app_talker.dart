import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

const diagnosticsEnabled =
    kDebugMode || bool.fromEnvironment('MAMBA_DIAGNOSTICS');

Talker createAppTalker({
  bool enabled = diagnosticsEnabled,
  bool console = true,
}) => TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: enabled,
    useConsoleLogs: console,
    useHistory: true,
    maxHistoryItems: 200,
  ),
);

/// Accepts only the metadata serialized by SafeLoggingInterceptor. Raw Dio
/// exceptions/requests/responses and provider states must never reach Talker.
void recordHttpMetadata(Talker talker, String metadata) {
  final fields = jsonDecode(metadata) as Map<String, dynamic>;
  final status = fields['status'] as int?;
  final category = fields['category'] as String;
  final level = switch ((status, category)) {
    (_, 'cancel') => LogLevel.debug,
    (final int value, _) when value >= 500 => LogLevel.error,
    (final int value, _) when value >= 400 => LogLevel.warning,
    (_, 'response') => LogLevel.info,
    _ => LogLevel.warning,
  };
  talker.logCustom(
    TalkerLog(
      metadata,
      key: level == LogLevel.error || level == LogLevel.warning
          ? TalkerKey.httpError
          : TalkerKey.httpResponse,
      title: 'HTTP',
      logLevel: level,
    ),
  );
}
