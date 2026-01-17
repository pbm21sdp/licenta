import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';
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
  final PetService _petService = PetService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortOption = 'Recently Added';
  List<Map<String, dynamic>> _allFavorites = [];
  List<Map<String, dynamic>> _filteredFavorites = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final user = _authService.currentUser;
      if (mounted) {
        setState(() {
          _currentUserId = user?.id;
        });
        _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavorites() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
        _allFavorites = [];
        _filteredFavorites = [];
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final favorites = await _petService.getUserFavorites(
        userId: _currentUserId!,
      );

      if (mounted) {
        setState(() {
          _allFavorites = favorites;
          _filterAndSortFavorites();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load favorites: $e')));
      }
    }
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
      final name = (pet["name"] as String? ?? '').toLowerCase();
      final breed = (pet["breed"] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery) || breed.contains(_searchQuery);
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case 'Recently Added':
        filtered.sort((a, b) {
          final dateA = a["added_date"] as String?;
          final dateB = b["added_date"] as String?;
          if (dateA == null || dateB == null) return 0;
          return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
        });
        break;
      case 'Alphabetical':
        filtered.sort((a, b) {
          final nameA = a["name"] as String? ?? '';
          final nameB = b["name"] as String? ?? '';
          return nameA.compareTo(nameB);
        });
        break;
      case 'Age':
        filtered.sort((a, b) {
          final ageA = a["age_years"] as int? ?? 0;
          final ageB = b["age_years"] as int? ?? 0;
          return ageA.compareTo(ageB);
        });
        break;
      case 'Breed':
        filtered.sort((a, b) {
          final breedA = a["breed"] as String? ?? '';
          final breedB = b["breed"] as String? ?? '';
          return breedA.compareTo(breedB);
        });
        break;
    }

    setState(() {
      _filteredFavorites = filtered;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
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

  Future<void> _removeFavorite(String petId) async {
    if (_currentUserId == null) return;

    try {
      await _petService.removeFromFavorites(
        userId: _currentUserId!,
        petId: petId,
      );

      setState(() {
        _allFavorites.removeWhere((pet) => pet["id"] == petId);
        _filterAndSortFavorites();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove from favorites: $e')),
        );
      }
    }
  }

  void _showContextMenu(Map<String, dynamic> pet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
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
                title: const Text('Remove from Favorites'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Remove from Favorites?'),
                        content: const Text(
                          'Are you sure you want to remove this pet from your favorites?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('REMOVE'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    _removeFavorite(pet["id"] as String);
                  }
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'pets',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Apply to Adopt'),
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

  void _applyToAdopt(Map<String, dynamic> pet) {
    if (!(pet["is_available"] as bool? ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This pet is no longer available for adoption'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/pet-detail-screen', arguments: pet);
  }

  Future<void> _refreshFavorites() async {
    await _loadFavorites();
  }

  void _navigateToMainPets() {
    Navigator.of(context, rootNavigator: true).pushNamed('/main-pets-screen');
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
                        onTap: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed('/pet-detail-screen', arguments: pet);
                        },
                        onLongPress: () => _showContextMenu(pet),
                        onRemove: () => _removeFavorite(pet["id"] as String),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
