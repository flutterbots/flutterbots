import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'token_storage.dart';

enum Status {
  initial,
  authenticated,
  unauthenticated,
}

class AuthStatus {
  final Status status;
  final String? message;

  const AuthStatus({
    required this.status,
    this.message,
  });

  factory AuthStatus.initial() => const AuthStatus(status: Status.initial);

  factory AuthStatus.authenticated() =>
      const AuthStatus(status: Status.authenticated);

  factory AuthStatus.unauthenticated({String? message}) =>
      AuthStatus(status: Status.unauthenticated, message: message);
}

mixin ReactiveAuthStatusMixin<T extends AuthToken> on MemoryTokenStorage<T> {
  AuthStatus _authState = AuthStatus.initial();

  late final StreamController<AuthStatus> _controller =
      StreamController<AuthStatus>.broadcast()..add(_authState);

  Stream<AuthStatus> get authenticationStatus async* {
    yield _getStatus(initTokenValue);
    yield* _controller.stream;
  }

  void setToken(T? token) {
    _updateStatus(token);
  }

  void revokeToken(String? message) {
    if (_authState.status != Status.unauthenticated) {
      _authState = AuthStatus.unauthenticated(message: message);
      _controller.add(_authState);
    }
  }

  void close() => _controller.close();

  void _updateStatus(T? token) {
    _authState = token != null
        ? AuthStatus.authenticated()
        : AuthStatus.unauthenticated();
    _controller.add(_authState);
  }

  AuthStatus _getStatus(T? token) {
    return _authState = token != null
        ? AuthStatus.authenticated()
        : AuthStatus.unauthenticated();
  }

  @mustCallSuper
  @override
  FutureOr<void> write(T? token) {
    setToken(token);
    return super.write(token);
  }

  @mustCallSuper
  @override
  FutureOr<void> delete(String? message) {
    revokeToken(message);
    return super.delete(message);
  }
}
