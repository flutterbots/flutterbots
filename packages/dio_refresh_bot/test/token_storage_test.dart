import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAuthToken extends Mock implements AuthToken {}

class MockTokenProtocol extends Mock implements TokenProtocol {}

class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockDioError extends Mock implements DioError {}

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

class BotMemoryTokenStorageImpl extends BotMemoryTokenStorage<MockAuthToken>
    with RefreshBotMixin {}

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
    late BotMemoryTokenStorageImpl botMemoryTokenStorage;

    setUp(() {
      botMemoryTokenStorage = BotMemoryTokenStorageImpl();
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
      Future.delayed(
        Duration.zero,
        () async {
          botMemoryTokenStorage
            ..delete()
            ..delete();
        },
      );
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

  group('TokenProtocol', () {
    late TokenProtocol tokenProtocol;
    late MockResponse<dynamic> mockResponse;
    late MockAuthToken mockAuthToken;
    late MockDioError mockDioError;
    setUpAll(() {
      tokenProtocol = const TokenProtocol();
      mockResponse = MockResponse();
      mockAuthToken = MockAuthToken();
      mockDioError = MockDioError();
    });
    test('by default shouldRefresh must return true if statusCode=401', () {
      when(() => mockResponse.statusCode).thenReturn(401);
      expect(
        tokenProtocol.shouldRefresh(mockResponse, mockAuthToken),
        true,
      );
    });

    test(
        'shouldRefresh must return false if response is not compatible with'
        ' passed shouldRefresh method', () {
      when(() => mockResponse.statusCode).thenReturn(401);
      when(() => mockDioError.response).thenReturn(mockResponse);
      tokenProtocol = TokenProtocol(
        shouldRefresh: (response, token) => response?.statusCode == 400,
      );
      expect(
        tokenProtocol.shouldRefresh(mockResponse, mockAuthToken),
        false,
      );
    });
    test('by default shouldRevokeToken must return true if statusCode=401', () {
      when(() => mockResponse.statusCode).thenReturn(401);
      when(() => mockDioError.response).thenReturn(mockResponse);
      expect(
        tokenProtocol.shouldRevokeToken(mockDioError),
        true,
      );
    });
    test(
        'shouldRevokeToken must return false if response is not compatible with'
        ' passed shouldRevokeToken method', () {
      when(() => mockResponse.statusCode).thenReturn(401);
      when(() => mockDioError.response).thenReturn(mockResponse);
      tokenProtocol = TokenProtocol(
        shouldRevokeToken: (error) => error.response?.statusCode == 405,
      );
      expect(
        tokenProtocol.shouldRevokeToken(mockDioError),
        false,
      );
    });
  });

  group('onRequest', () {
    late MockBotTokenStorage botTokenStorage;
    late RefreshTokenInterceptor interceptor;
    late RequestOptions requestOptions;
    late RequestInterceptorHandler requestHandler;
    setUpAll(() {
      botTokenStorage = MockBotTokenStorage();
      requestHandler = RequestInterceptorHandler();
      requestOptions = RequestOptions(path: '');
    });

    test('token still Null and return unauthenticatedStatus if token is null',
        () async {
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) async {
          return MockAuthToken();
        },
      );
      await interceptor.onRequest(requestOptions, requestHandler);
      expect(botTokenStorage.stream, emits(isNull));
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.unauthenticated),
      );
    });

    test(
        'return exist Token and return authenticationStatus'
        ' if shouldRefresh => false', () async {
      final mockAuthToken = MockAuthToken();
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) async {
          return MockAuthToken();
        },
        tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => false),
      );
      await interceptor.onRequest(requestOptions, requestHandler);
      expect(botTokenStorage.stream, emits(mockAuthToken));
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.authenticated),
      );
    });
    test(
        'return authenticated status and update token'
        ' if: token is not null,'
        ' refresh token request success,'
        ' no another request do refreshing'
        ' and shouldRefresh is true', () async {
      final mockAuthToken = MockAuthToken();
      final newMockAuthToken = MockAuthToken();
      final _refreshToken = (_, __) async => newMockAuthToken;

      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      when(() => newMockAuthToken.accessToken).thenReturn('new-access-token');
      when(() => newMockAuthToken.tokenType).thenReturn('new-bearer');
      requestOptions.extra['__auth_token__'] = mockAuthToken;
      botTokenStorage.write(mockAuthToken);

      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: _refreshToken,
        tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => true),
      );
      await interceptor.onRequest(requestOptions, requestHandler);
      expect(botTokenStorage.stream, emits(newMockAuthToken));

      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.authenticated),
      );
    });

    test(
        'return authenticated status, update token and retry to send request'
        ' if another request already refreshed token', () async {
      final mockAuthToken = MockAuthToken();
      final newMockAuthToken = MockAuthToken();
      final fromAnotherRequestMockAuthToken = MockAuthToken();
      final mockDio = MockDio();
      final _refreshToken = (_, __) async => newMockAuthToken;
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      requestOptions.extra['__auth_token__'] = fromAnotherRequestMockAuthToken;
      botTokenStorage.write(mockAuthToken);

      ///ToDo: mocking dio is not working correctly
      // when(() => mockDio.hashCode).thenReturn(1234);
      // when(() => mockDio.fetch<dynamic>(captureAny()))
      //     .thenAnswer((invocation) async {
      //   print("test mock");
      //   return MockResponse();
      // });
      interceptor = RefreshTokenInterceptor(
        // dio: mockDio,
        tokenStorage: botTokenStorage,
        refreshToken: _refreshToken,
        tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => true),
      );
      await interceptor.onRequest(requestOptions, requestHandler);
      expect(botTokenStorage.stream, emits(fromAnotherRequestMockAuthToken));
      expect(
        botTokenStorage.authenticationStatus.map((event) => event.status),
        emits(Status.authenticated),
      );
    });
  });
}
