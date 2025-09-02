class RegisterRequest {
  final String name;
  final String email;
  final String phoneNumber;
  final String username;
  final String password;
  final String confirmPassword;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'role': 'CUSTOMER',
      'fullName': name,
      'phoneNumber': phoneNumber,
    };
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class OtpVerificationRequest {
  final String email;
  final String otp;

  OtpVerificationRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final String username;
  final String email;
  final String role;
  final bool passwordChangeRequired;
  final bool isTemporaryPassword;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.username,
    required this.email,
    required this.role,
    required this.passwordChangeRequired,
    required this.isTemporaryPassword,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      passwordChangeRequired: json['passwordChangeRequired'] ?? false,
      isTemporaryPassword: json['isTemporaryPassword'] ?? false,
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final String? fullName;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    this.fullName,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      isActive: json['isActive'] ?? true,
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'isActive': isActive,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }
}

class ApiError {
  final String message;
  final String code;
  final int statusCode;

  ApiError({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] ?? 'Unknown error occurred',
      code: json['statusCode'] ?? 'UNKNOWN_ERROR',
      statusCode: json['status'] ?? 500,
    );
  }
}