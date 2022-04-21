## Refresh Token For Dio


dio_refresh_bot is an interceptor that attempts to simplify custom API authentication by transparently integrating token refresh and caching. 

dio_refresh_bot: is flexible and is intended to support custom token refresh mechanisms.

A [dio](https://pub.dev/packages/dio) interceptor for a built-in token refresh.

## Getting started

### Add dependency [#](https://pub.dev/packages/dio_refresh_bot#add-dependency)

```yaml
dependencies:
  dio_refresh_bot: ^1.0.0 #latest version
```

## Usage

- Create a new instance from Dio

```dart
final dio = Dio();
```

- Creat new class whose has extends from  BotMemoryTokenStorage<AuthToken>

```dart
class TokenStorageImpl extends BotMemoryTokenStorage<AuthToken> {}
```

and you will get override AuthToken init

```dart
// and you will get overrid AuthToken init
@override
  AuthToken? get initValue => const AuthToken(
        accessToken: '<Your Initial Access Token>',
        refreshToken: '<Your Initial Refresh Token>',
        tokenType: '<Your Initial Token Type>',
        // You Can make the token expire in your code
        // without expiring it from the API call (Optional)
        expiresIn: Duration(days: 1),
      );
```

or 

```dart
@override
AuthToken? get initValue => null;
```

- Then Create a new intance from TokenStorageImpl 

```dart
  final storage = TokenStorageImpl();
```

- Then Add RefreshTokenInterceptor to Dio Interceptors 

```dart
  dio.interceptors.add(
    RefreshTokenInterceptor<AuthToken>(
      // pass your dio instance 
      dio: dio,
      // pass your storage instance 
      tokenStorage: storage,
      // we have sperable instance for Dio
      // [tokenDio] you can get your dio instance for refresh method
			// [token] is AuthToken object storage
      refreshToken: (token, tokenDio) async {
        final response = await tokenDio.post<dynamic>(
          '/refresh',
          data: {'refreshToken': token.refreshToken},
        );
        return AuthToken.fromMap(response.data as Map<String, dynamic>);
      },
    ),
  );
```



## Additional information

We add listen for your storage when your token has [ Created, Updated, or Deleted ]

```dart
// listen to the token changes
storage.stream.listen(print);

// listen to auth state changes
storage.authenticationStatus.listen(print);
```
