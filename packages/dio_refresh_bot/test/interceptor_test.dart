import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'token_storage_test.dart';

class MockTokenProtocol extends Mock implements TokenProtocol {}

class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockDioError extends Mock implements DioError {}

void main() {
  group('TokenProtocol', () {
    late TokenProtocol tokenProtocol;
    late MockResponse<Object> mockResponse;
    late MockAuthToken mockAuthToken;
    late MockDioError mockDioError;
    setUp(() {
      tokenProtocol = const TokenProtocol();
      mockResponse = MockResponse<Object>();
      mockAuthToken = MockAuthToken();
      mockDioError = MockDioError();
    });
    test('by default shouldRefresh must return true if statusCode = 401', () {
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
    setUp(() {
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
      expect(botTokenStorage.read(), isNull);
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
    // test(
    //     'return authenticated status and update token'
    //     ' if: token is not null,'
    //     ' refresh token request success,'
    //     ' no another request do refreshing'
    //     ' and shouldRefresh is true', () async {
    //   final mockAuthToken = MockAuthToken();
    //   final newMockAuthToken = MockAuthToken();
    //
    //   when(() => mockAuthToken.accessToken).thenReturn('access-token');
    //   when(() => mockAuthToken.tokenType).thenReturn('bearer');
    //   when(() => newMockAuthToken.accessToken).thenReturn('new-access-token');
    //   when(() => newMockAuthToken.tokenType).thenReturn('new-bearer');
    //   requestOptions.extra['__auth_token__'] = mockAuthToken;
    //   botTokenStorage.write(mockAuthToken);
    //
    //   interceptor = RefreshTokenInterceptor(
    //     tokenStorage: botTokenStorage,
    //     refreshToken: (_, __) async => newMockAuthToken,
    //     tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => true),
    //   );
    //   await interceptor.onRequest(requestOptions, requestHandler);
    //   expect(botTokenStorage.stream, emits(newMockAuthToken));
    //
    //   expect(
    //     botTokenStorage.authenticationStatus.map((event) => event.status),
    //     emits(Status.authenticated),
    //   );
    // });

    //   test(
    //       'return authenticated status, update token and retry to send request'
    //       ' if another request already refreshed token', () async {
    //     final mockAuthToken = MockAuthToken();
    //     final newMockAuthToken = MockAuthToken();
    //     final fromAnotherRequestMockAuthToken = MockAuthToken();
    //     final mockDio = MockDio();
    //     when(() => mockAuthToken.accessToken).thenReturn('access-token');
    //     when(() => mockAuthToken.tokenType).thenReturn('bearer');
    //     requestOptions.extra['__auth_token__'] = fromAnotherRequestMockAuthToken;
    //     botTokenStorage.write(mockAuthToken);
    //
    //     ///ToDo: mocking dio is not working correctly
    //     // when(() => mockDio.hashCode).thenReturn(1234);
    //     // when(() => mockDio.fetch<dynamic>(captureAny()))
    //     //     .thenAnswer((invocation) async {
    //     //   print("test mock");
    //     //   return MockResponse();
    //     // });
    //     interceptor = RefreshTokenInterceptor(
    //       // dio: mockDio,
    //       tokenStorage: botTokenStorage,
    //       refreshToken: (_, __) async => newMockAuthToken,
    //       tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => true),
    //     );
    //     await interceptor.onRequest(requestOptions, requestHandler);
    //     expect(botTokenStorage.stream, emits(fromAnotherRequestMockAuthToken));
    //     expect(
    //       botTokenStorage.authenticationStatus.map((event) => event.status),
    //       emits(Status.authenticated),
    //     );
    //   });
  });
}
