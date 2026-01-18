// lib/services/pet_service.dart
// Serviciu pentru gestionarea animalelor

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../data/models/pet_model.dart';
import 'api_client.dart';

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;

  final ApiClient _apiClient = ApiClient();

  PetService._internal();

  // ==========================================
  // LISTARE ANIMALE
  // ==========================================

  /// Obține lista de animale cu filtre și paginare
  Future<PetsResponse> getPets({
    String? type,
    String? breed,
    String? ageCategory,
    String? gender,
    String? size,
    String? color,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (type != null) queryParams['type'] = type;
      if (breed != null) queryParams['breed'] = breed;
      if (ageCategory != null) queryParams['age_category'] = ageCategory;
      if (gender != null) queryParams['gender'] = gender;
      if (size != null) queryParams['size'] = size;
      if (color != null) queryParams['color'] = color;
      if (city != null) queryParams['city'] = city;

      final response = await _apiClient.get(
        ApiConfig.pets,
        queryParameters: queryParams,
      );

      return PetsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Obține animale pentru swipe (exclude cele deja vizualizate)
  Future<List<PetModel>> getSwipePets({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.petSwipeFeed,
        queryParameters: {'limit': limit},
      );

      if (response.data['success'] == true && response.data['data']?['pets'] != null) {
        return (response.data['data']['pets'] as List)
            .map((p) => PetModel.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Obține detaliile unui animal
  Future<PetModel?> getPetById(int id) async {
    try {
      final response = await _apiClient.get(ApiConfig.petById(id));

      if (response.data['success'] == true && response.data['data']?['pet'] != null) {
        return PetModel.fromJson(response.data['data']['pet']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // SWIPE ACTIONS
  // ==========================================

  /// Înregistrează un swipe (like sau pass)
  Future<bool> swipePet(int petId, String action) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.petSwipe(petId),
        data: {'action': action}, // 'like' sau 'pass'
      );

      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Like la un animal (swipe right)
  Future<bool> likePet(int petId) async {
    return await swipePet(petId, 'like');
  }

  /// Pass la un animal (swipe left)
  Future<bool> passPet(int petId) async {
    return await swipePet(petId, 'pass');
  }

  /// Anulează ultimul swipe
  Future<Map<String, dynamic>?> undoSwipe() async {
    try {
      final response = await _apiClient.post(ApiConfig.petSwipeUndo);

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // CĂUTARE
  // ==========================================

  /// Caută animale după un termen
  Future<List<PetModel>> searchPets(String searchTerm, {int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.pets,
        queryParameters: {
          'breed': searchTerm,
          'limit': limit,
        },
      );

      if (response.data['success'] == true && response.data['data']?['pets'] != null) {
        return (response.data['data']['pets'] as List)
            .map((p) => PetModel.fromJson(p))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // FILTRARE LOCALĂ (pentru cache)
  // ==========================================

  /// Filtrează o listă de animale local
  List<PetModel> filterPets(
    List<PetModel> pets, {
    String? type,
    String? gender,
    String? size,
    String? ageCategory,
  }) {
    return pets.where((pet) {
      if (type != null && pet.type != type) return false;
      if (gender != null && pet.gender != gender) return false;
      if (size != null && pet.size != size) return false;
      if (ageCategory != null && pet.ageCategory != ageCategory) return false;
      return true;
    }).toList();
  }

  /// Sortează o listă de animale
  List<PetModel> sortPets(List<PetModel> pets, String sortBy) {
    final sortedPets = List<PetModel>.from(pets);

    switch (sortBy) {
      case 'name':
        sortedPets.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'age':
        sortedPets.sort((a, b) => (a.ageCategory ?? '').compareTo(b.ageCategory ?? ''));
        break;
      case 'recent':
        sortedPets.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'breed':
        sortedPets.sort((a, b) => (a.breed ?? '').compareTo(b.breed ?? ''));
        break;
    }

    return sortedPets;
  }
}
