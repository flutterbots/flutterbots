import 'dart:async';

import 'package:bot_storage/bot_storage.dart';
import 'package:test/test.dart';

class MockValue {}

class BotStorageImpl extends BotStorage<MockValue> {
  MockValue? storageValue;

  @override
  MockValue? read() {
    return storageValue;
  }

  @override
  FutureOr<void> write(MockValue? value) {
    storageValue = value;
  }

  @override
  FutureOr<void> delete() {
    storageValue = null;
  }
}

class BotStorageImplWithMixin extends BotStorage<MockValue>
    with BotStorageMixin {
  MockValue? storageValue;

  @override
  MockValue? read() {
    return storageValue;
  }

  @override
  FutureOr<void> write(MockValue? value) {
    super.write(value);
    storageValue = value;
  }

  @override
  FutureOr<void> delete() {
    super.delete();
    storageValue = null;
  }
}

void main() {
  late MockValue mockValue;
  setUpAll(() {
    mockValue = MockValue();
  });

  group(
    'BotMemoryStorage Storage',
    () {
      late BotMemoryStorage<MockValue> botStorage;
      setUp(
        () {
          botStorage = BotMemoryStorage<MockValue>();
        },
      );

      test(
        'write and read and delete',
        () {
          botStorage.write(mockValue);
          expect(botStorage.read(), mockValue);
          expect(botStorage.stream, emits(mockValue));

          botStorage.delete();
          expect(botStorage.read(), isNull);
          expect(botStorage.stream, emits(isNull));
        },
      );
    },
  );

  group(
    'Bot Storage',
    () {
      late BotStorage botStorage;
      setUp(
        () {
          botStorage = BotStorageImpl();
        },
      );

      test(
        'write and read and delete',
        () {
          botStorage.write(mockValue);
          expect(botStorage.read(), mockValue);
          botStorage.delete();
          expect(botStorage.read(), isNull);
        },
      );
    },
  );

  group(
    'Bot Storage with BotStorageMixin',
    () {
      late BotStorageMixin botStorage;
      setUp(
        () {
          botStorage = BotStorageImplWithMixin();
        },
      );

      test(
        'write and read and delete',
        () {
          botStorage.write(mockValue);
          expect(botStorage.read(), mockValue);
          expect(botStorage.stream, emits(mockValue));

          botStorage.delete();
          expect(botStorage.read(), isNull);
          expect(botStorage.stream, emits(isNull));
        },
      );
    },
  );

  // group(
  //   'Bot Storage Wrapper with BotStorageMixin',
  //   () {
  //     late BotStorageMixin botStorage;
  //     setUp(
  //       () {
  //         botStorage =
  //             BotStorageWrapper<MockValue>(read: read, write: onUpdated, delete: delete);
  //       },
  //     );
  //
  //     test(
  //       'write and read and delete',
  //       () {
  //         botStorage.write(mockValue);
  //         expect(botStorage.read(), mockValue);
  //         expect(botStorage.stream, emits(mockValue));
  //
  //         botStorage.delete();
  //         expect(botStorage.read(), isNull);
  //         expect(botStorage.stream, emits(isNull));
  //       },
  //     );
  //   },
  // );
}
