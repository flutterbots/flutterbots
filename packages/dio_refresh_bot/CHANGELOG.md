## 2.2.1

- **FIX**: downgrades metadata to 1.12.0.

## 2.2.0

- **CHORE**: updates packages.

## 2.1.2

- **FIX**: build token header for `onRequest`.

## 2.1.1

- **FEAT**: add defaultTokenType `bearer' to `AuthToken.fromMap`.

## 2.1.0

- **FEAT**: add optional debugLog for refreshToken request.
- **FIX**: handle `refreshToken` error when his type is not `DioError`.

## 2.0.0+1

> Note: This release has breaking changes.

- **FIX**: add shouldRefresh implementation for onRequest.
- **BREAKING**: remove un-needed dio from `RefreshTokenInterceptor`.

## 1.0.6

* chore: fix local path conflict with bot_storage

## 1.0.5

* test: add test files.

## 1.0.4

* chore: pump up dependencies.

## 1.0.3+1

* build: downgrade meta to 1.7.0

## 1.0.3

* feat: AuthToken implements `Equatable`.
* fix: add should refresh to onRequest.
* chore: pump up dependencies.

## 1.0.2

* fix: token stream event has not been added.
* update example.

## 1.0.0+1

* add readme.

## 1.0.0

* initial release.
