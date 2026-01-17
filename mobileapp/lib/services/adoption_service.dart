import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

/// Service for handling adoption application operations
class AdoptionService {
  final SupabaseClient _client = SupabaseService.instance.client;
  final _authService = AuthService.instance;

  /// Submit a new adoption application
  ///
  /// Returns the application ID on success
  /// Throws Exception on failure
  Future<String> submitAdoptionApplication({
    required String petId,
    required String petName,
    String? shelterId,
    required String applicantName,
    required String applicantEmail,
    required String applicantPhone,
    required String applicantAddress,
    required String housingType,
    required bool hasGarden,
    required bool hasExistingPets,
    required String experienceLevel,
    String? additionalNotes,
  }) async {
    try {
      // Get current user ID if authenticated
      final userId = _authService.currentUser?.id;

      final response = await _client
          .from('adoption_applications')
          .insert({
            'pet_id': petId,
            'pet_name': petName,
            'shelter_id': shelterId,
            'user_id': userId,
            'applicant_name': applicantName,
            'applicant_email': applicantEmail,
            'applicant_phone': applicantPhone,
            'applicant_address': applicantAddress,
            'housing_type': housingType,
            'has_garden': hasGarden,
            'has_existing_pets': hasExistingPets,
            'experience_level': experienceLevel,
            'additional_notes': additionalNotes,
            'application_status': 'pending',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (error) {
      throw Exception('Failed to submit adoption application: $error');
    }
  }

  /// Get adoption history for authenticated user
  Future<List<Map<String, dynamic>>> getUserAdoptionHistory() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('adoption_applications')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch adoption history: $error');
    }
  }

  /// Get adoption history by email (for non-authenticated access)
  Future<List<Map<String, dynamic>>> getAdoptionHistoryByEmail(
    String email,
  ) async {
    try {
      final response = await _client
          .from('adoption_applications')
          .select('*')
          .eq('applicant_email', email)
          .order('submitted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch adoption history: $error');
    }
  }

  /// Get pending applications for authenticated user
  Future<List<Map<String, dynamic>>> getPendingApplications() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('adoption_applications')
          .select('*')
          .eq('user_id', userId)
          .eq('application_status', 'pending')
          .order('submitted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch pending applications: $error');
    }
  }

  /// Get all shelters
  Future<List<Map<String, dynamic>>> getShelters() async {
    try {
      final response = await _client
          .from('shelter_profiles')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch shelters: $error');
    }
  }

  /// Get shelter by ID
  Future<Map<String, dynamic>?> getShelterById(String shelterId) async {
    try {
      final response = await _client
          .from('shelter_profiles')
          .select()
          .eq('id', shelterId)
          .maybeSingle();

      return response;
    } catch (error) {
      throw Exception('Failed to fetch shelter: $error');
    }
  }

  /// Check if application exists for a pet and email
  Future<bool> hasExistingApplication({
    required String petId,
    required String applicantEmail,
  }) async {
    try {
      final response = await _client
          .from('adoption_applications')
          .select('id')
          .eq('pet_id', petId)
          .eq('applicant_email', applicantEmail)
          .maybeSingle();

      return response != null;
    } catch (error) {
      return false;
    }
  }

  /// Get application count for a pet
  Future<int> getApplicationCountForPet(String petId) async {
    try {
      final response = await _client
          .from('adoption_applications')
          .select('id')
          .eq('pet_id', petId)
          .count();

      return response.count ?? 0;
    } catch (error) {
      return 0;
    }
  }
}