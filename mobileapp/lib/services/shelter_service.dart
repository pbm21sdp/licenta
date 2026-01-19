import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

/// Service for handling shelter staff operations
/// Includes application management, pet management, and dashboard statistics
class ShelterService {
  static final ShelterService instance = ShelterService._internal();
  factory ShelterService() => instance;
  ShelterService._internal();

  final SupabaseClient _client = SupabaseService.instance.client;
  final _authService = AuthService.instance;

  // =====================================================
  // Dashboard Statistics
  // =====================================================

  /// Get dashboard statistics for shelter
  Future<Map<String, int>> getDashboardStats(String shelterId) async {
    try {
      // Get total pets count
      final petsResponse = await _client
          .from('pets')
          .select('id')
          .eq('shelter_id', shelterId);
      final totalPets = (petsResponse as List).length;

      // Get available pets count
      final availablePetsResponse = await _client
          .from('pets')
          .select('id')
          .eq('shelter_id', shelterId)
          .eq('is_available', true);
      final availablePets = (availablePetsResponse as List).length;

      // Get pet IDs for this shelter to filter applications
      final petIds = (petsResponse as List)
          .map((p) => p['id'] as String)
          .toList();

      if (petIds.isEmpty) {
        return {
          'totalPets': totalPets,
          'availablePets': availablePets,
          'pendingApplications': 0,
          'totalApplications': 0,
        };
      }

      // Get pending applications count
      final pendingResponse = await _client
          .from('adoption_applications')
          .select('id')
          .inFilter('pet_id', petIds)
          .eq('application_status', 'pending');
      final pendingApplications = (pendingResponse as List).length;

      // Get total applications count
      final totalApplicationsResponse = await _client
          .from('adoption_applications')
          .select('id')
          .inFilter('pet_id', petIds);
      final totalApplications = (totalApplicationsResponse as List).length;

      return {
        'totalPets': totalPets,
        'availablePets': availablePets,
        'pendingApplications': pendingApplications,
        'totalApplications': totalApplications,
      };
    } catch (e) {
      return {
        'totalPets': 0,
        'availablePets': 0,
        'pendingApplications': 0,
        'totalApplications': 0,
      };
    }
  }

  // =====================================================
  // Application Management
  // =====================================================

  /// Get all applications for shelter's pets
  Future<List<Map<String, dynamic>>> getShelterApplications(
    String shelterId, {
    String? statusFilter,
  }) async {
    try {
      // First get all pet IDs for this shelter
      final petsResponse = await _client
          .from('pets')
          .select('id')
          .eq('shelter_id', shelterId);

      final petIds =
          (petsResponse as List).map((p) => p['id'] as String).toList();

      if (petIds.isEmpty) return [];

      // Build query for applications
      // Note: pet_id is TEXT, not FK, so we cannot use join syntax
      // pet_name is already stored in the application record
      var query = _client
          .from('adoption_applications')
          .select('*')
          .inFilter('pet_id', petIds);

      // Apply status filter if provided
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('application_status', statusFilter);
      }

      final response = await query.order('submitted_at', ascending: false);
      final applications = List<Map<String, dynamic>>.from(response);

      // Fetch pet images for all applications
      if (applications.isNotEmpty) {
        final applicationPetIds = applications
            .map((app) => app['pet_id'] as String?)
            .where((id) => id != null && id.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (applicationPetIds.isNotEmpty) {
          final petsData = await _client
              .from('pets')
              .select('id, name, image_url, breed, species')
              .inFilter('id', applicationPetIds);

          // Create a map for quick lookup
          final petsMap = <String, Map<String, dynamic>>{};
          for (final pet in petsData) {
            petsMap[pet['id'] as String] = pet;
          }

          // Attach pet data to applications
          for (final app in applications) {
            final appPetId = app['pet_id'] as String?;
            if (appPetId != null && petsMap.containsKey(appPetId)) {
              app['pets'] = petsMap[appPetId];
            }
          }
        }
      }

      return applications;
    } catch (e) {
      throw Exception('Failed to fetch shelter applications: $e');
    }
  }

  /// Get a single application by ID
  Future<Map<String, dynamic>?> getApplicationById(String applicationId) async {
    try {
      // Note: pet_id is TEXT, not FK, so we cannot use join syntax
      final response = await _client
          .from('adoption_applications')
          .select('*')
          .eq('id', applicationId)
          .maybeSingle();

      if (response == null) return null;

      // Fetch pet details separately if pet_id exists
      final petId = response['pet_id'] as String?;
      if (petId != null && petId.isNotEmpty) {
        final petResponse = await _client
            .from('pets')
            .select(
                'id, name, breed, species, image_url, age_years, gender, description')
            .eq('id', petId)
            .maybeSingle();

        if (petResponse != null) {
          response['pets'] = petResponse;
        }
      }

      return response;
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  /// Update application status
  Future<void> updateApplicationStatus(
    String applicationId,
    String newStatus, {
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'application_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updates['staff_notes'] = notes;
      }

      await _client
          .from('adoption_applications')
          .update(updates)
          .eq('id', applicationId);
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Get application counts by status for shelter
  Future<Map<String, int>> getApplicationCountsByStatus(
    String shelterId,
  ) async {
    try {
      // First get all pet IDs for this shelter
      final petsResponse = await _client
          .from('pets')
          .select('id')
          .eq('shelter_id', shelterId);

      final petIds =
          (petsResponse as List).map((p) => p['id'] as String).toList();

      if (petIds.isEmpty) {
        return {
          'pending': 0,
          'under_review': 0,
          'interview': 0,
          'approved': 0,
          'rejected': 0,
          'withdrawn': 0,
        };
      }

      // Get all applications
      final response = await _client
          .from('adoption_applications')
          .select('application_status')
          .inFilter('pet_id', petIds);

      final applications = List<Map<String, dynamic>>.from(response);

      // Count by status
      final counts = <String, int>{
        'pending': 0,
        'under_review': 0,
        'interview': 0,
        'approved': 0,
        'rejected': 0,
        'withdrawn': 0,
      };

      for (final app in applications) {
        final status = app['application_status'] as String?;
        if (status != null && counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }
      }

      return counts;
    } catch (e) {
      return {
        'pending': 0,
        'under_review': 0,
        'interview': 0,
        'approved': 0,
        'rejected': 0,
        'withdrawn': 0,
      };
    }
  }

  // =====================================================
  // Pet Management
  // =====================================================

  /// Get all pets for shelter
  Future<List<Map<String, dynamic>>> getShelterPets(
    String shelterId, {
    bool? availableOnly,
  }) async {
    try {
      var query = _client.from('pets').select('''
            *,
            pet_gallery (
              id,
              image_url,
              image_semantic_label,
              display_order
            )
          ''').eq('shelter_id', shelterId);

      if (availableOnly == true) {
        query = query.eq('is_available', true);
      }

      final response = await query.order('created_at', ascending: false);
      final pets = List<Map<String, dynamic>>.from(response);

      // Fetch active applications for all pets to show "Adoption In Progress" status
      final petIds = pets.map((p) => p['id'] as String).toList();
      Map<String, String> activeApplicationStatus = {};

      if (petIds.isNotEmpty) {
        final activeApplicationsResponse = await _client
            .from('adoption_applications')
            .select('pet_id, application_status')
            .inFilter('pet_id', petIds)
            .inFilter('application_status', ['pending', 'under_review', 'interview', 'approved']);

        // Build a map of pet_id -> most advanced application status
        for (final app in activeApplicationsResponse) {
          final petId = app['pet_id'] as String;
          final status = app['application_status'] as String;
          // Keep the most advanced status (approved > interview > under_review > pending)
          if (!activeApplicationStatus.containsKey(petId) ||
              _getStatusPriority(status) > _getStatusPriority(activeApplicationStatus[petId]!)) {
            activeApplicationStatus[petId] = status;
          }
        }
      }

      final mappedPets = pets.map((pet) {
        // Format age string
        final ageYears = pet['age_years'] as int? ?? 0;
        String ageString;
        if (ageYears == 1) {
          ageString = '1 year old';
        } else if (ageYears < 1) {
          ageString = '${ageYears * 12} months old';
        } else {
          ageString = '$ageYears years old';
        }

        final petId = pet['id'] as String;
        final hasActiveApplication = activeApplicationStatus.containsKey(petId);

        return {
          ...pet,
          'age': ageString,
          'has_active_application': hasActiveApplication,
          'active_application_status': hasActiveApplication ? activeApplicationStatus[petId] : null,
        };
      }).toList();

      // When filtering for available only, also exclude pets with active applications
      // This ensures consistency with what adopters see in their feed
      if (availableOnly == true) {
        return mappedPets.where((pet) =>
          pet['has_active_application'] != true
        ).toList();
      }

      return mappedPets;
    } catch (e) {
      throw Exception('Failed to fetch shelter pets: $e');
    }
  }

  /// Helper to get status priority for determining most advanced status
  int _getStatusPriority(String status) {
    switch (status) {
      case 'approved':
        return 4;
      case 'interview':
        return 3;
      case 'under_review':
        return 2;
      case 'pending':
        return 1;
      default:
        return 0;
    }
  }

  /// Get a single pet by ID
  Future<Map<String, dynamic>?> getPetById(String petId) async {
    try {
      final response = await _client.from('pets').select('''
            *,
            pet_gallery (
              id,
              image_url,
              image_semantic_label,
              display_order
            )
          ''').eq('id', petId).maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch pet: $e');
    }
  }

  /// Create a new pet
  Future<String> createPet({
    required String shelterId,
    required String name,
    required String species,
    required String breed,
    required int ageYears,
    required String gender,
    required String description,
    required String healthStatus,
    required String imageUrl,
    required String imageSemanticLabel,
    bool isAvailable = true,
  }) async {
    try {
      final response = await _client
          .from('pets')
          .insert({
            'shelter_id': shelterId,
            'name': name,
            'species': species,
            'breed': breed,
            'age_years': ageYears,
            'gender': gender,
            'description': description,
            'health_status': healthStatus,
            'image_url': imageUrl,
            'image_semantic_label': imageSemanticLabel,
            'is_available': isAvailable,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create pet: $e');
    }
  }

  /// Update an existing pet
  Future<void> updatePet({
    required String petId,
    String? name,
    String? species,
    String? breed,
    int? ageYears,
    String? gender,
    String? description,
    String? healthStatus,
    String? imageUrl,
    String? imageSemanticLabel,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (species != null) updates['species'] = species;
      if (breed != null) updates['breed'] = breed;
      if (ageYears != null) updates['age_years'] = ageYears;
      if (gender != null) updates['gender'] = gender;
      if (description != null) updates['description'] = description;
      if (healthStatus != null) updates['health_status'] = healthStatus;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (imageSemanticLabel != null) {
        updates['image_semantic_label'] = imageSemanticLabel;
      }
      if (isAvailable != null) updates['is_available'] = isAvailable;

      await _client.from('pets').update(updates).eq('id', petId);
    } catch (e) {
      throw Exception('Failed to update pet: $e');
    }
  }

  /// Toggle pet availability
  Future<void> togglePetAvailability(String petId, bool isAvailable) async {
    try {
      await _client.from('pets').update({
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', petId);
    } catch (e) {
      throw Exception('Failed to update pet availability: $e');
    }
  }

  // =====================================================
  // Shelter Profile Management
  // =====================================================

  /// Update shelter profile
  Future<void> updateShelterProfile({
    required String shelterId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      if (website != null) updates['website'] = website;
      if (logoUrl != null) updates['logo_url'] = logoUrl;

      await _client
          .from('shelter_profiles')
          .update(updates)
          .eq('id', shelterId);
    } catch (e) {
      throw Exception('Failed to update shelter profile: $e');
    }
  }

  /// Get shelter profile
  Future<Map<String, dynamic>?> getShelterProfile(String shelterId) async {
    try {
      final response = await _client
          .from('shelter_profiles')
          .select()
          .eq('id', shelterId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch shelter profile: $e');
    }
  }

  // =====================================================
  // Recent Activity
  // =====================================================

  /// Get recent applications for dashboard
  Future<List<Map<String, dynamic>>> getRecentApplications(
    String shelterId, {
    int limit = 5,
  }) async {
    try {
      // First get all pet IDs for this shelter
      final petsResponse = await _client
          .from('pets')
          .select('id')
          .eq('shelter_id', shelterId);

      final petIds =
          (petsResponse as List).map((p) => p['id'] as String).toList();

      if (petIds.isEmpty) return [];

      final response = await _client
          .from('adoption_applications')
          .select('''
            id,
            pet_name,
            applicant_name,
            application_status,
            submitted_at
          ''')
          .inFilter('pet_id', petIds)
          .order('submitted_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
