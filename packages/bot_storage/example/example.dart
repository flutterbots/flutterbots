import 'dart:async';

import 'package:bot_storage/bot_storage.dart';

// ignore_for_file: avoid_print
void main() async {

  final botStorage = BotStorageImpl();
  botStorage.stream.listen(print);
  await botStorage.write('new value');
  await botStorage.delete();
  botStorage.close();

  print('Memory Example:');
  // memory
  final botMemStorage = BotStorageMemoryImpl();
  botMemStorage.stream.listen(print);
  await botMemStorage.write('new value');
  await botMemStorage.delete();
  botMemStorage.close();

  print('Wrapper Example:');
  //wrapper
  final BotStorageWrapper botStorageWrapper = BotStorageWrapper<String>(
    delete: () {},
    read: () {
      return 'Hello';
    },
    write: (value) {
      print(value);
    },
  );
  botStorageWrapper.stream.listen(print);
  await botStorageWrapper.write('new value');
  await botStorageWrapper.delete();
  botStorageWrapper.close();
}

class BotStorageMemoryImpl extends BotMemoryStorage<String> {
  @override
  String? get initValue => 'init value';
}

class BotStorageImpl extends BotStorage<String> with BotStorageMixin<String> {
  final FakeStorage _storage = FakeStorage();

  @override
  FutureOr<void> delete() async {
    super.delete();
    return _storage.remove();
  }

  @override
  String? read() {
    return _storage.getString();
  }

  @override
  FutureOr<void> write(String? value) async {
    super.write(value);
    _storage.setString(value);
  }
}

class FakeStorage {
  String? value;

  void setString(String? value) {
    this.value = value;
  }

  String? getString() {
    return value;
  }

  void remove() {
    value = null;
  }
}
