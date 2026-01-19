import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/preference_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_modal_widget.dart';
import './widgets/pet_card_widget.dart';

class MainPetsScreenInitialPage extends StatefulWidget {
  const MainPetsScreenInitialPage({super.key});

  @override
  State<MainPetsScreenInitialPage> createState() =>
      _MainPetsScreenInitialPageState();
}

class _MainPetsScreenInitialPageState extends State<MainPetsScreenInitialPage>
    with WidgetsBindingObserver {
  final CardSwiperController _cardController = CardSwiperController();
  final PetService _petService = PetService();
  final AuthService _authService = AuthService();
  final PreferenceService _preferenceService = PreferenceService();

  bool _isLoading = true;
  int _currentCardIndex = 0;
  List<Map<String, dynamic>> _petData = [];
  final List<Map<String, String>> _undoQueue = [];
  static const int maxUndoQueueSize = 5;
  String? _currentUserId;
  String? _errorMessage;
  bool _isProcessingSwipe = false;

  // Filter state
  Map<String, dynamic>? _savedPreferences;
  Map<String, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload pets when user returns to this screen
      _loadPets();
    }
  }

  Future<void> _initializeUser() async {
    try {
      final user = _authService.currentUser;
      if (mounted) {
        setState(() {
          _currentUserId = user?.id;
        });
        // Load preferences first, then load pets with filters applied
        await _loadPreferences();
        _loadPets();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize: $e';
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await _preferenceService.getUserPreferences(_currentUserId!);
      if (mounted && prefs != null) {
        setState(() {
          _savedPreferences = prefs;
          // Initialize active filters from saved preferences
          _activeFilters = {
            'speciesFilter': prefs['preferred_pet_types'] ?? [],
            'hasGarden': prefs['has_garden'],
            'hasChildren': prefs['hasChildren'],
            'hasOtherPets': prefs['has_other_pets'],
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    }
  }

  Future<void> _loadPets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Extract filter values
      final speciesFilter = _activeFilters['speciesFilter'] as List?;
      final hasGarden = _activeFilters['hasGarden'] as bool?;
      final hasChildren = _activeFilters['hasChildren'] as bool?;
      final hasOtherPets = _activeFilters['hasOtherPets'] as bool?;

      final pets = await _petService.getAvailablePets(
        userId: _currentUserId,
        speciesFilter: speciesFilter != null && speciesFilter.isNotEmpty
            ? List<String>.from(speciesFilter)
            : null,
        hasGarden: hasGarden,
        hasChildren: hasChildren,
        hasOtherPets: hasOtherPets,
      );

      if (mounted) {
        setState(() {
          _petData = pets;
          _isLoading = false;
          _currentCardIndex = 0;
          _undoQueue.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load pets: $e';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load pets: $e')));
      }
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
    // Only allow left and right swipes
    if (direction != CardSwiperDirection.left &&
        direction != CardSwiperDirection.right) {
      return false;
    }

    // Prevent swiping beyond available pets
    if (previousIndex >= _petData.length) {
      return false;
    }

    // Prevent multiple simultaneous swipes
    if (_isProcessingSwipe) {
      return false;
    }

    final pet = _petData[previousIndex];
    final petId = pet['id'] as String;

    // Determine the action type
    final actionType = direction == CardSwiperDirection.right ? 'like' : 'skip';

    // Add to undo queue with action type
    if (_undoQueue.length >= maxUndoQueueSize) {
      _undoQueue.removeAt(0);
    }
    _undoQueue.add({'petId': petId, 'action': actionType});

    if (direction == CardSwiperDirection.right) {
      _handleLike(petId);
    } else if (direction == CardSwiperDirection.left) {
      _handleSkip(petId);
    }

    // Always update state to refresh undo button and card index
    setState(() {
      if (currentIndex != null) {
        _currentCardIndex = currentIndex;
      } else {
        // Last card was swiped - set index beyond array to trigger empty state
        _currentCardIndex = _petData.length;
      }
    });

    HapticFeedback.lightImpact();
    return true;
  }

  Future<void> _handleLike(String petId) async {
    if (_currentUserId == null) return;

    try {
      await _petService.addToFavorites(userId: _currentUserId!, petId: petId);
      await _petService.recordInteraction(
        userId: _currentUserId!,
        petId: petId,
        interactionType: 'like',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on PostgrestException catch (e) {
      // Handle duplicate favorites error specifically
      if (e.code == '23505') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This pet is already in your favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add to favorites: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to favorites: $e')),
        );
      }
    }
  }

  Future<void> _handleSkip(String petId) async {
    if (_currentUserId == null) return;

    try {
      await _petService.recordInteraction(
        userId: _currentUserId!,
        petId: petId,
        interactionType: 'skip',
      );
    } catch (e) {
      // Silent fail for skip
    }
  }

  Future<void> _handleLikeButton() async {
    if (_currentCardIndex >= _petData.length || _isProcessingSwipe) return;
    if (_currentUserId == null) return;

    setState(() {
      _isProcessingSwipe = true;
    });

    try {
      final pet = _petData[_currentCardIndex];
      final petId = pet['id'] as String;

      // Perform database operations FIRST
      await _petService.addToFavorites(userId: _currentUserId!, petId: petId);
      await _petService.recordInteraction(
        userId: _currentUserId!,
        petId: petId,
        interactionType: 'like',
      );

      // Add to undo queue (for button-triggered swipes)
      if (_undoQueue.length >= maxUndoQueueSize) {
        _undoQueue.removeAt(0);
      }
      _undoQueue.add({'petId': petId, 'action': 'like'});

      // Only swipe if operation succeeded
      if (mounted) {
        _cardController.swipe(CardSwiperDirection.right);
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } on PostgrestException catch (e) {
      // Handle duplicate favorites error - don't swipe the card
      if (mounted) {
        if (e.code == '23505') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This pet is already in your favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add to favorites: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to favorites: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSwipe = false;
        });
      }
    }
  }

  Future<void> _handleSkipButton() async {
    if (_currentCardIndex >= _petData.length || _isProcessingSwipe) return;
    if (_currentUserId == null) return;

    setState(() {
      _isProcessingSwipe = true;
    });

    try {
      final pet = _petData[_currentCardIndex];
      final petId = pet['id'] as String;

      // Perform database operations FIRST
      await _petService.recordInteraction(
        userId: _currentUserId!,
        petId: petId,
        interactionType: 'skip',
      );

      // Add to undo queue (for button-triggered swipes)
      if (_undoQueue.length >= maxUndoQueueSize) {
        _undoQueue.removeAt(0);
      }
      _undoQueue.add({'petId': petId, 'action': 'skip'});

      // Only swipe if operation succeeded
      if (mounted) {
        _cardController.swipe(CardSwiperDirection.left);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to skip: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSwipe = false;
        });
      }
    }
  }

  Future<void> _handleUndo() async {
    if (_undoQueue.isEmpty || _currentUserId == null) return;

    final lastAction = _undoQueue.removeLast();
    final petId = lastAction['petId']!;
    final action = lastAction['action']!;

    try {
      // Reverse the database action by removing the interaction
      // Uses matching criteria to handle race conditions
      await _petService.removeInteraction(
        userId: _currentUserId!,
        petId: petId,
        interactionType: action,
      );

      // If it was a like, also remove from favorites
      if (action == 'like') {
        await _petService.removeFromFavorites(
          userId: _currentUserId!,
          petId: petId,
        );
      }

      // Restore the card in the UI
      _cardController.undo();
      HapticFeedback.mediumImpact();

      setState(() {
        if (_currentCardIndex > 0) {
          _currentCardIndex--;
        }
      });
    } catch (e) {
      // Re-add to queue if undo failed
      _undoQueue.add(lastAction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo: $e')),
        );
      }
    }
  }

  void _navigateToPetDetail(Map<String, dynamic> pet) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/pet-detail-screen', arguments: pet);
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModalWidget(
        currentFilters: _activeFilters,
        savedPreferences: _savedPreferences,
        onApply: (filters) {
          setState(() {
            // Merge new species filter with existing preference-based filters
            _activeFilters = {
              ..._activeFilters,
              'speciesFilter': filters['speciesFilter'],
            };
          });
          _loadPets();
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cardController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required double size,
    required String iconName,
    required Color iconColor,
    required Color backgroundColor,
    required Color shadowColor,
    double iconSize = 32,
    VoidCallback? onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: CustomIconWidget(
              iconName: iconName,
              color: iconColor,
              size: iconSize,
            ),
          ),
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
                onPressed: _showFilterModal,
                icon: CustomIconWidget(
                  iconName: 'tune',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                tooltip: 'Filter Pets',
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
              : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'error_outline',
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        SizedBox(height: 3.h),
                        ElevatedButton.icon(
                          onPressed: _loadPets,
                          icon: CustomIconWidget(
                            iconName: 'refresh',
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Show either pet cards or empty state
                    if (_petData.isEmpty || _currentCardIndex >= _petData.length)
                      EmptyStateWidget(onRefresh: _refreshPets)
                    else
                      Padding(
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          top: 2.h,
                          bottom: 15.h, // Space for buttons
                        ),
                        child: CardSwiper(
                          controller: _cardController,
                          cardsCount: _petData.length,
                          onSwipe: _onSwipe,
                          isLoop: false,
                          numberOfCardsDisplayed: _petData.length < 3
                              ? _petData.length
                              : 3,
                          backCardOffset: const Offset(0, 40),
                          padding: EdgeInsets.zero,
                          allowedSwipeDirection: const AllowedSwipeDirection.only(
                            left: true,
                            right: true,
                          ),
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

                    // Action buttons - visible when cards present OR undo queue has items
                    if ((_petData.isNotEmpty && _currentCardIndex < _petData.length) ||
                        _undoQueue.isNotEmpty)
                      Positioned(
                        bottom: 4.h,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Skip button (X icon, round) - disabled when empty
                            _buildActionButton(
                              theme: theme,
                              size: 60,
                              iconName: 'close',
                              iconColor: _currentCardIndex < _petData.length
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              backgroundColor: theme.colorScheme.surface,
                              shadowColor: theme.shadowColor.withValues(alpha: 0.15),
                              onTap: _currentCardIndex < _petData.length
                                  ? _handleSkipButton
                                  : null,
                            ),

                            SizedBox(width: 4.w),

                            // Undo button (round) - always enabled if queue not empty
                            _buildActionButton(
                              theme: theme,
                              size: 50,
                              iconName: 'undo',
                              iconSize: 24,
                              iconColor: _undoQueue.isNotEmpty
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              backgroundColor: theme.colorScheme.surface,
                              shadowColor: theme.shadowColor.withValues(alpha: 0.15),
                              onTap: _undoQueue.isNotEmpty ? _handleUndo : null,
                            ),

                            SizedBox(width: 4.w),

                            // Like button (heart icon, round) - disabled when empty
                            _buildActionButton(
                              theme: theme,
                              size: 60,
                              iconName: 'favorite',
                              iconColor: _currentCardIndex < _petData.length
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              backgroundColor: _currentCardIndex < _petData.length
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                              shadowColor: _currentCardIndex < _petData.length
                                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : theme.shadowColor.withValues(alpha: 0.15),
                              onTap: _currentCardIndex < _petData.length
                                  ? _handleLikeButton
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
