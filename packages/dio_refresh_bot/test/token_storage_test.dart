import 'dart:async';

import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAuthToken extends Mock implements AuthToken {}

class MockBotTokenStorage extends BotTokenStorage<MockAuthToken> {
  MockAuthToken? storageValue;

  @override
  MockAuthToken? read() {
    return storageValue;
  }

  @override
  FutureOr<void> write(MockAuthToken? value) {
    storageValue = value;
    super.write(value);
  }

  @override
  FutureOr<void> delete([String? message]) {
    storageValue = null;
    super.delete(message);
  }
}

void main() {
  test('AuthStatus toString', () {
    expect(
      AuthStatus.unauthenticated(message: 'message').toString(),
      'AuthStatus${{'status': Status.unauthenticated, 'message': 'message'}}',
    );
  });

  late MockAuthToken mockAuthToken;
  setUpAll(() {
    mockAuthToken = MockAuthToken();
  });

  group('Bot Memory Token Storage', () {
    late BotMemoryTokenStorageWrapper<MockAuthToken> botMemoryTokenStorage;

    setUp(() {
      botMemoryTokenStorage = BotMemoryTokenStorageWrapper();
    });

    test('init token should be null and emit it', () {
      expect(botMemoryTokenStorage.value, null);
      expect(botMemoryTokenStorage.stream, emits(null));
    });

    test('init auth state is unauthenticated', () {
      expect(
        botMemoryTokenStorage.authenticationStatus.map((event) => event.status),
        emits(
          Status.unauthenticated,
        ),
      );
    });

    test(
        'write should change memory token and emit it '
        'and change authenticationStatus', () async {
      await botMemoryTokenStorage.write(mockAuthToken);
      expect(botMemoryTokenStorage.value, isA<MockAuthToken>());
      expect(botMemoryTokenStorage.stream, emits(mockAuthToken));
      expect(
        botMemoryTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.authenticated),
      );
    });

    test(
        'delete should change memory value to null and '
        'emit it and unauthenticated should emitted.', () async {
      await botMemoryTokenStorage.delete();
      expect(botMemoryTokenStorage.stream, emits(isNull));
      expect(
        botMemoryTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.unauthenticated),
      );
    });

    test('just first delete should emit new authenticationStatus', () async {
      await botMemoryTokenStorage.write(mockAuthToken);
      botMemoryTokenStorage
        ..delete()
        ..delete();
      await expectLater(
        botMemoryTokenStorage.authenticationStatus.map((event) => event.status),
        emitsInOrder(<Status>[Status.authenticated, Status.unauthenticated]),
      );
    });

    test('delete with message', () async {
      await botMemoryTokenStorage.write(mockAuthToken);
      await botMemoryTokenStorage.delete('token deleted 🤯');
      expect(
        botMemoryTokenStorage.authenticationStatus
            .map((event) => event.message),
        emits('token deleted 🤯'),
      );
    });
  });

  group('Bot Token Storage', () {
    late MockBotTokenStorage botTokenStorage;

    setUp(() {
      botTokenStorage = MockBotTokenStorage();
    });

    test('init token should be null and emit it', () {
      expect(botTokenStorage.value, null);
      expect(botTokenStorage.stream, emits(null));
    });

    test('init auth state is unauthenticated', () {
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(
          Status.unauthenticated,
        ),
      );
    });

    test(
        'write should change mixin token value and emit it and change authenticationStatus',
        () async {
      await botTokenStorage.write(mockAuthToken);
      expect(botTokenStorage.value, isA<MockAuthToken>());
      expect(botTokenStorage.stream, emits(isA<MockAuthToken>()));
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.authenticated),
      );
    });

    test(
        'delete should change mixin token value to null and '
        'emit it and unauthenticated should emitted.', () async {
      await botTokenStorage.delete();
      expect(botTokenStorage.stream, emits(isNull));
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.unauthenticated),
      );
    });
  });
}
