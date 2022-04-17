import 'dart:async';
import 'package:bot_storage/bot_storage.dart';

import 'package:flutter/foundation.dart';
import 'package:refresh_bot/src/token_storage.dart';

/// User authentication status
enum Status {
  /// The initial status before read the token value
  initial,

  /// User inn the authenticated status
  authenticated,

  /// User inn the unauthenticated status
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
}

/// Mixin add reactive behavior to [BotStorageMixin]
mixin RefreshBotMixin<T extends AuthToken> on BotStorageMixin<T> {
  AuthStatus _authState = AuthStatus.initial();

  late final StreamController<AuthStatus> _controller =
      StreamController<AuthStatus>.broadcast()..add(_authState);

  ///
  Stream<AuthStatus> get authenticationStatus async* {
    _authState = _getStatus(read());
    yield _authState;
    yield* _controller.stream;
  }

  void _setToken(T? token) {
    _updateStatus(token);
  }

  void _revokeToken(String? message) {
    if (_authState.status != Status.unauthenticated) {
      _authState = AuthStatus.unauthenticated(message: message);
      _controller.add(_authState);
    }
  }

  @override
  void close() {
    _controller.close();
    super.close();
  }

  void _updateStatus(T? token) {
    _authState = _getStatus(token);
    _controller.add(_authState);
  }

  AuthStatus _getStatus(T? token) {
    return _authState = token != null
        ? AuthStatus.authenticated()
        : AuthStatus.unauthenticated();
  }

  @mustCallSuper
  @override
  FutureOr<void> write(T? token) async {
    super.write(value);
    _setToken(token);
  }

  @mustCallSuper
  @override
  FutureOr<void> delete([String? message]) async {
    super.delete();
    _revokeToken(message);
  }
}
