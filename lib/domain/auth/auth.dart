import '../../core/result.dart';

/// Short-lived login secret, intentionally absent from diagnostics/serialization.
final class QrChallenge {
  const QrChallenge({
    required this.key,
    required this.url,
    required this.expiresAt,
    this.authorityRevision = 0,
  });
  final String key, url;
  final DateTime expiresAt;
  final int authorityRevision;
  @override
  String toString() => 'QrChallenge(redacted)';
}

enum QrPollStatus { waiting, scanned, expired, completed }

abstract interface class AuthRepository {
  Future<Result<QrChallenge>> create(CancellationSignal cancellation);

  /// A completed result means identity validation AND durable storage succeeded.
  Future<Result<QrPollStatus>> poll(
    QrChallenge challenge,
    CancellationSignal cancellation,
  );
}
