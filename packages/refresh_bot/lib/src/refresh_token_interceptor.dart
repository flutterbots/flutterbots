import 'package:dio/dio.dart';

import 'token_storage.dart';

typedef RefreshToken<T> = Future<T> Function(T token, Dio dio);

typedef ShouldRefresh<T> = bool Function(
  Response? response,
  T? token,
);

typedef ShouldRevoke = bool Function(DioError error);

typedef RevokeCallback = String? Function(DioError error);

typedef TokenReader<T> = String Function(DioError error, T token);

/// Function responsible for building the token header(s) give a [token].
typedef TokenHeaderBuilder<T> = Map<String, String> Function(T token);

class RefreshTokenInterceptor<T extends AuthToken> extends QueuedInterceptor {
  /// This function call when the token end, Its return new token
  final RefreshToken<T> refreshToken;

  /// Interface Api class to
  final TokenStorage<T> tokenStorage;

  final TokenHeaderBuilder? tokenHeaderBuilder;

  final Dio dio;

  final TokenProtocol protocol;

  //We need this [_tokenDio] client for refresh token
  final Dio _tokenDio;

  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.refreshToken,
    this.protocol = const TokenProtocol(),
    Dio? tokenDio,
    this.tokenHeaderBuilder,
  }) : _tokenDio = tokenDio ?? Dio(dio.options);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.read();
    if (token != null) {
      options.headers.addAll(_headersBuilder(token));
      options.token = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    T? storageToken = await tokenStorage.read();

    if (response == null ||
        !protocol.shouldRefresh(response, storageToken) ||
        storageToken == null) {
      return handler.next(err);
    }

    //if current storageToken  not equal request headerToken => refreshToken has done by another intercept process
    if (storageToken != err.requestOptions.token) {
      //retry with new storageToken
      await _requestRetry(err.requestOptions, dio).then((response) {
        // complete the request with Response object and other error interceptor(s) will not be executed.
        handler.resolve(response);
      }).catchError((error, stackTrace) {
        //retry error
        //when error occur, continue to call the next error interceptor.
        handler.next(error);
      });
    } else {
      _refreshToken(storageToken, err, handler);
    }
  }

  Future<void> _refreshToken(
      T token, DioError error, ErrorInterceptorHandler handler) async {
    refreshToken(token, _tokenDio).then((newToken) async {
      await tokenStorage.write(newToken);
      _requestRetry(error.requestOptions, dio).then((response) {
        // complete the request with Response object and other error interceptor(s) will not be executed.
        handler.resolve(response);
      }).catchError((error, stackTrace) {
        //retry error
        //when error occur, continue to call the next error interceptor.
        handler.next(error);
      });
    }).catchError(
      (error, stackTrace) {
        //refresh token error
        //when error occur, continue to call the next error interceptor.
        handler.next(error);
        if (error is DioError && protocol.shouldRevokeToken(error)) {
          tokenStorage.delete(protocol.onRevoked?.call(error));
        }
      },
    );
  }

  _requestRetry(RequestOptions requestOptions, Dio dio) {
    return dio.fetch(requestOptions);
  }

  Map<String, String> _headersBuilder(T token) {
    final tokenBuilder = tokenHeaderBuilder ?? _defaultTokenHeaderBuilder;
    return tokenBuilder(token);
  }

  Map<String, String> _defaultTokenHeaderBuilder(T token) {
    return {'Authorization': '${token.tokenType} ' + token.accessToken};
  }
}

class TokenProtocol<T extends AuthToken> {
  final RevokeCallback? onRevoked;

  final ShouldRevoke shouldRevokeToken;

  final ShouldRefresh<T> shouldRefresh;

  const TokenProtocol({
    this.onRevoked,
    this.shouldRevokeToken = _shouldRevokeToken,
    this.shouldRefresh = _shouldRefresh,
  });

  static bool _shouldRefresh<T extends AuthToken>(Response? response, _) {
    return response?.statusCode == 401;
  }

  static bool _shouldRevokeToken(DioError error) {
    final response = error.response;
    return response?.statusCode == 403 || response?.statusCode == 401;
  }
}

extension RequestOptionsExtention on RequestOptions {
  static const _kTokenKey = 'auth-token';

  set token(AuthToken? token) => extra[_kTokenKey] = token;

  AuthToken? get token => extra[_kTokenKey] as AuthToken?;
}
