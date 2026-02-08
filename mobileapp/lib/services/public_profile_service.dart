// lib/services/public_profile_service.dart
// Serviciu pentru profile publice și căutare utilizatori

import '../config/api_config.dart';
import '../data/models/pet_model.dart';
import '../data/models/public_profile_model.dart';
import 'api_client.dart';

class PublicProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Obține profilul public al unui utilizator
  Future<PublicProfileModel> getUserProfile(int userId) async {
    final response = await _apiClient.get(ApiConfig.userProfile(userId));

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to fetch user profile');
    }

    return PublicProfileModel.fromJson(response.data['data']['profile']);
  }

  /// Obține animalele unui utilizator
  Future<UserPetsResponse> getUserPets(
    int userId, {
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
      ApiConfig.userPets(userId),
      queryParameters: queryParams,
    );

    return UserPetsResponse.fromJson(response.data);
  }

  /// Caută utilizatori după nume
  Future<UserSearchResponse> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.usersSearch,
      queryParameters: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return UserSearchResponse.fromJson(response.data);
  }

  /// Obține utilizatorii cu cele mai multe animale listate
  Future<List<UserSearchResult>> getTopListers({int limit = 10}) async {
    final response = await _apiClient.get(
      ApiConfig.usersTopListers,
      queryParameters: {'limit': limit.toString()},
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to fetch top listers');
    }

    final topListers = response.data['data']['topListers'] as List? ?? [];
    return topListers.map((u) => UserSearchResult.fromJson(u)).toList();
  }
}

/// Model pentru răspunsul cu animalele unui utilizator
class UserPetsResponse {
  final bool success;
  final UserOwner? owner;
  final List<PetModel> pets;
  final PaginationInfo? pagination;

  UserPetsResponse({
    required this.success,
    this.owner,
    required this.pets,
    this.pagination,
  });

  factory UserPetsResponse.fromJson(Map<String, dynamic> json) {
    return UserPetsResponse(
      success: json['success'] ?? false,
      owner: json['data']?['owner'] != null
          ? UserOwner.fromJson(json['data']['owner'])
          : null,
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

/// Model pentru owner info în răspuns
class UserOwner {
  final int id;
  final String name;

  UserOwner({required this.id, required this.name});

  factory UserOwner.fromJson(Map<String, dynamic> json) {
    return UserOwner(
      id: json['id'],
      name: json['name'] ?? 'Anonymous User',
    );
  }
}

/// Model pentru răspunsul la căutare utilizatori
class UserSearchResponse {
  final bool success;
  final List<UserSearchResult> users;
  final PaginationInfo? pagination;

  UserSearchResponse({
    required this.success,
    required this.users,
    this.pagination,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      success: json['success'] ?? false,
      users: json['data']?['users'] != null
          ? (json['data']['users'] as List)
              .map((u) => UserSearchResult.fromJson(u))
              .toList()
          : [],
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}
