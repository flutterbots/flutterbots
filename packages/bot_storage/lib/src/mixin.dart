import 'dart:async';

import 'package:flutter/foundation.dart';

import '../bot_storage.dart';

mixin BotStorageMixin<T> on BotStorage<T> {
  T? value;

  final _controller = StreamController<T?>.broadcast();

  Stream<T?> get stream async* {
    value = read();
    yield value;
    yield* _controller.stream;
  }

  @override
  @mustCallSuper
  FutureOr<void> write(T? value) {
    _controller.add(value);
  }

  @override
  @mustCallSuper
  FutureOr<void> delete() {
    _controller.add(null);
  }

  void close() {
    _controller.close();
  }
}
