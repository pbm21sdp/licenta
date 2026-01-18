// lib/services/preference_service.dart
// Serviciu pentru gestionarea preferințelor utilizatorului

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class PreferenceService {
  static final PreferenceService _instance = PreferenceService._internal();
  factory PreferenceService() => _instance;

  final ApiClient _apiClient = ApiClient();

  PreferenceService._internal();

  // ==========================================
  // PREFERINȚE UTILIZATOR
  // ==========================================

  /// Obține preferințele utilizatorului
  Future<UserPreferences?> getPreferences() async {
    try {
      final response = await _apiClient.get(ApiConfig.preferences);

      if (response.data['success'] == true &&
          response.data['data']?['preferences'] != null) {
        return UserPreferences.fromJson(response.data['data']['preferences']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Salvează preferințele (la onboarding)
  Future<UserPreferences?> savePreferences(UserPreferences preferences) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.preferences,
        data: preferences.toJson(),
      );

      if (response.data['success'] == true &&
          response.data['data']?['preferences'] != null) {
        return UserPreferences.fromJson(response.data['data']['preferences']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Actualizează preferințele
  Future<UserPreferences?> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.preferences,
        data: updates,
      );

      if (response.data['success'] == true &&
          response.data['data']?['preferences'] != null) {
        return UserPreferences.fromJson(response.data['data']['preferences']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Șterge preferințele
  Future<bool> deletePreferences() async {
    try {
      final response = await _apiClient.delete(ApiConfig.preferences);
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Verifică dacă utilizatorul a completat onboarding-ul
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await getPreferences();
      return prefs != null;
    } catch (e) {
      return false;
    }
  }
}

// Model pentru preferințele utilizatorului
class UserPreferences {
  final List<String>? preferredPetTypes;
  final bool? hasGarden;
  final bool? hasChildren;
  final List<String>? childrenAges;
  final bool? hasOtherPets;
  final List<String>? otherPetTypes;
  final DateTime? updatedAt;

  UserPreferences({
    this.preferredPetTypes,
    this.hasGarden,
    this.hasChildren,
    this.childrenAges,
    this.hasOtherPets,
    this.otherPetTypes,
    this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredPetTypes: json['preferredPetTypes'] != null
          ? List<String>.from(json['preferredPetTypes'])
          : null,
      hasGarden: json['hasGarden'],
      hasChildren: json['hasChildren'],
      childrenAges: json['childrenAges'] != null
          ? List<String>.from(json['childrenAges'])
          : null,
      hasOtherPets: json['hasOtherPets'],
      otherPetTypes: json['otherPetTypes'] != null
          ? List<String>.from(json['otherPetTypes'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredPetTypes': preferredPetTypes,
      'hasGarden': hasGarden,
      'hasChildren': hasChildren,
      'childrenAges': childrenAges,
      'hasOtherPets': hasOtherPets,
      'otherPetTypes': otherPetTypes,
    };
  }

  UserPreferences copyWith({
    List<String>? preferredPetTypes,
    bool? hasGarden,
    bool? hasChildren,
    List<String>? childrenAges,
    bool? hasOtherPets,
    List<String>? otherPetTypes,
  }) {
    return UserPreferences(
      preferredPetTypes: preferredPetTypes ?? this.preferredPetTypes,
      hasGarden: hasGarden ?? this.hasGarden,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenAges: childrenAges ?? this.childrenAges,
      hasOtherPets: hasOtherPets ?? this.hasOtherPets,
      otherPetTypes: otherPetTypes ?? this.otherPetTypes,
      updatedAt: updatedAt,
    );
  }

  // Verifică dacă preferințele sunt complete
  bool get isComplete {
    return preferredPetTypes != null &&
           preferredPetTypes!.isNotEmpty &&
           hasGarden != null;
  }

  // Construiește un query string pentru filtrare
  Map<String, dynamic> toFilterQuery() {
    final query = <String, dynamic>{};

    if (preferredPetTypes != null && preferredPetTypes!.isNotEmpty) {
      // API-ul acceptă un singur tip, deci trimitem primul
      query['type'] = preferredPetTypes!.first;
    }

    return query;
  }
}
