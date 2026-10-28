class UserAuthModel {
  final int id;
  final String name;
  final String email;
  final String msisdn;

  const UserAuthModel({
    required this.id,
    required this.name,
    required this.email,
    this.msisdn = '',
  });

  factory UserAuthModel.fromJson(Map<String, dynamic> json) {
    return UserAuthModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      msisdn: json['msisdn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'msisdn': msisdn,
    };
  }
}

class AuthResponseData {
  final String accessToken;
  final String? refreshToken;
  final UserAuthModel user;
  final String? installationId;
  final bool deviceTokenRegistered;

  const AuthResponseData({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.installationId,
    this.deviceTokenRegistered = false,
  });

  /// Backend returns the user fields flat alongside the tokens
  /// (see POST /api/auth/login), so fall back to the root object when
  /// no nested `user` key is present.
  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    return AuthResponseData(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      user: UserAuthModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? json,
      ),
      installationId: json['installation_id'] as String?,
      deviceTokenRegistered: json['device_token_registered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  /// FCM registration. The backend requires both or neither.
  final String? deviceToken;
  final String? deviceType;

  /// Returned by the BE on first login; resend so one phone stays one device.
  final String? installationId;

  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceToken,
    this.deviceType,
    this.installationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (installationId != null && installationId!.isNotEmpty)
        'installation_id': installationId,
      if (deviceToken != null && deviceType != null) ...{
        'device_token': deviceToken,
        'device_type': deviceType,
      },
    };
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String msisdn;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.msisdn,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'msisdn': msisdn,
      'password': password,
    };
  }
}
