import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user preferences with Supabase
class PreferenceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Loads user preferences from user_preferences table
  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Transform database format to UI format
      return _transformToUIFormat(response);
    } catch (e) {
      throw Exception('Failed to load preferences: $e');
    }
  }

  /// Saves user preferences to user_preferences table
  Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> prefs,
  ) async {
    try {
      // Transform UI format to database format
      final dbData = _transformToDBFormat(userId, prefs);

      // Upsert preferences (insert or update)
      await _supabase.from('user_preferences').upsert(
        dbData,
        onConflict: 'user_id',
      );
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }

  /// Clears user preferences from user_preferences table
  Future<void> clearUserPreferences(String userId) async {
    try {
      await _supabase
          .from('user_preferences')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear preferences: $e');
    }
  }

  /// Transforms database format to UI-friendly format
  Map<String, dynamic> _transformToUIFormat(Map<String, dynamic> dbData) {
    // Parse preferred_pet_types array to determine pet type preference
    final preferredTypes = (dbData['preferred_pet_types'] as List?) ?? [];
    String? petType;
    if (preferredTypes.contains('Dog') && preferredTypes.contains('Cat')) {
      petType = 'Both';
    } else if (preferredTypes.contains('Dog')) {
      petType = 'Dog';
    } else if (preferredTypes.contains('Cat')) {
      petType = 'Cat';
    }

    // Parse garden access
    final hasGarden = dbData['has_garden'] as bool? ?? false;
    String gardenAccess;
    if (hasGarden) {
      gardenAccess = 'Closed Garden'; // Default to closed if has garden
    } else {
      gardenAccess = 'No Garden';
    }

    // Parse children info
    final hasChildren = dbData['has_children'] as bool? ?? false;
    final childrenAges = (dbData['children_ages'] as List?) ?? [];
    String? childrenAgeRange;
    if (hasChildren && childrenAges.isNotEmpty) {
      // Try to determine age range from stored ages
      childrenAgeRange = _determineAgeRange(childrenAges);
    }

    // Parse existing pets
    final hasOtherPets = dbData['has_other_pets'] as bool? ?? false;
    final otherPetTypes = (dbData['other_pet_types'] as List?) ?? [];
    List<String> existingPets = [];
    Map<String, int> petCounts = {};
    if (hasOtherPets) {
      existingPets = List<String>.from(otherPetTypes);
      for (final pet in existingPets) {
        petCounts[pet] = 1; // Default count
      }
    }

    return {
      'petType': petType,
      'gardenAccess': gardenAccess,
      'hasChildren': hasChildren,
      'childrenAgeRange': childrenAgeRange,
      'existingPets': existingPets,
      'petCounts': petCounts,
      // Keep raw DB values for filtering
      'preferred_pet_types': preferredTypes,
      'has_garden': hasGarden,
      'has_other_pets': hasOtherPets,
      'other_pet_types': otherPetTypes,
    };
  }

  /// Transforms UI format to database format
  Map<String, dynamic> _transformToDBFormat(
    String userId,
    Map<String, dynamic> prefs,
  ) {
    // Convert pet type selection to array
    List<String> preferredPetTypes = [];
    final petType = prefs['petType'] as String?;
    if (petType == 'Both') {
      preferredPetTypes = ['Dog', 'Cat'];
    } else if (petType != null) {
      preferredPetTypes = [petType];
    }

    // Convert garden access to boolean
    final gardenAccess = prefs['gardenAccess'] as String?;
    final hasGarden = gardenAccess != null && gardenAccess != 'No Garden';

    // Children info
    final hasChildren = prefs['hasChildren'] as bool? ?? false;
    final childrenAgeRange = prefs['childrenAgeRange'] as String?;
    List<String> childrenAges = [];
    if (hasChildren && childrenAgeRange != null) {
      childrenAges = [childrenAgeRange]; // Store the age range string
    }

    // Existing pets
    final existingPets = (prefs['existingPets'] as List?) ?? [];
    final hasOtherPets = existingPets.isNotEmpty;

    return {
      'user_id': userId,
      'preferred_pet_types': preferredPetTypes,
      'has_garden': hasGarden,
      'has_children': hasChildren,
      'children_ages': childrenAges,
      'has_other_pets': hasOtherPets,
      'other_pet_types': List<String>.from(existingPets),
    };
  }

  /// Determines age range string from stored ages
  String? _determineAgeRange(List<dynamic> ages) {
    if (ages.isEmpty) return null;
    // If stored as range strings, return the first one
    if (ages.first is String) {
      return ages.first as String;
    }
    return null;
  }
}