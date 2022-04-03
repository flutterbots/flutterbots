import 'dart:async';

abstract class BotStorage<T> {
  /// Returns the stored data.
  T? read();

  /// Saves the provided [value] asynchronously.
  FutureOr<void> write(T? value);

  /// Deletes the stored data asynchronously.
  FutureOr<void> delete();
}

abstract class BotMemoryStorage<T> extends BotStorage<T> {
  late T? value = initValue;

  @override
  T? read() {
    return value;
  }

  @override
  FutureOr<void> write(T? value) {
    this.value = value;
  }

  @override
  FutureOr<void> delete() {
    value = null;
  }

  T? get initValue => value;
}
