// lib/services/user_pets_service.dart
// Serviciu pentru gestionarea animalelor proprii (CRUD)

import '../config/api_config.dart';
import '../data/models/pet_model.dart';
import 'api_client.dart';

class UserPetsService {
  final ApiClient _apiClient = ApiClient();

  /// Obține toate animalele utilizatorului curent
  Future<MyPetsResponse> getMyPets({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiConfig.myPets,
      queryParameters: queryParams,
    );

    return MyPetsResponse.fromJson(response.data);
  }

  /// Obține detaliile unui animal propriu
  Future<PetModel> getMyPetById(int id) async {
    final response = await _apiClient.get(ApiConfig.myPetById(id));

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to fetch pet');
    }

    return PetModel.fromJson(response.data['data']['pet']);
  }

  /// Creează un animal nou
  Future<PetModel> createPet({
    required String name,
    required String type,
    String? breed,
    String? ageCategory,
    String? gender,
    String? size,
    String? color,
    String? coat,
    double? fee,
    String? description,
    String? healthStatus,
    String? story,
    String? locationAddress,
    String? locationCity,
    String? locationCountry,
    String? zipCode,
    String? shelterContactEmail,
    String? shelterContactPhone,
    List<String>? traits,
    List<String>? photos,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
    };

    if (breed != null) body['breed'] = breed;
    if (ageCategory != null) body['ageCategory'] = ageCategory;
    if (gender != null) body['gender'] = gender;
    if (size != null) body['size'] = size;
    if (color != null) body['color'] = color;
    if (coat != null) body['coat'] = coat;
    if (fee != null) body['fee'] = fee;
    if (description != null) body['description'] = description;
    if (healthStatus != null) body['healthStatus'] = healthStatus;
    if (story != null) body['story'] = story;
    if (locationAddress != null) body['locationAddress'] = locationAddress;
    if (locationCity != null) body['locationCity'] = locationCity;
    if (locationCountry != null) body['locationCountry'] = locationCountry;
    if (zipCode != null) body['zipCode'] = zipCode;
    if (shelterContactEmail != null) body['shelterContactEmail'] = shelterContactEmail;
    if (shelterContactPhone != null) body['shelterContactPhone'] = shelterContactPhone;
    if (traits != null) body['traits'] = traits;
    if (photos != null) body['photos'] = photos;

    final response = await _apiClient.post(ApiConfig.myPets, data: body);

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to create pet');
    }

    return PetModel.fromJson(response.data['data']['pet']);
  }

  /// Actualizează un animal
  Future<PetModel> updatePet(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      ApiConfig.myPetById(id),
      data: updates,
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to update pet');
    }

    return PetModel.fromJson(response.data['data']['pet']);
  }

  /// Șterge un animal
  Future<void> deletePet(int id) async {
    final response = await _apiClient.delete(ApiConfig.myPetById(id));

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to delete pet');
    }
  }

  /// Adaugă o poză la un animal
  Future<void> addPetPhoto(int petId, String photoUrl, {bool isPrimary = false}) async {
    final response = await _apiClient.post(
      ApiConfig.myPetPhotos(petId),
      data: {
        'url': photoUrl,
        'isPrimary': isPrimary,
      },
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to add photo');
    }
  }

  /// Șterge o poză de la un animal
  Future<void> deletePetPhoto(int petId, int photoId) async {
    final response = await _apiClient.delete(
      ApiConfig.myPetPhotoById(petId, photoId),
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to delete photo');
    }
  }

  /// Actualizează disponibilitatea unui animal
  Future<PetModel> updatePetAvailability(int id, bool isAvailable) async {
    return updatePet(id, {
      'isAvailable': isAvailable,
      'adoptionStatus': isAvailable ? 'available' : 'unavailable',
    });
  }
}

/// Model pentru răspunsul cu lista de animale proprii
class MyPetsResponse {
  final bool success;
  final List<PetModel> pets;
  final PaginationInfo? pagination;

  MyPetsResponse({
    required this.success,
    required this.pets,
    this.pagination,
  });

  factory MyPetsResponse.fromJson(Map<String, dynamic> json) {
    return MyPetsResponse(
      success: json['success'] ?? false,
      pets: json['data']?['pets'] != null
          ? (json['data']['pets'] as List)
              .map((p) => PetModel.fromJson(p))
              .toList()
          : [],
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}
