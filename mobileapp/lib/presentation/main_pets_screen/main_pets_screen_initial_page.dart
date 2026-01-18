import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/pet_service.dart';
import '../../services/api_client.dart';
import '../../data/models/pet_model.dart';
import './widgets/empty_state_widget.dart';
import './widgets/pet_card_widget.dart';

class MainPetsScreenInitialPage extends StatefulWidget {
  const MainPetsScreenInitialPage({super.key});

  @override
  State<MainPetsScreenInitialPage> createState() =>
      _MainPetsScreenInitialPageState();
}

class _MainPetsScreenInitialPageState extends State<MainPetsScreenInitialPage> {
  final CardSwiperController _cardController = CardSwiperController();
  final PetService _petService = PetService();

  bool _showUndoButton = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentCardIndex = 0;

  // Lista de animale de la API
  List<PetModel> _pets = [];

  // Date mock pentru fallback când nu există conexiune la server
  final List<Map<String, dynamic>> _mockPetData = [
    {
      "id": 1,
      "name": "Luna",
      "age": "2 years",
      "breed": "Golden Retriever",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d",
      "semanticLabel": "Luna, Golden Retriever, 2 years",
      "bio": "Luna is a friendly and energetic Golden Retriever who loves playing fetch and swimming.",
      "healthStatus": "Vaccinated, Spayed, Microchipped",
    },
    {
      "id": 2,
      "name": "Max",
      "age": "3 years",
      "breed": "Labrador",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1507270603269-dbbf5099b47c",
      "semanticLabel": "Max, Labrador, 3 years",
      "bio": "Max is a loyal and intelligent Labrador who enjoys long walks and training sessions.",
      "healthStatus": "Vaccinated, Neutered, Microchipped",
    },
    {
      "id": 3,
      "name": "Bella",
      "age": "1 year",
      "breed": "Persian Cat",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1612801143784-84b527938e53",
      "semanticLabel": "Bella, Persian Cat, 1 year",
      "bio": "Bella is a gentle and affectionate Persian cat who loves cuddles.",
      "healthStatus": "Vaccinated, Spayed, Dewormed",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Încearcă să încarce animalele de la API
      final pets = await _petService.getSwipePets(limit: 10);

      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
          _currentCardIndex = 0;
        });
      }
    } on ApiException catch (e) {
      print('API Error: ${e.message}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Nu se pot încărca animalele. Verifică conexiunea.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPets() async {
    _currentCardIndex = 0;
    await _loadPets();
  }

  // Convertește PetModel la Map pentru compatibilitate cu widget-urile existente
  Map<String, dynamic> _petToMap(PetModel pet) {
    return {
      "id": pet.id,
      "name": pet.name,
      "age": pet.ageDisplay,
      "breed": pet.breed ?? "Unknown",
      "gender": pet.genderDisplay,
      "image": pet.imageUrl,
      "semanticLabel": "${pet.name}, ${pet.breed ?? 'Unknown breed'}, ${pet.ageDisplay}",
      "bio": pet.description ?? pet.story ?? "No description available.",
      "healthStatus": pet.healthStatus ?? "Health status not available",
      "gallery": pet.galleryUrls.map((url) => {"url": url}).toList(),
    };
  }

  // Obține datele pentru afișare (API sau mock)
  List<Map<String, dynamic>> get _displayPets {
    if (_pets.isNotEmpty) {
      return _pets.map((pet) => _petToMap(pet)).toList();
    }
    return _mockPetData;
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // Obține pet-ul care a fost swiped
    final swipedPet = _pets.isNotEmpty && previousIndex < _pets.length
        ? _pets[previousIndex]
        : null;

    if (direction == CardSwiperDirection.right) {
      HapticFeedback.lightImpact();
      _showUndoButtonTemporarily();
      // Like - trimite la API
      if (swipedPet != null) {
        _petService.likePet(swipedPet.id).catchError((e) {
          print('Error liking pet: $e');
        });
      }
    } else if (direction == CardSwiperDirection.left) {
      HapticFeedback.lightImpact();
      _showUndoButtonTemporarily();
      // Pass - trimite la API
      if (swipedPet != null) {
        _petService.passPet(swipedPet.id).catchError((e) {
          print('Error passing pet: $e');
        });
      }
    }

    if (currentIndex != null) {
      setState(() {
        _currentCardIndex = currentIndex;
      });
    }

    return true; // Allow the swipe
  }

  void _showUndoButtonTemporarily() {
    setState(() {
      _showUndoButton = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showUndoButton = false;
        });
      }
    });
  }

  void _undoSwipe() {
    _cardController.undo();
    HapticFeedback.mediumImpact();
    setState(() {
      _showUndoButton = false;
      if (_currentCardIndex > 0) {
        _currentCardIndex--;
      }
    });
  }

  void _navigateToPetDetail(Map<String, dynamic> pet) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/pet-detail-screen', arguments: pet);
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
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
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Could not load pets. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _refreshPets,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 2.h,
            left: 4.w,
            right: 4.w,
            bottom: 2.h,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discover Pets',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/account-management-screen');
                },
                icon: CustomIconWidget(
                  iconName: 'tune',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                tooltip: 'Preferences',
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              : _hasError
              ? _buildErrorState()
              : _displayPets.isEmpty || _currentCardIndex >= _displayPets.length
              ? EmptyStateWidget(onRefresh: _refreshPets)
              : Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      child: CardSwiper(
                        controller: _cardController,
                        cardsCount: _displayPets.length,
                        onSwipe: _onSwipe,
                        onEnd: () {
                          // Called when all cards have been swiped
                          setState(() {
                            _currentCardIndex = _displayPets.length;
                          });
                        },
                        isLoop: false,
                        numberOfCardsDisplayed: _displayPets.length >= 3 ? 3 : _displayPets.length,
                        backCardOffset: const Offset(0, 40),
                        padding: EdgeInsets.zero,
                        cardBuilder:
                            (
                              context,
                              index,
                              horizontalThresholdPercentage,
                              verticalThresholdPercentage,
                            ) {
                              return PetCardWidget(
                                pet: _displayPets[index],
                                onTap: () =>
                                    _navigateToPetDetail(_displayPets[index]),
                              );
                            },
                      ),
                    ),
                    if (_showUndoButton)
                      Positioned(
                        bottom: 4.h,
                        right: 4.w,
                        child: AnimatedOpacity(
                          opacity: _showUndoButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: FloatingActionButton(
                            onPressed: _undoSwipe,
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            child: CustomIconWidget(
                              iconName: 'undo',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
