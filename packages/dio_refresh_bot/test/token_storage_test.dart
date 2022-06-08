import 'dart:async';

import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAuthToken extends Mock implements AuthToken {}

class MockBotTokenStorage extends BotTokenStorage<MockAuthToken>
    with RefreshBotMixin {
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
  group('AuthToken', () {
    late AuthToken authToken;
    late AuthToken authToken2;
    late Map<String, dynamic> mapMatcher;
    setUp(() {
      authToken = const AuthToken(
        accessToken: 'accessToken',
        expiresIn: 98,
        refreshToken: 'refreshToken',
        tokenType: 'tokenType',
      );
      authToken2 = const AuthToken(
        accessToken: 'accessToken',
        expiresIn: 98,
        refreshToken: 'refreshToken',
        tokenType: 'tokenType',
      );
      mapMatcher = <String, dynamic>{
        'accessToken': 'accessToken',
        'tokenType': 'tokenType',
        'refreshToken': 'refreshToken',
        'expiresIn': 98,
      };
    });

    test('to map', () {
      expect(authToken.toMap(), mapMatcher);
    });

    test('from map', () {
      expect(AuthToken.fromMap(mapMatcher), authToken);
    });

    test('to string', () {
      expect(
        authToken.toString(),
        'AuthToken$mapMatcher',
      );
    });

    group('token equality', () {
      test('token equality with same values', () {
        expect(authToken == authToken2, isTrue);
      });

      test('token equality with different [accessToken] value', () {
        expect(
          authToken == authToken2.copyWith(accessToken: 'newAccessToken'),
          isFalse,
        );
      });

      test('token equality with different [refreshToken] value', () {
        expect(
          authToken == authToken2.copyWith(refreshToken: 'newRefreshToken'),
          isFalse,
        );
      });

      test('token equality with different [expiresIn] value', () {
        expect(
          authToken == authToken2.copyWith(expiresIn: 99),
          isFalse,
        );
      });

      test('token equality with different [tokenType] value', () {
        expect(
          authToken == authToken2.copyWith(tokenType: 'newTokenType'),
          isFalse,
        );
      });
    });
  });

  test('AuthStatus toString', () {
    expect(
      AuthStatus.unauthenticated(message: 'message').toString(),
      'AuthStatus${{'status': Status.unauthenticated, 'message': 'message'}}',
    );
  });

  group('Bot Memory Token Storage', () {
    late BotMemoryTokenStorage<MockAuthToken> botMemoryTokenStorage;

    setUp(() {
      botMemoryTokenStorage = BotMemoryTokenStorage();
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
      await botMemoryTokenStorage.write(MockAuthToken());
      expect(botMemoryTokenStorage.value, isA<MockAuthToken>());
      expect(botMemoryTokenStorage.stream, emits(isA<MockAuthToken>()));
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
      await botMemoryTokenStorage.write(MockAuthToken());
      botMemoryTokenStorage
        ..delete()
        ..delete();
      await expectLater(
        botMemoryTokenStorage.authenticationStatus.map((event) => event.status),
        emitsInOrder(<Status>[Status.authenticated, Status.unauthenticated]),
      );
    });

    test('delete with message', () async {
      await botMemoryTokenStorage.write(MockAuthToken());
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
      await botTokenStorage.write(MockAuthToken());
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
