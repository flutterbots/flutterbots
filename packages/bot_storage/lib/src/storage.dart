import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// Callback for read value
typedef ReadCallback<T> = T? Function();

/// Callback for Write a new value
typedef WriteCallback<T> = FutureOr<void> Function(T? value);

/// Callback for delete stored value
typedef DeleteCallback<T> = FutureOr<void> Function();

/// An interface which must be implemented to
/// read, write, and delete the `value`.
abstract class BotStorage<T> {
  /// Returns the stored data.
  FutureOr<T?> read();

  /// Saves the provided [value] asynchronously.
  FutureOr<void> write(T? value);

  /// Deletes the stored data asynchronously.
  FutureOr<void> delete();

  /// Initialize BotStorage
  FutureOr<void> init() {}
}

/// Memory storage implementation for [BotStorage]
/// read, write, and delete the `value` from memory
class BotMemoryStorage<T> extends BotStorage<T> with BotStorageMixin<T> {
  /// The current value saved in the memory
  @override
  late T? value = initValue;

  @override
  T? read() {
    return value;
  }

  @override
  FutureOr<void> write(T? value) {
    super.write(value);
    this.value = value;
  }

  @override
  FutureOr<void> delete() {
    super.delete();
    value = null;
  }

  /// To provide init value for the [BotMemoryStorage]
  T? get initValue => null;
}

/// A wrapper concrete class for [BotStorage] interface
class BotStorageWrapper<T> extends BotStorage<T> with BotStorageMixin<T> {
  /// Provide [read], [write] and [delete] callbacks instead of
  /// implementing [BotStorage] interface directly
  BotStorageWrapper({
    required ReadCallback<T> read,
    required WriteCallback<T> write,
    required DeleteCallback<T> delete,
  })  : _read = read,
        _write = write,
        _delete = delete;

  final ReadCallback<T> _read;
  final WriteCallback<T> _write;
  final DeleteCallback<T> _delete;

  @override
  T? read() {
    return _read();
  }

  @override
  FutureOr<void> write(T? value) {
    super.write(value);
    return _write(value);
  }

  @override
  FutureOr<void> delete() {
    super.delete();
    return _delete();
  }
}

/// A wrapper concrete class for [BotMemoryStorage] interface
class BotMemoryStorageWrapper<T> extends BotMemoryStorage<T> {
  /// Provide [onUpdated] and [onDeleted] callbacks, in addition to [initValue]
  /// instead of implementing [BotMemoryStorage] interface directly
  BotMemoryStorageWrapper({
    DeleteCallback<T>? onDeleted,
    WriteCallback<T>? onUpdated,
    T? initValue,
  })  : _onUpdated = onUpdated,
        _delete = onDeleted,
        _initValue = initValue;

  final WriteCallback<T>? _onUpdated;
  final DeleteCallback<T>? _delete;
  final T? _initValue;

  @override
  FutureOr<void> write(T? value) {
    super.write(value);
    return _onUpdated?.call(value);
  }

  @override
  FutureOr<void> delete() {
    super.delete();
    return _delete?.call();
  }

  @override
  T? get initValue => _initValue;
}

/// Mixin that added reactive behavior to [BotStorage]
mixin BotStorageMixin<T> on BotStorage<T> {
  late T? _value;

  BehaviorSubject<T?>? __controller;

  BehaviorSubject<T?> get _controller {
    if (__controller == null) {
      throw StateError(
        'BotStorage stream not initialized. Call initValueStream() first.',
      );
    }

    return __controller!;
  }

  /// Initializes the internal value stream by reading the current
  /// value asynchronously.
  ///
  /// This method must be called before accessing the reactive stream or
  /// `_value`.
  /// Typically used to support async initialization in [BotStorageMixin]
  @override
  @mustCallSuper
  Future<void> init() async {
    await super.init();

    if (__controller != null) {
      throw StateError(
        'BotStorage stream already initialized.',
      );
    }

    _value = await read();
    __controller = BehaviorSubject<T?>.seeded(_value);
  }

  /// Notifies about changes to any [value] updates.
  Stream<T?> get stream => _controller.stream;

  /// Get the current value.
  T? get value => _value;

  @override
  @mustCallSuper
  void write(T? value) {
    _value = value;
    _controller.add(value);
  }

  @override
  @mustCallSuper
  void delete() {
    _controller.add(null);
    _value = null;
  }

  /// Sends or enqueues an error event.
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  /// Close the auth stream controller.
  void close() {
    _controller.close();
  }
}
