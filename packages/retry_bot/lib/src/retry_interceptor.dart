import 'package:dio/dio.dart';

import 'package:retry_bot/src/dio_connectivity_request.dart';

/// Handle your connection with interceptor
class OnRetryConnection extends Interceptor {
  /// pass your request has scheduleRequestRetry depend on dio and connectivity
  OnRetryConnection({required this.request, this.onTimeOut});

  /// your request has stream method with dio  requests
  final DioConnectivityRequest request;

  /// put your event when you get timeout connections
  final Function()? onTimeOut;

  /// handle your error
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (_shouldRetry(err)) {
      try {
        request.scheduleRequestRetry(err.requestOptions);
      } catch (e) {
        handler.next(err.error as DioError);
      }
    } else {
      handler.reject(err);
    }
  }

  /// when should retry
  bool _shouldRetry(DioError error) {
    final status = error.type != DioErrorType.cancel &&
        error.type != DioErrorType.response;
    if (_isTimeOut(error)) {
      onTimeOut!();
    }
    return status;
  }

  /// timeout condition
  bool _isTimeOut(DioError error) =>
      error.type == DioErrorType.connectTimeout ||
      error.type == DioErrorType.sendTimeout ||
      error.type == DioErrorType.receiveTimeout;
}
