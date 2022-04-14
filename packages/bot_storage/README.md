# :robot: Bot Storage
[![pub package][pub_badge]][pub_badge_link][![style: very good analysis][vgv_badge]][vgv_badge_link][![License: MIT][license_badge]][license_badge_link]

A useful package provide an interface to handle read, write and delete operations in reactive way.

## Usage

Add a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  bot_storage: ^1.0.1
```

Simple usage using `BotMemoryStorage`:

```dart
import 'package:bot_storage/bot_storage.dart';

void main() {
  final botStorage = BotStorageImpl();
  botStorage.stream.listen(print);
  await botStorage.write('new value');
  await botStorage.delete();
  botStorage.close();
}

class BotStorageImpl extends BotMemoryStorage<String> {
  @override
  String? get initValue => 'init value';
}
```
Or implement `BotStorage` with `SharedPreference` (or any other local storage) like this:

```dart
class BotStorageImpl extends BotStorage<String> with BotStorageMixin<String> {
  BotStorageImpl(this._storage);
  
  final SharedPreference _storage;

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

void main() async {
  final botStorage = BotStorageImpl();
  botStorage.stream.listen(print);
  await botStorage.write('event');
  await botStorage.delete();
  botStorage.close();

}
```
You can use BotStorageWrapper Concreate class
```dart
void main(){
  final BotStorageWrapper botStorageWrapper = BotStorageWrapper<String>(
    delete: () {
      // delete from your storage
    },
    read: () {
      // read from your storage
      return 'none';
    },
    write: (value) {
      // write to your storage
    },
  );
  botStorageWrapper.stream.listen(print);
  botStorageWrapper.write('new value');
  botStorageWrapper.delete();
  botStorageWrapper.close();
}
 
```
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[vgv_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[pub_badge]: https://img.shields.io/badge/pub-1.0.1-blue
[pub_badge_link]: https://pub.dartlang.org/packages/bot_storage
[vgv_badge_link]: https://pub.dev/packages/very_good_analysis



