import 'dart:async';

import 'package:bot_storage/bot_storage.dart';

/// An interface which must be implemented to
/// read, write, and delete the `Token`.
abstract class BotTokenStorage<T extends AuthToken> implements BotStorage<T> {
  /// Deletes the stored token asynchronously.
  ///
  /// the [message] is for providing the delete reason
  /// for example "user logged out" or "user blocked"
  @override
  FutureOr<void> delete([String? message]);
}

///
abstract class BotMemoryTokenStorage<T extends AuthToken>
    implements BotMemoryStorage<T> {
  @override
  FutureOr<void> delete([String? message]) {
    value = null;
  }
}

///
class AuthToken {
  ///
  const AuthToken({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.refreshToken,
    this.expiresIn,
  });

  /// The access token as a string.
  final String accessToken;

  /// The type of token, the default is “bearer”.
  final String tokenType;

  /// Token which can used to obtain another access token.
  final String? refreshToken;

  ///
  final Duration? expiresIn;

  ///
  AuthToken copyWith({
    String? accessToken,
    String? tokenType,
    String? refreshToken,
    Duration? expiresIn,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}
