import '../../../domain/entities/app_models.dart';

final class RequestIdentity {
  const RequestIdentity(this.session, [String? cookie]) : _cookie = cookie;
  final Session session;
  final String? _cookie;
  String? get cookie => session.isAuthenticated ? _cookie : null;
  @override
  String toString() =>
      'RequestIdentity(${session.scopeKey}, credential: redacted)';
}
