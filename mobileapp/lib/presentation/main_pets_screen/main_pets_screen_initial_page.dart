import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
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
  bool _showUndoButton = false;
  bool _isLoading = true;
  int _currentCardIndex = 0;

  final List<Map<String, dynamic>> _petData = [
    {
      "id": 1,
      "name": "Luna",
      "age": "2 years",
      "breed": "Golden Retriever",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d",
      "semanticLabel":
          "Golden Retriever dog with fluffy golden fur sitting outdoors in natural lighting",
      "bio":
          "Luna is a friendly and energetic Golden Retriever who loves playing fetch and swimming. She's great with children and other pets.",
      "healthStatus": "Vaccinated, Spayed, Microchipped",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d",
          "semanticLabel":
              "Golden Retriever dog with fluffy golden fur sitting outdoors in natural lighting",
        },
        {
          "url": "https://images.unsplash.com/photo-1632366941290-f3248eb1699f",
          "semanticLabel":
              "Golden Retriever puppy lying on grass with tongue out",
        },
      ],
    },
    {
      "id": 2,
      "name": "Max",
      "age": "3 years",
      "breed": "Labrador",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1507270603269-dbbf5099b47c",
      "semanticLabel":
          "Black Labrador dog with shiny coat sitting attentively with alert expression",
      "bio":
          "Max is a loyal and intelligent Labrador who enjoys long walks and training sessions. He's well-behaved and house-trained.",
      "healthStatus": "Vaccinated, Neutered, Microchipped",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1507270603269-dbbf5099b47c",
          "semanticLabel":
              "Black Labrador dog with shiny coat sitting attentively with alert expression",
        },
        {
          "url": "https://images.unsplash.com/photo-1575493125700-d31ebbc72b09",
          "semanticLabel":
              "Black Labrador running through water with joyful expression",
        },
      ],
    },
    {
      "id": 3,
      "name": "Bella",
      "age": "1 year",
      "breed": "Persian Cat",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1612801143784-84b527938e53",
      "semanticLabel":
          "White Persian cat with fluffy fur and blue eyes looking directly at camera",
      "bio":
          "Bella is a gentle and affectionate Persian cat who loves cuddles and quiet environments. She's perfect for apartment living.",
      "healthStatus": "Vaccinated, Spayed, Dewormed",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1612801143784-84b527938e53",
          "semanticLabel":
              "White Persian cat with fluffy fur and blue eyes looking directly at camera",
        },
        {
          "url": "https://images.unsplash.com/photo-1575408824052-8f497497f04b",
          "semanticLabel": "White Persian cat grooming itself on soft blanket",
        },
      ],
    },
    {
      "id": 4,
      "name": "Charlie",
      "age": "4 years",
      "breed": "Beagle",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1603088839340-d73e99dd831a",
      "semanticLabel":
          "Beagle dog with brown and white coat sitting on wooden deck with curious expression",
      "bio":
          "Charlie is a playful and curious Beagle with a great sense of smell. He loves outdoor adventures and exploring new places.",
      "healthStatus": "Vaccinated, Neutered, Microchipped",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1603088839340-d73e99dd831a",
          "semanticLabel":
              "Beagle dog with brown and white coat sitting on wooden deck with curious expression",
        },
        {
          "url": "https://images.unsplash.com/photo-1548980939-59b205ca539d",
          "semanticLabel":
              "Beagle dog running through autumn leaves with happy expression",
        },
      ],
    },
    {
      "id": 5,
      "name": "Daisy",
      "age": "2 years",
      "breed": "Siamese Cat",
      "gender": "Female",
      "image": "https://images.unsplash.com/photo-1709262315195-3254daf9068c",
      "semanticLabel":
          "Siamese cat with cream and brown points sitting elegantly with blue eyes",
      "bio":
          "Daisy is a vocal and social Siamese cat who loves attention and interactive play. She's very intelligent and learns tricks quickly.",
      "healthStatus": "Vaccinated, Spayed, Microchipped",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1709262315195-3254daf9068c",
          "semanticLabel":
              "Siamese cat with cream and brown points sitting elegantly with blue eyes",
        },
        {
          "url": "https://images.unsplash.com/photo-1624268898688-2e745a947348",
          "semanticLabel": "Siamese cat playing with toy on carpet",
        },
      ],
    },
    {
      "id": 6,
      "name": "Rocky",
      "age": "5 years",
      "breed": "German Shepherd",
      "gender": "Male",
      "image": "https://images.unsplash.com/photo-1582660482303-0b292b0971fe",
      "semanticLabel":
          "German Shepherd dog with black and tan coat sitting alert with pointed ears",
      "bio":
          "Rocky is a protective and loyal German Shepherd who makes an excellent guard dog. He's well-trained and responds to commands.",
      "healthStatus": "Vaccinated, Neutered, Microchipped",
      "gallery": [
        {
          "url": "https://images.unsplash.com/photo-1582660482303-0b292b0971fe",
          "semanticLabel":
              "German Shepherd dog with black and tan coat sitting alert with pointed ears",
        },
        {
          "url":
              "https://img.rocket.new/generatedImages/rocket_gen_img_1c0db7698-1764889533933.png",
          "semanticLabel":
              "German Shepherd running through field with focused expression",
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPets() async {
    await _loadPets();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.right) {
      HapticFeedback.lightImpact();
      _showUndoButtonTemporarily();
    } else if (direction == CardSwiperDirection.left) {
      HapticFeedback.lightImpact();
      _showUndoButtonTemporarily();
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
              : _currentCardIndex >= _petData.length
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
                        cardsCount: _petData.length,
                        onSwipe: _onSwipe,
                        numberOfCardsDisplayed: 3,
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
                                pet: _petData[index],
                                onTap: () =>
                                    _navigateToPetDetail(_petData[index]),
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
