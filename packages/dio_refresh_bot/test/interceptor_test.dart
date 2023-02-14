import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'token_storage_test.dart';

class MockTokenProtocol extends Mock implements TokenProtocol {}

class MockDio extends Mock implements Dio {}

class MockRequestOptions extends Mock implements RequestOptions {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockDioError extends Mock implements DioError {}

class MockException extends Mock implements Exception {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockResponse<dynamic>());
    registerFallbackValue(MockDioError());
  });

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

  group('Interceptor', () {
    late BotTokenStorageImpl botTokenStorage;
    late RefreshTokenInterceptor interceptor;
    late RequestOptions requestOptions;
    late MockRequestOptions refreshRequestOptions;
    late MockRequestInterceptorHandler requestInterceptorHandler;
    late MockErrorInterceptorHandler errorInterceptorHandler;
    late MockDioError dioError;
    late MockException mockException;
    late MockResponse<dynamic> response;
    late MockResponse<dynamic> successResponse;
    late MockAuthToken mockAuthToken;
    late MockAuthToken newMockAuthToken;
    late MockDio dio;
    setUp(() {
      botTokenStorage = BotTokenStorageImpl();
      requestInterceptorHandler = MockRequestInterceptorHandler();
      errorInterceptorHandler = MockErrorInterceptorHandler();
      requestOptions = RequestOptions();
      refreshRequestOptions = MockRequestOptions();
      dioError = MockDioError();
      mockException = MockException();
      response = MockResponse<dynamic>();
      successResponse = MockResponse<dynamic>();
      mockAuthToken = MockAuthToken();
      newMockAuthToken = MockAuthToken();
      dio = MockDio();
      requestOptions.extra['__auth_token__'] = mockAuthToken;
    });

    test('Logger', () async {
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        debugLog: true,
        refreshToken: (_, __) async {
          return MockAuthToken();
        },
      );
      expect(
        interceptor.dio.interceptors.any(
          (element) => element is LogInterceptor,
        ),
        true,
      );
    });

    test(
        '[onRequest] Continue to call the next request interceptor with '
        'absent token header', () async {
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) async {
          return MockAuthToken();
        },
      );
      await interceptor.onRequest(requestOptions, requestInterceptorHandler);
      expect(requestOptions.headers['Authorization'], isNull);
      verify(
        () => requestInterceptorHandler.next(requestOptions),
      ).called(1);
    });

    test(
        '[onRequest] Continue to call the next request interceptor '
        'with token header', () async {
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
      await interceptor.onRequest(requestOptions, requestInterceptorHandler);
      expect(
        requestOptions.headers['Authorization'],
        '${mockAuthToken.tokenType} ${mockAuthToken.accessToken}',
      );
      verify(
        () => requestInterceptorHandler.next(requestOptions),
      ).called(1);
    });

    test('[onRequest] Refresh token will be triggered if token is expired',
        () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      when(() => newMockAuthToken.accessToken).thenReturn('new-access-token');
      when(() => newMockAuthToken.tokenType).thenReturn('new-bearer');
      when(() => dio.fetch<dynamic>(requestOptions))
          .thenAnswer((invocation) async => successResponse);
      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        tokenDio: dio,
        refreshToken: (_, __) async {
          return newMockAuthToken;
        },
        tokenProtocol: TokenProtocol(
          shouldRefresh: (_, __) => true,
        ),
      );
      await interceptor.onRequest(requestOptions, requestInterceptorHandler);
      expect(
        requestOptions.headers['Authorization'],
        '${newMockAuthToken.tokenType} ${newMockAuthToken.accessToken}',
      );
      verify(
        () => requestInterceptorHandler.resolve(successResponse),
      ).called(1);
      expect(botTokenStorage.read(), newMockAuthToken);
    });

    test(
        '[onRequest][Fail][shouldRevokeToken => false] '
        'Refresh token will be triggered if token is expired', () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        tokenDio: dio,
        refreshToken: (_, __) async {
          throw dioError;
        },
        tokenProtocol: TokenProtocol(
          shouldRefresh: (_, __) => true,
          shouldRevokeToken: (_) => false,
        ),
      );
      await interceptor.onRequest(requestOptions, requestInterceptorHandler);
      verify(
        () => requestInterceptorHandler.reject(dioError),
      ).called(1);
      expect(botTokenStorage.read(), mockAuthToken);
    });

    test(
        '[onRequest][Fail][shouldRevokeToken => true] Refresh token will be '
        'triggered if token is expired', () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        tokenDio: dio,
        refreshToken: (_, __) async {
          throw dioError;
        },
        tokenProtocol: TokenProtocol(
          shouldRefresh: (_, __) => true,
          shouldRevokeToken: (_) => true,
        ),
      );
      await interceptor.onRequest(requestOptions, requestInterceptorHandler);
      verify(
        () => requestInterceptorHandler.reject(dioError),
      ).called(1);
      expect(botTokenStorage.read(), null);
    });

    test('[onError] with error other than 401', () async {
      when(() => response.statusCode).thenReturn(500);
      when(() => dioError.response).thenReturn(response);
      when(() => dioError.requestOptions).thenReturn(requestOptions);

      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) async => MockAuthToken(),
      );

      await interceptor.onError(dioError, errorInterceptorHandler);
      verifyNever(
        () => mockAuthToken.accessToken,
      );
      verify(
        () => errorInterceptorHandler.next(dioError),
      ).called(1);
      expect(botTokenStorage.read(), mockAuthToken);
    });

    test('[onError] refresh token throwing an error other than DioError',
        () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      when(() => response.statusCode).thenReturn(401);
      when(() => dioError.response).thenReturn(response);
      when(() => dioError.requestOptions).thenReturn(requestOptions);

      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) => throw mockException,
      );

      await interceptor.onError(dioError, errorInterceptorHandler);
      verify(
        () => errorInterceptorHandler.next(any()),
      ).called(1);
      expect(botTokenStorage.read(), mockAuthToken);
    });

    test('[onError] Refresh token when response status code is 401', () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      when(() => newMockAuthToken.accessToken).thenReturn('new-access-token');
      when(() => newMockAuthToken.tokenType).thenReturn('new-bearer');
      when(() => response.statusCode).thenReturn(401);
      when(() => successResponse.statusCode).thenReturn(200);
      when(() => successResponse.requestOptions).thenReturn(requestOptions);
      when(() => dioError.response).thenReturn(response);
      when(() => dioError.requestOptions).thenReturn(requestOptions);
      when(() => dio.fetch<dynamic>(requestOptions)).thenAnswer(
        (_) async => successResponse,
      );

      await botTokenStorage.write(mockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenDio: dio,
        tokenStorage: botTokenStorage,
        refreshToken: (_, __) async => newMockAuthToken,
        tokenProtocol: TokenProtocol(shouldRefresh: (_, __) => true),
      );
      await interceptor.onError(dioError, errorInterceptorHandler);

      verify(
        () => errorInterceptorHandler.resolve(successResponse),
      ).called(1);

      expect(botTokenStorage.read(), newMockAuthToken);
    });

    test(
        '[onError] Refresh token will be skipped when response status '
        'code is 401 && token has been changed', () async {
      when(() => mockAuthToken.accessToken).thenReturn('access-token');
      when(() => mockAuthToken.tokenType).thenReturn('bearer');
      when(() => newMockAuthToken.accessToken).thenReturn('new-access-token');
      when(() => newMockAuthToken.tokenType).thenReturn('new-bearer');
      when(() => response.statusCode).thenReturn(401);
      when(() => successResponse.statusCode).thenReturn(200);
      when(() => successResponse.requestOptions).thenReturn(requestOptions);
      when(() => dioError.response).thenReturn(response);
      when(() => dioError.requestOptions).thenReturn(requestOptions);
      when(() => dio.fetch<dynamic>(requestOptions)).thenAnswer(
        (_) async => successResponse,
      );
      when(() => dio.fetch<dynamic>(refreshRequestOptions)).thenAnswer(
        (_) async => MockResponse<dynamic>(),
      );

      await botTokenStorage.write(newMockAuthToken);
      interceptor = RefreshTokenInterceptor(
        tokenDio: dio,
        tokenStorage: botTokenStorage,
        refreshToken: (_, dio) async {
          await dio.fetch<dynamic>(refreshRequestOptions);
          return MockAuthToken();
        },
      );
      await interceptor.onError(dioError, errorInterceptorHandler);
      expect(
        requestOptions.headers['Authorization'],
        '${newMockAuthToken.tokenType} ${newMockAuthToken.accessToken}',
      );
      verify(
        () => errorInterceptorHandler.resolve(successResponse),
      ).called(1);
      verifyNever(
        () => dio.fetch<dynamic>(refreshRequestOptions),
      );
    });
  });
}
