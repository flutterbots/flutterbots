import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/src/token_storage.dart';

/// Function for refresh token and return a new one
typedef RefreshToken<T> = Future<T> Function(T token, Dio tokenDio);

/// Function to decide if we need to refresh token depending on [Response]
/// and [token] value
typedef ShouldRefresh<T> = bool Function(
  Response? response,
  T? token,
);

/// Function to decide when we should revoke the token depending on [DioError]
typedef ShouldRevoke = bool Function(DioError error);

/// Function for Taking the the an action when the token is revoked
///
/// from this function we can return meaningful message
typedef RevokeCallback = String? Function(DioError error);

/// Function responsible for building the token header.
typedef TokenHeaderBuilder<T> = Map<String, String> Function(T token);

///
class RefreshTokenInterceptor<T extends AuthToken> extends QueuedInterceptor {
  ///
  RefreshTokenInterceptor({
    Dio? dio,
    required this.tokenStorage,
    required this.refreshToken,
    this.onRevoked,
    this.tokenProtocol = const TokenProtocol(),
    Dio? tokenDio,
    this.tokenHeaderBuilder,
  })  : _dio = dio ?? Dio(),
        _tokenDio = tokenDio ?? Dio(dio?.options);

  /// This function called when we should refresh the token
  /// and Its returns a new token
  ///
  /// refer to [TokenProtocol] for shouldRefresh
  final RefreshToken<T> refreshToken;

  /// This function will be triggered if the token revoked
  /// and the refresh token is failed
  ///
  /// refer to [TokenProtocol] for shouldRevoke
  final RevokeCallback? onRevoked;

  /// Interface API class to read, write and delete token from storage or memory
  final BotTokenStorageType<T> tokenStorage;

  /// Function for building custom token header depending on stored token
  final TokenHeaderBuilder? tokenHeaderBuilder;

  /// The [TokenProtocol] for refresh token process
  final TokenProtocol tokenProtocol;

  final Dio _tokenDio;

  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = tokenStorage.read();
    if (token != null) {
      options.headers.addAll(_headersBuilder(token));
      options.token = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final storageToken = tokenStorage.read();

    if (response == null ||
        !tokenProtocol.shouldRefresh(response, storageToken) ||
        storageToken == null) {
      return handler.next(err);
    }

    // if current storageToken not equal request token
    // then => refreshToken has done by another intercept process
    if (storageToken != err.requestOptions.token) {
      // retry with new storageToken
      await _requestRetry(
        err.requestOptions,
        storageToken,
      ).then((response) {
        handler.resolve(response);
      }).catchError((Object error, StackTrace stackTrace) {
        handler.next(error as DioError);
      });
    } else {
      await _refreshToken(storageToken, err, handler);
    }
  }

  Future<void> _refreshToken(
    T token,
    DioError error,
    ErrorInterceptorHandler handler,
  ) async {
    return refreshToken(token, _tokenDio).then((newToken) async {
      tokenStorage.write(newToken);
      await _requestRetry(
        error.requestOptions,
        newToken,
      ).then((Response response) {
        handler.resolve(response);
      }).catchError((Object error, StackTrace stackTrace) {
        handler.next(error as DioError);
      });
    }).
        //refresh token error
        catchError(
      (Object error, StackTrace stackTrace) async {
        if (tokenProtocol.shouldRevokeToken(error as DioError)) {
          await tokenStorage.delete(onRevoked?.call(error));
        }
        handler.next(error);
      },
    );
  }

  Future<Response> _requestRetry(
    RequestOptions requestOptions,
    T token,
  ) {
    return _dio.fetch<dynamic>(
      requestOptions
        ..headers.addAll(
          _headersBuilder(token),
        ),
    );
  }

  Map<String, String> _headersBuilder(T token) {
    final tokenBuilder = tokenHeaderBuilder ?? _defaultTokenHeaderBuilder;
    return tokenBuilder(token);
  }

  Map<String, String> _defaultTokenHeaderBuilder(T token) {
    return {'Authorization': '${token.tokenType} ${token.accessToken}'};
  }
}

/// Two functions wrapped in simple protocol class
/// when we should refresh or revoke the token this is a protocol :)
class TokenProtocol<T extends AuthToken> {
  /// Provide a handy TokenProtocol
  /// and pass [shouldRevokeToken] and [shouldRefresh] wrapped functions to it
  const TokenProtocol({
    this.shouldRevokeToken = _shouldRevokeToken,
    this.shouldRefresh = _shouldRefresh,
  });

  /// If refresh token throw [DioError] we should revoke the
  /// token for specific errors
  ///
  /// the default when the response status code is 403 or 401
  /// we can optionally return a reason message or null
  final ShouldRevoke shouldRevokeToken;

  /// the default when response status code is 401
  final ShouldRefresh<T> shouldRefresh;

  static bool _shouldRefresh(
    Response? response,
    dynamic _,
  ) {
    return response?.statusCode == 401;
  }

  static bool _shouldRevokeToken(DioError error) {
    final response = error.response;
    return response?.statusCode == 403 || response?.statusCode == 401;
  }
}

extension _RequestOptionsExtention on RequestOptions {
  static const _kTokenKey = '__auth_token__';

  set token(AuthToken? token) => extra[_kTokenKey] = token;

  AuthToken? get token => extra[_kTokenKey] as AuthToken?;
}
