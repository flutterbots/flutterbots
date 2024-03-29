import 'package:dio/dio.dart';
import 'package:dio_refresh_bot/dio_refresh_bot.dart';

// ignore_for_file: avoid_print
void main() {
  final dio = Dio();

  final storage = BotMemoryTokenStorage<AuthToken>();

  dio.interceptors.add(
    RefreshTokenInterceptor<AuthToken>(
      tokenStorage: storage,
      refreshToken: (token, tokenDio) async {
        final response = await tokenDio.post<dynamic>(
          'https://example/refresh',
          data: {'refreshToken': token.refreshToken},
        );

        return AuthToken.fromMap(response.data as Map<String, dynamic>);
      },
    ),
  );
  // listen to the token changes
  storage.stream.listen(print);

  // listen to auth state changes
  // storage.authenticationStatus.listen(print);
}
