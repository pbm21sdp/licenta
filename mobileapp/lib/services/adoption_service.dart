// lib/services/adoption_service.dart
// Serviciu pentru gestionarea cererilor de adopție

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../data/models/adoption_model.dart';
import 'api_client.dart';

class AdoptionService {
  static final AdoptionService _instance = AdoptionService._internal();
  factory AdoptionService() => _instance;

  final ApiClient _apiClient = ApiClient();

  AdoptionService._internal();

  // ==========================================
  // CERERI DE ADOPȚIE
  // ==========================================

  /// Obține lista cererilor de adopție ale utilizatorului
  Future<AdoptionsResponse> getMyAdoptions({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        ApiConfig.adoptions,
        queryParameters: queryParams,
      );

      return AdoptionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Obține detaliile unei cereri de adopție
  Future<AdoptionModel?> getAdoptionById(int id) async {
    try {
      final response = await _apiClient.get(ApiConfig.adoptionById(id));

      if (response.data['success'] == true &&
          response.data['data']?['application'] != null) {
        return AdoptionModel.fromJson(response.data['data']['application']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Trimite o cerere de adopție nouă
  Future<AdoptionResult> createAdoption(CreateAdoptionRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.adoptions,
        data: request.toJson(),
      );

      return AdoptionResult(
        success: response.data['success'] ?? false,
        message: response.data['message'] ?? '',
        applicationId: response.data['data']?['application']?['id'],
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Actualizează o cerere de adopție (doar dacă e în starea pending)
  Future<AdoptionModel?> updateAdoption(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.adoptionById(id),
        data: updates,
      );

      if (response.data['success'] == true &&
          response.data['data']?['application'] != null) {
        return AdoptionModel.fromJson(response.data['data']['application']);
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Anulează o cerere de adopție
  Future<bool> cancelAdoption(int id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.adoptionById(id));
      return response.data['success'] ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Verifică dacă utilizatorul are o cerere activă pentru un animal
  Future<bool> hasActiveApplication(int petId) async {
    try {
      final response = await getMyAdoptions();

      return response.applications.any(
        (app) => app.petId == petId &&
                 (app.status == 'pending' || app.status == 'in_review'),
      );
    } catch (e) {
      return false;
    }
  }

  /// Obține numărul de cereri în așteptare
  Future<int> getPendingCount() async {
    try {
      final response = await getMyAdoptions(status: 'pending');
      return response.pagination?.totalItems ?? response.applications.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obține toate cererile grupate pe status
  Future<Map<String, List<AdoptionModel>>> getAdoptionsGroupedByStatus() async {
    try {
      final response = await getMyAdoptions(limit: 100);

      final grouped = <String, List<AdoptionModel>>{
        'pending': [],
        'in_review': [],
        'approved': [],
        'rejected': [],
      };

      for (final app in response.applications) {
        grouped[app.status]?.add(app);
      }

      return grouped;
    } catch (e) {
      return {
        'pending': [],
        'in_review': [],
        'approved': [],
        'rejected': [],
      };
    }
  }
}

// Model pentru rezultatul creării unei cereri
class AdoptionResult {
  final bool success;
  final String message;
  final int? applicationId;

  AdoptionResult({
    required this.success,
    required this.message,
    this.applicationId,
  });
}
