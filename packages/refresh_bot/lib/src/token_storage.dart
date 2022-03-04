import 'dart:async';

/// An interface which must be implemented to
/// read, write, and delete the `Token`.
abstract class TokenStorage<T extends AuthToken> {
  /// Returns the stored token.
  FutureOr<T?> read();

  /// Saves the provided [token] asynchronously.
  FutureOr<void> write(T? token);

  /// Deletes the stored token asynchronously.
  FutureOr<void> delete(String? message);
}

abstract class MemoryTokenStorage<T extends AuthToken>
    implements TokenStorage<T> {
  MemoryTokenStorage() {
    authToken = initTokenValue;
  }

  late T? authToken;

  @override
  FutureOr<void> delete(String? message) {
    authToken = null;
  }

  @override
  FutureOr<T?> read() {
    return authToken;
  }

  @override
  FutureOr<void> write(T? token) {
    authToken = token;
  }

  T? get initTokenValue;
}

class AuthToken {
  /// The access token string as issued by the authorization server.
  final String accessToken;

  /// The type of token this is, typically just the string “bearer”.
  final String tokenType;

  /// Token which applications can use to obtain another access token.
  final String? refreshToken;

  /// If the access token expires, the server should reply
  /// with the duration of time the access token is granted for.
  final int? expiresIn;

  const AuthToken({
    required this.accessToken,
    this.tokenType = "bearer",
    this.refreshToken,
    this.expiresIn,
  });

  AuthToken copyWith({
    String? accessToken,
    String? tokenType,
    String? refreshToken,
    int? expiresIn,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          tokenType == other.tokenType &&
          refreshToken == other.refreshToken &&
          expiresIn == other.expiresIn;

  @override
  int get hashCode =>
      accessToken.hashCode ^
      tokenType.hashCode ^
      refreshToken.hashCode ^
      expiresIn.hashCode;
}
