import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/favorite_service.dart';
import '../../services/api_client.dart';
import './widgets/empty_favorites_widget.dart';
import './widgets/favorite_pet_card_widget.dart';
import './widgets/favorites_header_widget.dart';

/// Favorites Screen - Displays user's liked pets in organized grid layout
/// Accessible via bottom tab navigation (Favorites tab active)
/// Features: Grid view, search, sort, swipe-to-delete, pull-to-refresh
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Recently Added';

  // Service și state pentru favorites
  final FavoriteService _favoriteService = FavoriteService();
  List<FavoriteItem> _favoritePets = [];
  List<Map<String, dynamic>> _allFavorites = [];
  List<Map<String, dynamic>> _filteredFavorites = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await _favoriteService.getFavorites();

      if (mounted) {
        setState(() {
          _favoritePets = response.favorites;
          _allFavorites = response.favorites.map((fav) => _favoriteToMap(fav)).toList();
          _isLoading = false;
          _filterAndSortFavorites();
        });
      }
    } on ApiException catch (e) {
      print('API Error loading favorites: ${e.message}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not load favorites. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // Convertește FavoriteItem la Map pentru compatibilitate cu widget-urile existente
  Map<String, dynamic> _favoriteToMap(FavoriteItem fav) {
    return {
      "id": fav.id,
      "name": fav.name,
      "age": fav.ageCategory ?? "Unknown age",
      "breed": fav.breed ?? "Unknown",
      "gender": fav.gender ?? "Unknown",
      "image": fav.imageUrl,
      "semanticLabel": "${fav.breed ?? 'Pet'} named ${fav.name}",
      "bio": "A lovely ${fav.type} looking for a home.",
      "healthStatus": "Contact shelter for health details",
      "addedDate": fav.favoritedAt,
      "available": fav.isAvailable,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterAndSortFavorites();
    });
  }

  void _filterAndSortFavorites() {
    List<Map<String, dynamic>> filtered = _allFavorites.where((pet) {
      final name = ((pet["name"] as String?) ?? '').toLowerCase();
      final breed = ((pet["breed"] as String?) ?? '').toLowerCase();
      return name.contains(_searchQuery) || breed.contains(_searchQuery);
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case 'Recently Added':
        filtered.sort((a, b) {
          final dateA = a["addedDate"] as DateTime?;
          final dateB = b["addedDate"] as DateTime?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;
      case 'Alphabetical':
        filtered.sort(
          (a, b) => ((a["name"] as String?) ?? '').compareTo((b["name"] as String?) ?? ''),
        );
        break;
      case 'Age':
        filtered.sort((a, b) {
          final ageA = (a["age"] as String?) ?? '';
          final ageB = (b["age"] as String?) ?? '';
          return ageA.compareTo(ageB);
        });
        break;
      case 'Breed':
        filtered.sort(
          (a, b) => ((a["breed"] as String?) ?? '').compareTo((b["breed"] as String?) ?? ''),
        );
        break;
    }

    setState(() {
      _filteredFavorites = filtered;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort By', style: theme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              ...['Recently Added', 'Alphabetical', 'Age', 'Breed'].map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: _sortOption == option
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _sortOption = option;
                      _filterAndSortFavorites();
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeFavorite(int petId) async {
    // Salvează pet-ul pentru undo
    final removedPetIndex = _allFavorites.indexWhere((pet) => pet["id"] == petId);
    final removedPet = removedPetIndex != -1 ? _allFavorites[removedPetIndex] : null;
    final removedFavIndex = _favoritePets.indexWhere((fav) => fav.id == petId);

    // Elimină din UI imediat pentru feedback rapid
    setState(() {
      _allFavorites.removeWhere((pet) => pet["id"] == petId);
      if (removedFavIndex != -1) {
        _favoritePets.removeAt(removedFavIndex);
      }
      _filterAndSortFavorites();
    });

    try {
      await _favoriteService.removeFavorite(petId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from favorites'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Readaugă în favorites
                try {
                  await _favoriteService.addFavorite(petId);
                  _loadFavorites(); // Reîncarcă lista
                } catch (e) {
                  print('Error undoing remove: $e');
                }
              },
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      // Restaurează pet-ul în UI dacă API-ul eșuează
      if (removedPet != null && mounted) {
        setState(() {
          _allFavorites.insert(removedPetIndex, removedPet);
          _filterAndSortFavorites();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Restaurează pet-ul în UI dacă API-ul eșuează
      if (removedPet != null && mounted) {
        setState(() {
          _allFavorites.insert(removedPetIndex, removedPet);
          _filterAndSortFavorites();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not remove from favorites'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showContextMenu(Map<String, dynamic> pet) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text('Remove from Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveConfirmation(pet["id"] as int);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Share Pet'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share functionality coming soon')),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'pets',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Apply to Adopt'),
                onTap: () {
                  Navigator.pop(context);
                  _applyToAdopt(pet);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveConfirmation(int petId) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('Remove from Favorites?'),
          content: Text(
            'Are you sure you want to remove this pet from your favorites?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeFavorite(petId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text('REMOVE'),
            ),
          ],
        );
      },
    );
  }

  void _applyToAdopt(Map<String, dynamic> pet) {
    if (!(pet["available"] as bool)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This pet is no longer available for adoption'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Apply to Adopt ${pet["name"]}'),
          content: Text(
            'Your adoption application has been submitted. We\'ll contact you soon!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshFavorites() async {
    await _loadFavorites();

    if (mounted && !_hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Favorites updated')));
    }
  }

  void _navigateToMainPets() {
    Navigator.of(context, rootNavigator: true).pushNamed('/main-pets-screen');
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: theme.colorScheme.error,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'Could not load favorites',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Please try again later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPetDetail(Map<String, dynamic> pet) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/pet-detail-screen', arguments: pet);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with search and sort
        FavoritesHeaderWidget(
          searchController: _searchController,
          onSortPressed: _showSortOptions,
        ),

        // Main content
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : _hasError
              ? _buildErrorState()
              : _filteredFavorites.isEmpty
              ? EmptyFavoritesWidget(onStartSwipingPressed: _navigateToMainPets)
              : RefreshIndicator(
                  onRefresh: _refreshFavorites,
                  child: GridView.builder(
                    padding: EdgeInsets.all(4.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                    ),
                    itemCount: _filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final pet = _filteredFavorites[index];
                      return FavoritePetCardWidget(
                        pet: pet,
                        onTap: () => _navigateToPetDetail(pet),
                        onLongPress: () => _showContextMenu(pet),
                        onRemove: () =>
                            _showRemoveConfirmation(pet["id"] as int),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
