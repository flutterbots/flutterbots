import 'dart:async';

import 'package:bot_storage/bot_storage.dart';
import 'package:dio_refresh_bot/src/auth_token.dart';
import 'package:dio_refresh_bot/src/token_storage.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart';

/// User authentication status
enum Status {
  /// The initial status before read the token value
  initial,

  /// User is in the authenticated status
  authenticated,

  /// User is in the unauthenticated status
  unauthenticated,
}

/// Wrap user [Status] in class to include message in current user state
class AuthStatus {
  /// Describe current user status using [status] and string [message]
  const AuthStatus({
    required this.status,
    this.message,
  });

  /// Factory for return [AuthStatus] in initial status
  factory AuthStatus.initial() => const AuthStatus(status: Status.initial);

  /// Factory for return [AuthStatus] in authenticated status
  factory AuthStatus.authenticated() =>
      const AuthStatus(status: Status.authenticated);

  /// Factory for return [AuthStatus] in unauthenticated status
  /// and provide a message for unauthenticated status reason
  factory AuthStatus.unauthenticated({String? message}) =>
      AuthStatus(status: Status.unauthenticated, message: message);

  /// Current user status
  final Status status;

  /// This message describe the current user status
  ///
  /// it is helpful in [AuthStatus.unauthenticated] to describe
  /// why user is logged out (revoked or simple logout....)
  final String? message;

  @override
  String toString() {
    return 'AuthStatus${{
      'status': status,
      'message': message,
    }}';
  }
}

/// Mixin add reactive behavior to [BotStorageMixin]
mixin RefreshBotMixin<T extends AuthToken> on BotTokenStorageType<T> {
  ///
  AuthStatus authStatus = AuthStatus.initial();

  late final BehaviorSubject<AuthStatus> _controller =
      BehaviorSubject<AuthStatus>.seeded(_getStatus(read()));

  ///
  Stream<AuthStatus> get authenticationStatus => _controller.stream;

  void _setToken(T? token) {
    _updateStatus(token);
  }

  void _revokeToken(String? message) {
    if (authStatus.status != Status.unauthenticated) {
      authStatus = AuthStatus.unauthenticated(message: message);
      _controller.add(authStatus);
    }
  }

  ///
  void close() {
    _controller.close();
  }

  void _updateStatus(T? token) {
    authStatus = _getStatus(token);
    _controller.add(authStatus);
  }

  AuthStatus _getStatus(T? token) {
    return authStatus = token != null
        ? AuthStatus.authenticated()
        : AuthStatus.unauthenticated();
  }

  @mustCallSuper
  @override
  FutureOr<void> write(T? token) async {
    super.write(token);
    _setToken(token);
  }

  @mustCallSuper
  @override
  FutureOr<void> delete([String? message]) async {
    super.delete();
    _revokeToken(message);
  }
}
