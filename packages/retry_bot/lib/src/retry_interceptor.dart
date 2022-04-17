import 'package:dio/dio.dart';
import 'package:packages.retry_bot/src/dio_connectivity_request.dart';

///
class OnRetryConnection extends Interceptor {
  /// here you can docs
  OnRetryConnection({required this.request, this.onTimeOut});

  /// here you can docs
  final DioConnectivityRequest request;

  /// here you can docs
  final Function()? onTimeOut;

  /// here you can docs

  /// here you can docs
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

  /// here you can docs
  bool _shouldRetry(DioError error) {
    final status = error.type != DioErrorType.cancel && error.type != DioErrorType.response;
    if (_isTimeOut(error)) {
      onTimeOut!();
    }
    return status;
  }

  /// here you can docs
  bool _isTimeOut(DioError error) =>
      error.type == DioErrorType.connectTimeout ||
      error.type == DioErrorType.sendTimeout ||
      error.type == DioErrorType.receiveTimeout;
}
