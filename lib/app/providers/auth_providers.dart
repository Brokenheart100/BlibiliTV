import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

class QrTiming {
  const QrTiming({
    this.pollInterval = const Duration(seconds: 2),
    this.tickInterval = const Duration(seconds: 1),
    this.maxFailures = 3,
  });
  final Duration pollInterval, tickInterval;
  final int maxFailures;
}

@Riverpod(keepAlive: true)
QrTiming qrTiming(Ref ref) => const QrTiming();

String safeLoginReturn(String? raw) {
  if (raw == null) return '/library';
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      uri.hasQuery) {
    return '/library';
  }
  if (const [
    '/home',
    '/search',
    '/library',
    '/library/records',
    '/settings',
  ].contains(uri.path)) {
    return uri.path;
  }
  if (RegExp(r'^/video/BV[a-zA-Z0-9]+$').hasMatch(uri.path)) return uri.path;
  final player = RegExp(r'^/player/(BV[a-zA-Z0-9]+)$').firstMatch(uri.path);
  return player == null ? '/library' : '/video/${player.group(1)}';
}
