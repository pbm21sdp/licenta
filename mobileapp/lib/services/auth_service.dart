// lib/services/auth_service.dart
// Serviciu pentru autentificare

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../data/models/user_model.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final ApiClient _apiClient = ApiClient();
  UserModel? _currentUser;

  AuthService._internal();

  // Getter pentru utilizatorul curent
  UserModel? get currentUser => _currentUser;

  // Verifică dacă utilizatorul este autentificat
  bool get isLoggedIn => _apiClient.isAuthenticated && _currentUser != null;

  // Verifică dacă utilizatorul este admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // ==========================================
  // AUTENTIFICARE
  // ==========================================

  /// Login cu email și parolă
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.accessToken != null) {
        // Salvează token-urile
        await _apiClient.setTokens(
          authResponse.accessToken!,
          authResponse.refreshToken!,
        );

        // Salvează utilizatorul
        _currentUser = authResponse.user;
      }

      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Înregistrare utilizator nou
  Future<AuthResponse> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.accessToken != null) {
        // Salvează token-urile
        await _apiClient.setTokens(
          authResponse.accessToken!,
          authResponse.refreshToken!,
        );

        // Salvează utilizatorul
        _currentUser = authResponse.user;
      }

      return authResponse;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _apiClient.clearTokens();
    _currentUser = null;
  }

  /// Verificare email
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.verifyEmail,
        data: {'token': token},
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Resend verificare email
  Future<bool> resendVerification(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.resetPassword,
        data: {
          'token': token,
          'password': newPassword,
        },
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Schimbare parolă
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // PROFIL UTILIZATOR
  // ==========================================

  /// Obține profilul utilizatorului curent
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConfig.me);

      if (response.data['success'] == true && response.data['data']?['user'] != null) {
        _currentUser = UserModel.fromJson(response.data['data']['user']);
        return _currentUser;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Actualizează profilul utilizatorului
  Future<UserModel?> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _apiClient.put(
        ApiConfig.updateProfile,
        data: data,
      );

      if (response.data['success'] == true && response.data['data']?['user'] != null) {
        _currentUser = UserModel.fromJson(response.data['data']['user']);
        return _currentUser;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // SESIUNE
  // ==========================================

  /// Încarcă sesiunea existentă (la pornirea aplicației)
  Future<bool> loadSession() async {
    try {
      await _apiClient.loadTokens();

      if (_apiClient.isAuthenticated) {
        final user = await getCurrentUser();
        return user != null;
      }
      return false;
    } catch (e) {
      // Token expirat sau invalid, curățăm sesiunea
      await logout();
      return false;
    }
  }

  /// Refresh token manual
  Future<bool> refreshSession() async {
    try {
      final response = await _apiClient.post(ApiConfig.refreshToken);

      if (response.data['success'] == true) {
        await _apiClient.setTokens(
          response.data['data']['accessToken'],
          response.data['data']['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
