import 'dart:async';

import 'package:bot_storage/bot_storage.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:meta/meta.dart';

/// Callback for delete stored value from storage and return optional message
typedef DeleteTokenCallback<T> = FutureOr<String?> Function();

/// A type mixin used in [RefreshTokenInterceptor] that extend
/// [BotStorage.delete] behavior with message parameter.
///
/// That can be used for delete token and provide a reason message,
/// refer to [RefreshTokenInterceptor.onRevoked]
///
mixin BotTokenStorageType<T> on BotStorage<T> {
  /// Deletes the stored token asynchronously.
  ///
  /// the [message] is for providing the delete reason
  /// for example "user logged out" or "user blocked"
  @override
  @mustCallSuper
  FutureOr<void> delete([String? message]) {
    super.delete();
  }
}

/// A token storage that extends [BotStorage] to store and retrieve tokens.
abstract class BotTokenStorage<T extends AuthToken> extends BotStorage<T>
    with BotStorageMixin<T>, BotTokenStorageType<T> {}

/// Memory storage to store and retrieve tokens in memory.
/// read, write, and delete the `value` from memory
class BotMemoryTokenStorage<T extends AuthToken> extends BotMemoryStorage<T>
    with BotTokenStorageType<T> {
  @mustCallSuper
  @override
  FutureOr<void> delete([String? message]) async {
    value = null;
    await super.delete(message);
  }

  @override
  @mustCallSuper
  FutureOr<void> write(T? value) async {
    this.value = value;
    await super.write(value);
  }

  @override
  T? get initValue => null;
}
