import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:meta/meta.dart';

/// Function for refresh token and return a new one
typedef RefreshToken<T> = Future<T> Function(T token, Dio tokenDio);

/// Function to decide if we need to refresh token depending on [Response]
/// and [token] value
typedef ShouldRefresh<T> = bool Function(
  Response<dynamic>? response,
  T? token,
);

/// Function to decide when we should revoke the token depending on [DioError]
typedef ShouldRevoke = bool Function(DioError error);

/// Function for Taking the the an action when the token is revoked
///
/// from this function we can return meaningful message
///
typedef RevokeCallback = String? Function(DioError error);

/// Function responsible for building the token header.
typedef TokenHeaderBuilder<T> = Map<String, String> Function(T token);

///
typedef OnRefreshResponse = void Function(Response<dynamic> response);

///
typedef OnRefreshError = void Function(DioError error);

///
class RefreshTokenInterceptor<T extends AuthToken> extends QueuedInterceptor {
  ///
  RefreshTokenInterceptor({
    required this.tokenStorage,
    required this.refreshToken,
    this.onRevoked,
    this.tokenProtocol = const TokenProtocol(),
    Dio? tokenDio,
    this.debugLog = false,
    this.tokenHeaderBuilder,
  }) : _tokenDio = tokenDio ?? Dio() {
    _tokenDio.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8'
    };

    if (debugLog && tokenDio == null) {
      _tokenDio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }
  }

  /// This function called when we should refresh the token
  /// and Its returns a new token
  ///
  /// refer to [TokenProtocol] for shouldRefresh
  ///
  final RefreshToken<T> refreshToken;

  /// This function will be triggered if the token revoked
  /// and the refresh token is failed.
  ///
  /// We can optionally return a reason message or null.
  ///
  /// refer to [TokenProtocol] for shouldRevoke
  ///
  final RevokeCallback? onRevoked;

  /// Interface API class to read, write and delete token from storage or memory
  final BotTokenStorageType<T> tokenStorage;

  /// Function for building custom token header depending on stored token
  final TokenHeaderBuilder<T>? tokenHeaderBuilder;

  /// The [TokenProtocol] for refresh token process
  final TokenProtocol tokenProtocol;

  /// If it is enabled will print logs during refresh token request.
  final bool debugLog;

  final Dio _tokenDio;

  ///no-doc
  @visibleForTesting
  Dio get dio => _tokenDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var token = tokenStorage.read();
    if (token != null) {
      _buildHeader(options, token);
      if (tokenProtocol.shouldRefresh(null, token)) {
        await _refreshHandler(
          token,
          options,
          onResponse: (response) {
            token = tokenStorage.read();
            _buildHeader(options, token!);
            handler.resolve(response);
          },
          onError: (error) {
            handler.reject(error);
          },
        );
      } else {
        handler.next(options);
      }
    } else {
      handler.next(options);
    }
  }

  void _buildHeader(RequestOptions options, T token) {
    options.headers.addAll(_headersBuilder(token));
    options.token = token;
  }

  @override
  Future<void> onError(DioError err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final storageToken = tokenStorage.read();

    if (storageToken == null ||
        !tokenProtocol.shouldRefresh(response, storageToken)) {
      return handler.next(err);
    }

    await _refreshHandler(
      storageToken,
      err.requestOptions,
      onResponse: (response) {
        handler.resolve(response);
      },
      onError: (error) {
        handler.next(error);
      },
    );
  }

  Future<void> _refreshHandler(
    T storageToken,
    RequestOptions options, {
    required OnRefreshResponse onResponse,
    required OnRefreshError onError,
  }) async {
    try {
      // if current storageToken not equal request token
      // then => refreshToken has done by another intercept process
      if (storageToken != options.token) {
        // retry with new storageToken
        await _requestRetry(
          options,
          storageToken,
        ).then(onResponse);
      } else {
        await _refreshToken(
          storageToken,
          options,
          onResponse: onResponse,
        );
      }
    } catch (error, stackTrace) {
      late final DioError dioError;

      if (error is! DioError) {
        dioError = DioError(
          requestOptions: options,
          stackTrace: stackTrace,
          error: error,
        );
      } else {
        dioError = error;
      }

      if (tokenProtocol.shouldRevokeToken(dioError)) {
        await tokenStorage.delete(onRevoked?.call(dioError));
      }

      onError(dioError);
    }
  }

  Future<void> _refreshToken(
    T token,
    RequestOptions options, {
    required OnRefreshResponse onResponse,
  }) async {
    final newToken = await refreshToken(token, _tokenDio);
    await tokenStorage.write(newToken);

    final response = await _requestRetry(
      options,
      newToken,
    );
    onResponse(response);
  }

  Future<Response<dynamic>> _requestRetry(
    RequestOptions requestOptions,
    T token,
  ) {
    return _tokenDio.fetch<dynamic>(
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

/// Two functions wrapped in simple class
/// when we should refresh or revoke the token this is a protocol :)
///
class TokenProtocol<T extends AuthToken> {
  /// Provide a handy TokenProtocol
  /// and pass [shouldRevokeToken] and [shouldRefresh] wrapped functions to it
  ///
  const TokenProtocol({
    this.shouldRevokeToken = _shouldRevokeToken,
    this.shouldRefresh = _shouldRefresh,
  });

  /// [shouldRevokeToken] - check if we should revoke token.
  ///
  /// If refresh token throw [DioError] we should revoke the
  /// token for specific errors.
  ///
  /// the default when the response status code is 403 or 401
  ///
  final ShouldRevoke shouldRevokeToken;

  /// [shouldRefresh] - check if we should refresh token
  ///
  /// the default when response status code is 401
  ///
  final ShouldRefresh<T> shouldRefresh;

  static bool _shouldRefresh(
    Response<dynamic>? response,
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
