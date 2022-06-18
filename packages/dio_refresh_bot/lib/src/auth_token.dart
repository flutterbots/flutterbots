import 'package:equatable/equatable.dart';

///
class AuthToken extends Equatable {
  ///
  const AuthToken({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.refreshToken,
    this.expiresIn,
  });

  ///
  factory AuthToken.fromMap(Map<String, dynamic> map) {
    return AuthToken(
      accessToken: map['accessToken'] as String,
      tokenType: map['tokenType'] as String,
      refreshToken: map['refreshToken'] as String?,
      expiresIn: map['expiresIn'] as int?,
    );
  }

  /// The access token as a string.
  final String accessToken;

  /// The type of token, the default is “bearer”
  final String tokenType;

  /// Token which can be used to obtain another access token.
  final String? refreshToken;

  ///
  final int? expiresIn;

  ///
  AuthToken copyWith({
    String? accessToken,
    String? tokenType,
    String? refreshToken,
    int? expiresIn,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  ///
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'tokenType': tokenType,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }

  @override
  String toString() {
    return 'AuthToken${toMap()}';
  }

  @override
  List<Object?> get props => [accessToken, tokenType, refreshToken, expiresIn];
}
