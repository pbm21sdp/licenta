import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Recently Added';

  // Mock data for favorites - Session-based persistence
  final List<Map<String, dynamic>> _allFavorites = [
    {
      "id": 1,
      "name": "Luna",
      "age": "2 years",
      "breed": "Golden Retriever",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d",
      "semanticLabel":
          "Golden Retriever dog with fluffy golden fur sitting outdoors in sunlight",
      "bio":
          "Luna is a friendly and energetic Golden Retriever who loves playing fetch and swimming. She's great with children and other pets.",
      "healthStatus": "Vaccinated, Spayed, Microchipped",
      "addedDate": DateTime.now().subtract(Duration(days: 2)),
      "available": true,
    },
    {
      "id": 2,
      "name": "Max",
      "age": "3 years",
      "breed": "Labrador",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1593642867074-f6e8a4275b28",
      "semanticLabel":
          "Black Labrador dog with shiny coat sitting on grass looking at camera",
      "bio":
          "Max is a loyal and gentle Labrador who enjoys long walks and cuddles. He's well-trained and perfect for families.",
      "healthStatus": "Vaccinated, Neutered, Healthy",
      "addedDate": DateTime.now().subtract(Duration(days: 5)),
      "available": true,
    },
    {
      "id": 3,
      "name": "Whiskers",
      "age": "1 year",
      "breed": "Persian Cat",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1696996752553-fc0abffc4e80",
      "semanticLabel":
          "White Persian cat with fluffy fur and blue eyes sitting on wooden surface",
      "bio":
          "Whiskers is a calm and affectionate Persian cat who loves quiet environments and gentle petting. Perfect for apartment living.",
      "healthStatus": "Vaccinated, Neutered, Indoor Cat",
      "addedDate": DateTime.now().subtract(Duration(days: 1)),
      "available": true,
    },
    {
      "id": 4,
      "name": "Bella",
      "age": "4 years",
      "breed": "Beagle",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1710979421781-b22afa51211c",
      "semanticLabel":
          "Beagle dog with brown and white coat sitting on grass with tongue out",
      "bio":
          "Bella is a curious and playful Beagle with a great sense of smell. She loves outdoor adventures and treats.",
      "healthStatus": "Vaccinated, Spayed, Healthy",
      "addedDate": DateTime.now().subtract(Duration(days: 7)),
      "available": false,
    },
    {
      "id": 5,
      "name": "Charlie",
      "age": "5 years",
      "breed": "Tabby Cat",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1602418013963-c1f017b3bb63",
      "semanticLabel":
          "Orange tabby cat with green eyes lying on wooden floor looking at camera",
      "bio":
          "Charlie is an independent and friendly tabby cat who enjoys sunbathing and bird watching. Great mouser!",
      "healthStatus": "Vaccinated, Neutered, Indoor/Outdoor",
      "addedDate": DateTime.now().subtract(Duration(days: 3)),
      "available": true,
    },
    {
      "id": 6,
      "name": "Daisy",
      "age": "2 years",
      "breed": "Poodle",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1653156849433-e61ad6f3c574",
      "semanticLabel":
          "White poodle with curly fur sitting on grass with happy expression",
      "bio":
          "Daisy is an intelligent and hypoallergenic Poodle who loves learning tricks and playing with toys.",
      "healthStatus": "Vaccinated, Spayed, Groomed",
      "addedDate": DateTime.now().subtract(Duration(days: 4)),
      "available": true,
    },
  ];

  List<Map<String, dynamic>> _filteredFavorites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredFavorites = List.from(_allFavorites);
    _searchController.addListener(_onSearchChanged);
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
      final name = (pet["name"] as String).toLowerCase();
      final breed = (pet["breed"] as String).toLowerCase();
      return name.contains(_searchQuery) || breed.contains(_searchQuery);
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case 'Recently Added':
        filtered.sort(
          (a, b) => (b["addedDate"] as DateTime).compareTo(
            a["addedDate"] as DateTime,
          ),
        );
        break;
      case 'Alphabetical':
        filtered.sort(
          (a, b) => (a["name"] as String).compareTo(b["name"] as String),
        );
        break;
      case 'Age':
        filtered.sort((a, b) {
          final ageA = int.parse((a["age"] as String).split(' ')[0]);
          final ageB = int.parse((b["age"] as String).split(' ')[0]);
          return ageA.compareTo(ageB);
        });
        break;
      case 'Breed':
        filtered.sort(
          (a, b) => (a["breed"] as String).compareTo(b["breed"] as String),
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

  void _removeFavorite(int petId) {
    setState(() {
      _allFavorites.removeWhere((pet) => pet["id"] == petId);
      _filterAndSortFavorites();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed from favorites'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Undo functionality would restore the pet
          },
        ),
      ),
    );
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
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    // Update availability status (simulate real-time updates)
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Favorites updated')));
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
          child: _filteredFavorites.isEmpty
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
                          // Navigate to pet detail view
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pet detail view coming soon'),
                            ),
                          );
                        },
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
