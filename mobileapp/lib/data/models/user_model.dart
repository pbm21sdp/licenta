// lib/data/models/user_model.dart
// Model pentru datele utilizatorului

class UserModel {
  final int id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final bool isAdmin;
  final bool? mfaEnabled;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.isVerified,
    required this.isAdmin,
    this.mfaEnabled,
    this.lastLogin,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
      mfaEnabled: json['mfaEnabled'] ?? json['mfa_enabled'],
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'mfaEnabled': mfaEnabled,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? isVerified,
    bool? isAdmin,
    bool? mfaEnabled,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Model pentru răspunsul de autentificare
class AuthResponse {
  final bool success;
  final String message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final bool? requiresMFA;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.requiresMFA,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['data']?['user'] != null
          ? UserModel.fromJson(json['data']['user'])
          : null,
      accessToken: json['data']?['accessToken'],
      refreshToken: json['data']?['refreshToken'],
      requiresMFA: json['requiresMFA'],
    );
  }
}
