import 'dart:async';

import 'package:bot_storage/bot_storage.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Callback for delete stored value from storage and return optional message
typedef DeleteTokenCallback<T> = FutureOr<String?> Function();

/// A type mixin used in [RefreshTokenInterceptor] that extend
/// [BotStorage.delete] behavior with message parameter.
///
/// That can be used for delete token and provide a reason message,
/// refer to [RefreshTokenInterceptor.onRevoked]
///
mixin BotTokenStorageType<T> on BotStorageMixin<T> {
  /// Deletes the stored token asynchronously.
  ///
  /// the [message] is for providing the delete reason
  /// for example "user logged out" or "user blocked"
  @override
  @mustCallSuper
  FutureOr<void> delete([String? message]) {
    super.delete();
  }

  @override
  @mustCallSuper
  FutureOr<void> write(T? value) {
    super.write(value);
  }
}

/// A token storage that extends [BotStorage] to store and retrieve tokens.
abstract class BotTokenStorage<T extends AuthToken> extends BotStorage<T>
    with BotStorageMixin<T>, BotTokenStorageType<T> {}

/// Memory storage to store and retrieve tokens in memory.
/// read, write, and delete the `value` from memory
class BotMemoryTokenStorage<T extends AuthToken> extends BotMemoryStorage<T>
    with BotTokenStorageType<T>, RefreshBotMixin<T> {
  ///
  BotMemoryTokenStorage({
    WriteCallback<T>? onUpdated,
    DeleteTokenCallback<T>? onDeleted,
    ReadCallback<T>? initValue,
  })  : _writeCallback = onUpdated,
        _deleteCallback = onDeleted,
        _initValue = initValue;

  final WriteCallback<T>? _writeCallback;
  final DeleteTokenCallback<T>? _deleteCallback;
  final ReadCallback<T>? _initValue;

  @mustCallSuper
  @override
  FutureOr<void> delete([String? message]) async {
    await _deleteCallback?.call();
    value = null;
    final deleteMessage = (await _deleteCallback?.call()) ?? message;
    await super.delete(deleteMessage);
  }

  @override
  @mustCallSuper
  FutureOr<void> write(T? token) async {
    await _writeCallback?.call(token);
    value = token;
    await super.write(token);
  }

  @override
  T? get initValue => _initValue?.call();
}

///
class AuthToken extends Equatable {
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
      refreshToken: map['refreshToken'] as String?,
      expiresIn: map['expiresIn'] as int?,
    );
  }

  /// The access token as a string.
  final String accessToken;

  /// The type of token, the default is “bearer”
  final String tokenType;

  /// Token which can be used to obtain another access token.
  final String? refreshToken;

  ///
  final int? expiresIn;

  ///
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

  ///
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'tokenType': tokenType,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  @override
  String toString() {
    return 'AuthToken${toMap()}';
  }

  @override
  List<Object?> get props => [accessToken, tokenType, refreshToken, expiresIn];
}
