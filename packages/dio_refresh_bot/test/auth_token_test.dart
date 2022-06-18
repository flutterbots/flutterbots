import 'package:dio_refresh_bot/dio_refresh_bot.dart';
import 'package:test/test.dart';

void main() {
  group('AuthToken', () {
    late AuthToken authToken;
    late AuthToken authToken2;
    late Map<String, dynamic> mapMatcher;
    setUp(() {
      authToken = const AuthToken(
        accessToken: 'accessToken',
        expiresIn: 98,
        refreshToken: 'refreshToken',
        tokenType: 'tokenType',
      );
      authToken2 = const AuthToken(
        accessToken: 'accessToken',
        expiresIn: 98,
        refreshToken: 'refreshToken',
        tokenType: 'tokenType',
      );
      mapMatcher = <String, dynamic>{
        'accessToken': 'accessToken',
        'tokenType': 'tokenType',
        'refreshToken': 'refreshToken',
        'expiresIn': 98,
      };
    });

    test('to map', () {
      expect(authToken.toMap(), mapMatcher);
    });

    test('from map', () {
      expect(AuthToken.fromMap(mapMatcher), authToken);
    });

    test('to string', () {
      expect(
        authToken.toString(),
        'AuthToken$mapMatcher',
      );
    });

    group('token equality', () {
      test('token equality with same values', () {
        expect(authToken == authToken2, isTrue);
      });

      test('token equality with different [accessToken] value', () {
        expect(
          authToken == authToken2.copyWith(accessToken: 'newAccessToken'),
          isFalse,
        );
      });

      test('token equality with different [refreshToken] value', () {
        expect(
          authToken == authToken2.copyWith(refreshToken: 'newRefreshToken'),
          isFalse,
        );
      });

      test('token equality with different [expiresIn] value', () {
        expect(
          authToken == authToken2.copyWith(expiresIn: 99),
          isFalse,
        );
      });

      test('token equality with different [tokenType] value', () {
        expect(
          authToken == authToken2.copyWith(tokenType: 'newTokenType'),
          isFalse,
        );
      });
    });
  });

  test('AuthStatus toString', () {
    expect(
      AuthStatus.unauthenticated(message: 'message').toString(),
      'AuthStatus${{'status': Status.unauthenticated, 'message': 'message'}}',
    );
  });
}
