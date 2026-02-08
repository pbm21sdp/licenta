// lib/services/owner_adoptions_service.dart
// Serviciu pentru gestionarea cererilor de adopție primite (din perspectiva owner-ului)

import '../config/api_config.dart';
import '../data/models/pet_model.dart';
import '../data/models/public_profile_model.dart';
import 'api_client.dart';

class OwnerAdoptionsService {
  final ApiClient _apiClient = ApiClient();

  /// Obține cererile de adopție pentru animalele proprii
  Future<OwnerAdoptionsResponse> getMyAdoptionRequests({
    String? status,
    int? petId,
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
    if (petId != null) {
      queryParams['petId'] = petId.toString();
    }

    final response = await _apiClient.get(
      ApiConfig.ownerAdoptions,
      queryParameters: queryParams,
    );

    return OwnerAdoptionsResponse.fromJson(response.data);
  }

  /// Obține detaliile unei cereri de adopție
  Future<AdoptionRequestModel> getAdoptionRequestById(int id) async {
    final response = await _apiClient.get(ApiConfig.ownerAdoptionById(id));

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to fetch adoption request');
    }

    return AdoptionRequestModel.fromJson(response.data['data']['application']);
  }

  /// Aprobă o cerere de adopție
  Future<void> approveAdoption(int id, {String? notes}) async {
    await updateAdoptionStatus(id, 'approved', ownerNotes: notes);
  }

  /// Respinge o cerere de adopție
  Future<void> rejectAdoption(int id, {String? notes}) async {
    await updateAdoptionStatus(id, 'rejected', ownerNotes: notes);
  }

  /// Marchează o cerere ca "în revizuire"
  Future<void> markInReview(int id, {String? notes}) async {
    await updateAdoptionStatus(id, 'in_review', ownerNotes: notes);
  }

  /// Actualizează statusul unei cereri de adopție
  Future<void> updateAdoptionStatus(
    int id,
    String status, {
    String? ownerNotes,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (ownerNotes != null) {
      body['ownerNotes'] = ownerNotes;
    }

    final response = await _apiClient.put(
      ApiConfig.ownerAdoptionStatus(id),
      data: body,
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to update adoption status');
    }
  }

  /// Programează o întâlnire pentru o cerere de adopție
  Future<void> scheduleMeeting(
    int adoptionId, {
    required String scheduledDate,
    required String scheduledTime,
    required String location,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'location': location,
    };
    if (notes != null) {
      body['notes'] = notes;
    }

    final response = await _apiClient.post(
      ApiConfig.ownerAdoptionMeeting(adoptionId),
      data: body,
    );

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to schedule meeting');
    }
  }

  /// Obține statisticile owner-ului
  Future<OwnerStats> getOwnerStats() async {
    final response = await _apiClient.get(ApiConfig.ownerAdoptionsStats);

    if (response.data['success'] != true) {
      throw ApiException(message: response.data['message'] ?? 'Failed to fetch owner stats');
    }

    return OwnerStats.fromJson(response.data['data']);
  }
}

/// Model pentru răspunsul cu cererile de adopție
class OwnerAdoptionsResponse {
  final bool success;
  final List<AdoptionRequestModel> applications;
  final AdoptionRequestsStats? stats;
  final PaginationInfo? pagination;

  OwnerAdoptionsResponse({
    required this.success,
    required this.applications,
    this.stats,
    this.pagination,
  });

  factory OwnerAdoptionsResponse.fromJson(Map<String, dynamic> json) {
    return OwnerAdoptionsResponse(
      success: json['success'] ?? false,
      applications: json['data']?['applications'] != null
          ? (json['data']['applications'] as List)
              .map((a) => AdoptionRequestModel.fromJson(a))
              .toList()
          : [],
      stats: json['data']?['stats'] != null
          ? AdoptionRequestsStats.fromJson(json['data']['stats'])
          : null,
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}
