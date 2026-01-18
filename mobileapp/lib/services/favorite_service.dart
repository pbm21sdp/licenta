// lib/services/favorite_service.dart
// Serviciu pentru gestionarea favoritelor

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../data/models/pet_model.dart';
import 'api_client.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;

  final ApiClient _apiClient = ApiClient();

  FavoriteService._internal();

  // ==========================================
  // FAVORITE CRUD
  // ==========================================

  /// Obține lista de favorite a utilizatorului
  Future<FavoritesResponse> getFavorites({
    int page = 1,
    int limit = 20,
    String sort = 'recent', // 'recent', 'alphabetical', 'age', 'breed'
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.favorites,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': sort,
        },
      );

      return FavoritesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Adaugă un animal la favorite
  Future<bool> addFavorite(int petId) async {
    try {
      final response = await _apiClient.post(ApiConfig.favoriteById(petId));
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      // Dacă e deja în favorite, considerăm succes
      if (e.response?.statusCode == 409) {
        return true;
      }
      throw ApiException.fromDioError(e);
    }
  }

  /// Șterge un animal din favorite
  Future<bool> removeFavorite(int petId) async {
    try {
      final response = await _apiClient.delete(ApiConfig.favoriteById(petId));
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Verifică dacă un animal e în favorite
  Future<bool> checkFavorite(int petId) async {
    try {
      final response = await _apiClient.get(ApiConfig.checkFavorite(petId));
      return response.data['data']?['isFavorited'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Toggle favorite (adaugă sau șterge)
  Future<bool> toggleFavorite(int petId) async {
    final isFavorited = await checkFavorite(petId);
    if (isFavorited) {
      return await removeFavorite(petId);
    } else {
      return await addFavorite(petId);
    }
  }
}

// Model pentru răspunsul cu favorite
class FavoritesResponse {
  final bool success;
  final List<FavoriteItem> favorites;
  final PaginationInfo? pagination;

  FavoritesResponse({
    required this.success,
    required this.favorites,
    this.pagination,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      success: json['success'] ?? false,
      favorites: json['data']?['favorites'] != null
          ? (json['data']['favorites'] as List)
              .map((f) => FavoriteItem.fromJson(f))
              .toList()
          : [],
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}

// Model pentru un item din lista de favorite
class FavoriteItem {
  final int favoriteId;
  final DateTime favoritedAt;
  final int id;
  final String name;
  final String type;
  final String? breed;
  final String? ageCategory;
  final String? gender;
  final String? size;
  final double? fee;
  final bool isAvailable;
  final String? adoptionStatus;
  final String? locationCity;
  final String? locationCountry;
  final String? primaryPhoto;

  FavoriteItem({
    required this.favoriteId,
    required this.favoritedAt,
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    this.ageCategory,
    this.gender,
    this.size,
    this.fee,
    required this.isAvailable,
    this.adoptionStatus,
    this.locationCity,
    this.locationCountry,
    this.primaryPhoto,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      favoriteId: json['favorite_id'] ?? json['favoriteId'],
      favoritedAt: DateTime.parse(json['favorited_at'] ?? json['favoritedAt']),
      id: json['id'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      ageCategory: json['age_category'] ?? json['ageCategory'],
      gender: json['gender'],
      size: json['size'],
      fee: json['fee'] != null ? double.tryParse(json['fee'].toString()) : null,
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      adoptionStatus: json['adoption_status'] ?? json['adoptionStatus'],
      locationCity: json['location_city'] ?? json['locationCity'],
      locationCountry: json['location_country'] ?? json['locationCountry'],
      primaryPhoto: json['primary_photo'] ?? json['primaryPhoto'],
    );
  }

  // Convertire la PetModel pentru compatibilitate
  PetModel toPetModel() {
    return PetModel(
      id: id,
      name: name,
      type: type,
      breed: breed,
      ageCategory: ageCategory,
      gender: gender,
      size: size,
      fee: fee,
      isAvailable: isAvailable,
      adoptionStatus: adoptionStatus,
      locationCity: locationCity,
      locationCountry: locationCountry,
      primaryPhoto: primaryPhoto,
    );
  }

  String get imageUrl {
    if (primaryPhoto != null && primaryPhoto!.isNotEmpty) {
      return primaryPhoto!;
    }
    return 'https://via.placeholder.com/300x300?text=No+Image';
  }
}
