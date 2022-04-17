import 'dart:async';

import 'package:bot_storage/bot_storage.dart';
import 'package:dio_refresh_bot/refresh_bot.dart';

/// An interface which must be implemented to
/// read, write, and delete the `Token`.
abstract class BotTokenStorage<T extends AuthToken> extends BotStorage<T> {
  /// Deletes the stored token asynchronously.
  ///
  /// the [message] is for providing the delete reason
  /// for example "user logged out" or "user blocked"
  @override
  FutureOr<void> delete([String? message]);
}

///
class BotMemoryTokenStorage<T extends AuthToken> extends BotMemoryStorage<T>
    with RefreshBotMixin<T>
    implements BotTokenStorage<T> {
  @override
  FutureOr<void> delete([String? message]) {
    super.delete();
    value = null;
  }

  @override
  Future<void> write(T? token) async {
    await super.write(token);
    value = token;
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

  ///
  factory AuthToken.fromMap(Map<String, dynamic> map) {
    return AuthToken(
      accessToken: map['accessToken'] as String,
      tokenType: map['tokenType'] as String,
      refreshToken: map['refreshToken'] as String,
      expiresIn: map['expiresIn'] as Duration,
    );
  }

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
