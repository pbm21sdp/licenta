// lib/services/api_client.dart
// Client HTTP Dio cu interceptors pentru autentificare și error handling

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Adaugă interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
  }

  // Determină URL-ul corect în funcție de platformă
  String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1'; // Emulator Android
    }
    if (Platform.isIOS) {
      return 'http://localhost:5000/api/v1'; // Simulator iOS
    }
    return ApiConfig.baseUrl;
  }

  // Getter pentru Dio instance
  Dio get dio => _dio;

  // Interceptor pentru autentificare
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Adaugă token-ul la header dacă există
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Dacă primim 401, încercăm să reîmprospătăm token-ul
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              // Reîncearcă request-ul original cu noul token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (e) {
            // Refresh a eșuat, utilizatorul trebuie să se autentifice din nou
            await clearTokens();
          }
        }
        return handler.next(error);
      },
    );
  }

  // Interceptor pentru logging (doar în development)
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 REQUEST[${options.method}] => ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');
        print('   Message: ${error.message}');
        return handler.next(error);
      },
    );
  }

  // Reîmprospătează access token-ul folosind refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final response = await Dio().post(
        '${_getBaseUrl()}${ApiConfig.refreshToken}',
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _accessToken = response.data['data']['accessToken'];
        _refreshToken = response.data['data']['refreshToken'];
        await _saveTokens();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Setează token-urile după autentificare
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _saveTokens();
  }

  // Salvează token-urile în SharedPreferences
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  // Încarcă token-urile din SharedPreferences
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  // Șterge token-urile (logout)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Verifică dacă utilizatorul este autentificat
  bool get isAuthenticated => _accessToken != null;

  // Getter pentru access token
  String? get accessToken => _accessToken;

  // ==========================================
  // METODE HELPER PENTRU REQUEST-URI
  // ==========================================

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}

// Clasă pentru erori API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'A apărut o eroare neașteptată';
    int? statusCode = error.response?.statusCode;
    dynamic errors;

    if (error.response?.data != null && error.response?.data is Map) {
      message = error.response?.data['message'] ?? message;
      errors = error.response?.data['errors'];
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Conexiunea a expirat. Verifică conexiunea la internet.';
          break;
        case DioExceptionType.connectionError:
          message = 'Nu se poate conecta la server. Verifică conexiunea la internet.';
          break;
        case DioExceptionType.cancel:
          message = 'Request-ul a fost anulat.';
          break;
        default:
          message = error.message ?? message;
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  @override
  String toString() => message;
}
