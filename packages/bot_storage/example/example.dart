import 'package:bot_storage/bot_storage.dart';

// ignore_for_file: avoid_print
void main() {
  final botStorage = BotStorageImpl();
  botStorage.stream.listen(print);
  botStorage.write('event');
}

class BotStorageImpl extends BotMemoryStorage<String> {
  @override
  String? get initValue => 'init event';
}
