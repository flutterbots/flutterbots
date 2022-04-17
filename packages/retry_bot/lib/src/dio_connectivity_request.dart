import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

///
class DioConnectivityRequest {
  ///
  DioConnectivityRequest({
    required this.dio,
    required this.connectivity,
  });

  ///
  final Dio dio;

  ///
  final Connectivity connectivity;

  ///
  Future<Response> scheduleRequestRetry(RequestOptions requestOptions) async {
    late StreamSubscription streamSubscription;
    final responseCompleter = Completer<Response>();

    streamSubscription = connectivity.onConnectivityChanged.listen(
      (connectivityResult) {
        if (connectivityResult != ConnectivityResult.none) {
          streamSubscription.cancel();
          responseCompleter.complete(
            dio.request<dynamic>(
              requestOptions.path,
              cancelToken: requestOptions.cancelToken,
              data: requestOptions.data,
              onReceiveProgress: requestOptions.onReceiveProgress,
              onSendProgress: requestOptions.onSendProgress,
              queryParameters: requestOptions.queryParameters,
              options: Options(
                headers: requestOptions.headers,
                extra: requestOptions.extra,
                contentType: requestOptions.contentType,
                followRedirects: requestOptions.followRedirects,
                listFormat: requestOptions.listFormat,
                maxRedirects: requestOptions.maxRedirects,
                method: requestOptions.method,
                receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
                receiveTimeout: requestOptions.receiveTimeout,
                requestEncoder: requestOptions.requestEncoder,
                responseDecoder: requestOptions.responseDecoder,
                responseType: requestOptions.responseType,
                sendTimeout: requestOptions.sendTimeout,
                validateStatus: requestOptions.validateStatus,
              ),
            ),
          );
        }
      },
    );

    return responseCompleter.future;
  }
}
