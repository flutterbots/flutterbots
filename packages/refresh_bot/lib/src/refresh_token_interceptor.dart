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
  final TokenReader<T>? tokenReader;

  /// Interface Api class to
  final TokenStorage<T> tokenStorage;

  final TokenHeaderBuilder? tokenHeaderBuilder;

  final Dio dio;

  final TokenProtocol protocol;

  //We need this [_tokenDio] client for refresh token
  final Dio _tokenDio;

  // save request token in map using [RequestOptions] hash code
  // compare map token with storage token to avoid unnecessary refresh token
  // if you use  custom token model make sure you implement equal operator `==` in the right way
  final Map<int, T?> _activeRequestTokens;

  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.refreshToken,
    this.tokenReader,
    this.protocol = const TokenProtocol(),
    Dio? tokenDio,
    this.tokenHeaderBuilder,
  })  : _tokenDio = tokenDio ?? Dio(dio.options),
        _activeRequestTokens = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.read();
    _activeRequestTokens[options.hashCode] = token;
    if (token != null) {
      options.headers.addAll(_headersBuilder(token));
    }
    options.hashCode;
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
    final headerToken = _activeRequestTokens[err.requestOptions.hashCode];
    if (storageToken != headerToken) {
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

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _removeToken(response.requestOptions);
    handler.next(response);
  }

  Future<void> _refreshToken(
      T token, DioError error, ErrorInterceptorHandler handler) async {
    refreshToken(token, _tokenDio).then((newToken) async {
      await tokenStorage.write(newToken);
      _requestRetry(error.requestOptions, dio).then((response) {
        // complete the request with Response object and other error interceptor(s) will not be executed.
        handler.resolve(response);
        _removeToken(error.requestOptions);
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

  _removeToken(RequestOptions requestOptions) {
    _activeRequestTokens.remove(requestOptions.hashCode);
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
