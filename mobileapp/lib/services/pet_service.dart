import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing pet-related operations with Supabase
class PetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cooldown duration constant (1 hour = 3600 seconds)
  static const int cooldownHours = 1;
  static const int cooldownSeconds = cooldownHours * 3600;

  /// Filter parameters for pet queries
  /// - speciesFilter: List of species to include (e.g., ['Dog', 'Cat'])
  /// - hasGarden: Whether user has a garden (filters out pets that need garden if false)
  /// - hasChildren: Whether user has children (prefers child-friendly pets)
  /// - hasOtherPets: Whether user has other pets (prefers sociable pets)

  /// Fetches available pets for swiping, excluding:
  /// - Pets already favorited by the user
  /// - Pets currently on cooldown
  /// - Pets with active adoption applications (pending, under_review, interview, approved)
  /// - Pets not matching filter criteria
  Future<List<Map<String, dynamic>>> getAvailablePets({
    String? userId,
    List<String>? speciesFilter,
    bool? hasGarden,
    bool? hasChildren,
    bool? hasOtherPets,
  }) async {
    try {
      // Build base query for available pets
      var query = _supabase
          .from('pets')
          .select('''
            *,
            pet_gallery (
              id,
              image_url,
              image_semantic_label,
              display_order
            ),
            shelter_profiles (
              id,
              name
            )
          ''')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      final response = await query;
      List<Map<String, dynamic>> pets = List<Map<String, dynamic>>.from(
        response,
      );

      // Get pets with active applications from ANY user (pending, under_review, interview, approved)
      // These pets should be hidden from all users since adoption is in progress
      // Excluded statuses: rejected, withdrawn (pet is available again)
      // Using RPC function with SECURITY DEFINER to bypass RLS restrictions
      final activeApplicationsResponse = await _supabase
          .rpc('get_pets_with_active_applications');

      final activeApplicationPetIds = (activeApplicationsResponse as List)
          .map((e) => e as String)
          .toSet();

      // Filter out pets with active applications (applies to all users)
      pets = pets.where((pet) {
        final petId = pet['id'] as String;
        return !activeApplicationPetIds.contains(petId);
      }).toList();

      // If user is authenticated, also filter out favorited and cooldown pets
      if (userId != null) {
        // Get favorited pet IDs
        final favoritesResponse = await _supabase
            .from('user_favorites')
            .select('pet_id')
            .eq('user_id', userId);

        final favoritedPetIds = (favoritesResponse as List)
            .map((e) => e['pet_id'] as String)
            .toSet();

        // Get pets on cooldown (skipped pets with active cooldown)
        final cooldownResponse = await _supabase
            .from('pet_interactions')
            .select('pet_id, cooldown_until')
            .eq('user_id', userId)
            .gte('cooldown_until', DateTime.now().toIso8601String());

        final cooldownPetIds = (cooldownResponse as List)
            .map((e) => e['pet_id'] as String)
            .toSet();

        // Filter out favorited and cooldown pets
        pets = pets.where((pet) {
          final petId = pet['id'] as String;
          return !favoritedPetIds.contains(petId) &&
              !cooldownPetIds.contains(petId);
        }).toList();
      }

      // Apply species filter if provided (case-insensitive)
      if (speciesFilter != null && speciesFilter.isNotEmpty) {
        final lowerCaseFilter = speciesFilter.map((s) => s.toLowerCase()).toList();
        pets = pets.where((pet) {
          final species = pet['species'] as String?;
          if (species == null) return false;
          return lowerCaseFilter.contains(species.toLowerCase());
        }).toList();
      }

      // Apply garden filter: if user has no garden, filter out pets that need one
      if (hasGarden == false) {
        pets = pets.where((pet) {
          final needsGarden = pet['needs_garden'] as bool? ?? false;
          return !needsGarden;
        }).toList();
      }

      // Sort by compatibility (child-friendly and sociable pets first if applicable)
      if (hasChildren == true || hasOtherPets == true) {
        pets.sort((a, b) {
          int scoreA = 0;
          int scoreB = 0;

          if (hasChildren == true) {
            final aGoodWithChildren = a['good_with_children'] as bool? ?? false;
            final bGoodWithChildren = b['good_with_children'] as bool? ?? false;
            if (aGoodWithChildren) scoreA += 1;
            if (bGoodWithChildren) scoreB += 1;
          }

          if (hasOtherPets == true) {
            final aGoodWithPets = a['good_with_other_pets'] as bool? ?? false;
            final bGoodWithPets = b['good_with_other_pets'] as bool? ?? false;
            if (aGoodWithPets) scoreA += 1;
            if (bGoodWithPets) scoreB += 1;
          }

          return scoreB.compareTo(scoreA); // Higher scores first
        });
      }

      // Transform data to match UI expectations
      return pets.map((pet) {
        // Get primary image from pet_gallery or fallback to pet's image_url
        String primaryImageUrl = pet['image_url'] as String;
        String primarySemanticLabel = pet['image_semantic_label'] as String;

        final gallery = pet['pet_gallery'] as List?;
        if (gallery != null && gallery.isNotEmpty) {
          // Sort by display_order and get the first image
          final sortedGallery = List<Map<String, dynamic>>.from(gallery);
          sortedGallery.sort(
            (a, b) => (a['display_order'] as int).compareTo(
              b['display_order'] as int,
            ),
          );
          primaryImageUrl = sortedGallery.first['image_url'] as String;
          primarySemanticLabel =
              sortedGallery.first['image_semantic_label'] as String;
        }

        // Format age string
        final ageYears = pet['age_years'] as int;
        String ageString;
        if (ageYears == 1) {
          ageString = '1 year old';
        } else if (ageYears < 1) {
          ageString = '${ageYears * 12} months old';
        } else {
          ageString = '$ageYears years old';
        }

        return {
          'id': pet['id'],
          'name': pet['name'],
          'breed': pet['breed'],
          'age': ageString,
          'gender': pet['gender'],
          'species': pet['species'],
          'description': pet['description'] ?? '',
          'health_status': pet['health_status'] ?? '',
          'image': primaryImageUrl,
          'semanticLabel': primarySemanticLabel,
          'shelter_id': pet['shelter_id'],
          'is_available': pet['is_available'],
          'created_at': pet['created_at'],
          'updated_at': pet['updated_at'],
          // Keep original gallery data for detail screen
          'pet_gallery': gallery ?? [],
          'shelter_profiles': pet['shelter_profiles'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch available pets: $e');
    }
  }

  /// Records a pet interaction (like or skip)
  Future<void> recordInteraction({
    required String userId,
    required String petId,
    required String interactionType,
  }) async {
    try {
      final cooldownUntil = interactionType == 'skip'
          ? DateTime.now().add(Duration(seconds: cooldownSeconds))
          : null;

      await _supabase.from('pet_interactions').insert({
        'user_id': userId,
        'pet_id': petId,
        'interaction_type': interactionType,
        'cooldown_until': cooldownUntil?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record interaction: $e');
    }
  }

  /// Adds a pet to user's favorites
  /// Uses upsert to prevent duplicate key errors when the same pet is liked again
  Future<void> addToFavorites({
    required String userId,
    required String petId,
  }) async {
    try {
      await _supabase.from('user_favorites').upsert(
        {'user_id': userId, 'pet_id': petId},
        onConflict: 'user_id,pet_id',
      );
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Removes interaction(s) for a pet by type (for undo functionality)
  /// Deletes by matching criteria to handle race conditions where
  /// the insert might not have completed yet
  Future<void> removeInteraction({
    required String userId,
    required String petId,
    required String interactionType,
  }) async {
    try {
      await _supabase
          .from('pet_interactions')
          .delete()
          .eq('user_id', userId)
          .eq('pet_id', petId)
          .eq('interaction_type', interactionType);
    } catch (e) {
      throw Exception('Failed to remove interaction: $e');
    }
  }

  /// Removes a pet from user's favorites and deletes the 'like' interaction
  /// so the pet can reappear in the swipe feed
  Future<void> removeFromFavorites({
    required String userId,
    required String petId,
  }) async {
    try {
      // Remove from favorites
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('pet_id', petId);

      // Also delete the 'like' interaction so pet can reappear in feed
      await _supabase
          .from('pet_interactions')
          .delete()
          .eq('user_id', userId)
          .eq('pet_id', petId)
          .eq('interaction_type', 'like');
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Fetches user's favorite pets
  Future<List<Map<String, dynamic>>> getUserFavorites({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('''
            created_at,
            pets (
              *,
              pet_gallery (
                id,
                image_url,
                image_semantic_label,
                display_order
              ),
              shelter_profiles (
                id,
                name
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final favorites = (response as List)
          .map((item) {
            final petData = item['pets'];
            if (petData == null) return null;

            final pet = Map<String, dynamic>.from(petData);

            // Get primary image from pet_gallery or fallback to pet's image_url
            String primaryImageUrl = pet['image_url'] as String? ?? '';
            String primarySemanticLabel =
                pet['image_semantic_label'] as String? ?? 'Pet photo';

            final gallery = pet['pet_gallery'] as List?;
            if (gallery != null && gallery.isNotEmpty) {
              final sortedGallery = List<Map<String, dynamic>>.from(gallery);
              sortedGallery.sort(
                (a, b) => (a['display_order'] as int).compareTo(
                  b['display_order'] as int,
                ),
              );
              primaryImageUrl =
                  sortedGallery.first['image_url'] as String? ??
                  primaryImageUrl;
              primarySemanticLabel =
                  sortedGallery.first['image_semantic_label'] as String? ??
                  primarySemanticLabel;
            }

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

            return {
              'id': pet['id'],
              'name': pet['name'] ?? 'Unknown',
              'breed': pet['breed'] ?? 'Mixed Breed',
              'age': ageString,
              'age_years': ageYears,
              'gender': pet['gender'] ?? 'Unknown',
              'species': pet['species'] ?? 'Unknown',
              'description': pet['description'] ?? '',
              'health_status': pet['health_status'] ?? '',
              'image': primaryImageUrl,
              'semanticLabel': primarySemanticLabel,
              'shelter_id': pet['shelter_id'],
              'is_available': pet['is_available'] ?? true,
              'isAvailable': pet['is_available'] ?? true,
              'created_at': pet['created_at'],
              'updated_at': pet['updated_at'],
              'added_date': item['created_at'],
              'pet_gallery': gallery ?? [],
              'shelter_profiles': pet['shelter_profiles'],
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      return favorites;
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  /// Gets the count of pets on cooldown for a user
  Future<int> getCooldownPetsCount({required String userId}) async {
    try {
      final response = await _supabase
          .from('pet_interactions')
          .select('pet_id')
          .eq('user_id', userId)
          .gte('cooldown_until', DateTime.now().toIso8601String());

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Checks if there are any available pets after applying all filters
  Future<bool> hasAvailablePets({String? userId}) async {
    try {
      final pets = await getAvailablePets(userId: userId);
      return pets.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Fetches a single pet by ID regardless of availability status
  /// Used for viewing pet details in application history
  Future<Map<String, dynamic>?> getPetById(String petId) async {
    try {
      final response = await _supabase
          .from('pets')
          .select('''
            *,
            pet_gallery (
              id,
              image_url,
              image_semantic_label,
              display_order
            ),
            shelter_profiles (
              id,
              name
            )
          ''')
          .eq('id', petId)
          .maybeSingle();

      if (response == null) return null;

      final pet = Map<String, dynamic>.from(response);

      // Get primary image from pet_gallery or fallback to pet's image_url
      String primaryImageUrl = pet['image_url'] as String? ?? '';
      String primarySemanticLabel =
          pet['image_semantic_label'] as String? ?? 'Pet photo';

      final gallery = pet['pet_gallery'] as List?;
      if (gallery != null && gallery.isNotEmpty) {
        final sortedGallery = List<Map<String, dynamic>>.from(gallery);
        sortedGallery.sort(
          (a, b) => (a['display_order'] as int).compareTo(
            b['display_order'] as int,
          ),
        );
        primaryImageUrl =
            sortedGallery.first['image_url'] as String? ?? primaryImageUrl;
        primarySemanticLabel =
            sortedGallery.first['image_semantic_label'] as String? ??
            primarySemanticLabel;
      }

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

      return {
        'id': pet['id'],
        'name': pet['name'] ?? 'Unknown',
        'breed': pet['breed'] ?? 'Mixed Breed',
        'age': ageString,
        'age_years': ageYears,
        'gender': pet['gender'] ?? 'Unknown',
        'species': pet['species'] ?? 'Unknown',
        'description': pet['description'] ?? '',
        'health_status': pet['health_status'] ?? '',
        'image_url': primaryImageUrl,
        'image_semantic_label': primarySemanticLabel,
        'shelter_id': pet['shelter_id'],
        'is_available': pet['is_available'] ?? false,
        'created_at': pet['created_at'],
        'updated_at': pet['updated_at'],
        'pet_gallery': gallery ?? [],
        'shelter_profiles': pet['shelter_profiles'],
      };
    } catch (e) {
      return null;
    }
  }
}
