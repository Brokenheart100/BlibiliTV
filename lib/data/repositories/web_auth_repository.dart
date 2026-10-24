import '../../core/result.dart';
import '../../domain/auth/auth.dart';
import '../services/auth/web_auth_service.dart';
import '../services/bilibili/bilibili_api.dart';
import 'persistent_session_repository.dart';

class WebAuthRepository implements AuthRepository {
  WebAuthRepository(this.gateway, this.sessions);
  final AuthGateway gateway;
  final PersistentSessionRepository sessions;
  @override
  Future<Result<QrChallenge>> create(CancellationSignal signal) async {
    try {
      if (sessions.current.isAuthenticated) {
        throw const AppFailure(FailureKind.unavailable, '已登录，请先退出当前账号');
      }
      final epoch = sessions.revision;
      final challenge = await gateway.create(signal);
      if (signal.isCancelled || epoch != sessions.revision) {
        throw const AppFailure(FailureKind.cancelled, '已取消扫码');
      }
      return Success(
        QrChallenge(
          key: challenge.key,
          url: challenge.url,
          expiresAt: challenge.expiresAt,
          authorityRevision: epoch,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  @override
  Future<Result<QrPollStatus>> poll(
    QrChallenge challenge,
    CancellationSignal signal,
  ) async {
    try {
      if (DateTime.now().isAfter(challenge.expiresAt)) {
        return const Success(QrPollStatus.expired);
      }
      final result = await gateway.poll(challenge, signal);
      if (signal.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '已取消扫码');
      }
      if (result.status == QrPollStatus.completed) {
        await sessions.signIn(
          result.credential!,
          challenge.authorityRevision,
          signal,
        );
      }
      return Success(result.status);
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
