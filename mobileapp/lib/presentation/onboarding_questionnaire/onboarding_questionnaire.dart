import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/preference_service.dart';
import '../../services/api_client.dart';
import './widgets/children_inquiry_widget.dart';
import './widgets/existing_pets_widget.dart';
import './widgets/garden_option_widget.dart';
import './widgets/pet_type_card_widget.dart';

/// Onboarding Questionnaire Screen
/// Collects user preferences through a 4-step wizard for personalized pet matching
class OnboardingQuestionnaire extends StatefulWidget {
  const OnboardingQuestionnaire({super.key});

  @override
  State<OnboardingQuestionnaire> createState() =>
      _OnboardingQuestionnaireState();
}

class _OnboardingQuestionnaireState extends State<OnboardingQuestionnaire>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentStep = 0;
  bool _isSaving = false;

  // Service pentru salvarea preferințelor
  final PreferenceService _preferenceService = PreferenceService();

  // Step 1: Pet type preference
  String? _selectedPetType;

  // Step 2: Garden access
  String? _selectedGardenType;

  // Step 3: Children presence
  bool _hasChildren = false;
  String? _childrenAgeRange;

  // Step 4: Existing pets
  final List<String> _existingPets = [];
  final Map<String, int> _petCounts = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedPetType != null;
      case 1:
        return _selectedGardenType != null;
      case 2:
        return true; // Always valid, toggle has default state
      case 3:
        return true; // Always valid, can have no existing pets
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/main-pets-screen', (route) => false);
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    // Pregătește datele preferințelor folosind UserPreferences
    final preferences = UserPreferences(
      preferredPetTypes: _selectedPetType != null ? [_selectedPetType!] : null,
      hasGarden: _selectedGardenType != 'No Garden',
      hasChildren: _hasChildren,
      childrenAges: _childrenAgeRange != null ? [_childrenAgeRange!] : null,
      hasOtherPets: _existingPets.isNotEmpty,
      otherPetTypes: _existingPets.isNotEmpty ? _existingPets : null,
    );

    try {
      // Salvează preferințele în backend
      await _preferenceService.savePreferences(preferences);
      print('Preferences saved successfully');
    } on ApiException catch (e) {
      print('API Error saving preferences: ${e.message}');
      // Continuă oricum - preferințele pot fi salvate ulterior
    } catch (e) {
      print('Error saving preferences: $e');
      // Continuă oricum - preferințele pot fi salvate ulterior
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    // Show celebration animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Theme.of(context).colorScheme.tertiary,
                size: 64,
              ),
              SizedBox(height: 2.h),
              Text(
                'Setup Complete!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Your personalized pet matches are ready',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamedAndRemoveUntil(
                      '/main-pets-screen',
                      (route) => false,
                    );
                  },
                  child: const Text('Start Discovering'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _previousStep,
              )
            : null,
        title: Text('Getting Started', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(theme),

            // Step content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                  _buildStep4(theme),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),
          Text(
            'Step ${_currentStep + 1} of 4',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageWidget(
            imageUrl:
                'https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800',
            width: double.infinity,
            height: 20.h,
            fit: BoxFit.cover,
            semanticLabel:
                'Illustration showing various types of pets including cats, dogs, and birds in a friendly setting',
          ),
          SizedBox(height: 3.h),
          Text(
            'What type of pet are you looking for?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Select the pet type that best matches your lifestyle',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          PetTypeCardWidget(
            petType: 'Cat',
            iconName: 'pets',
            isSelected: _selectedPetType == 'Cat',
            onTap: () {
              setState(() {
                _selectedPetType = 'Cat';
              });
            },
          ),
          SizedBox(height: 2.h),
          PetTypeCardWidget(
            petType: 'Dog',
            iconName: 'pets',
            isSelected: _selectedPetType == 'Dog',
            onTap: () {
              setState(() {
                _selectedPetType = 'Dog';
              });
            },
          ),
          SizedBox(height: 2.h),
          PetTypeCardWidget(
            petType: 'Bird',
            iconName: 'flutter_dash',
            isSelected: _selectedPetType == 'Bird',
            onTap: () {
              setState(() {
                _selectedPetType = 'Bird';
              });
            },
          ),
          SizedBox(height: 2.h),
          PetTypeCardWidget(
            petType: 'Other',
            iconName: 'more_horiz',
            isSelected: _selectedPetType == 'Other',
            onTap: () {
              setState(() {
                _selectedPetType = 'Other';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageWidget(
            imageUrl:
                'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800',
            width: double.infinity,
            height: 20.h,
            fit: BoxFit.cover,
            semanticLabel:
                'Beautiful garden with green grass, flowers, and a white fence in sunny weather',
          ),
          SizedBox(height: 3.h),
          Text(
            'Do you have garden access?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'This helps us match you with pets that suit your living space',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          GardenOptionWidget(
            title: 'Open Garden',
            description: 'Unfenced outdoor space',
            iconName: 'grass',
            isSelected: _selectedGardenType == 'Open Garden',
            onTap: () {
              setState(() {
                _selectedGardenType = 'Open Garden';
              });
            },
          ),
          SizedBox(height: 2.h),
          GardenOptionWidget(
            title: 'Closed Garden',
            description: 'Fenced or enclosed outdoor space',
            iconName: 'fence',
            isSelected: _selectedGardenType == 'Closed Garden',
            onTap: () {
              setState(() {
                _selectedGardenType = 'Closed Garden';
              });
            },
          ),
          SizedBox(height: 2.h),
          GardenOptionWidget(
            title: 'No Garden',
            description: 'Indoor living only',
            iconName: 'home',
            isSelected: _selectedGardenType == 'No Garden',
            onTap: () {
              setState(() {
                _selectedGardenType = 'No Garden';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageWidget(
            imageUrl:
                'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800',
            width: double.infinity,
            height: 20.h,
            fit: BoxFit.cover,
            semanticLabel:
                'Happy family with children playing with a golden retriever dog in a park',
          ),
          SizedBox(height: 3.h),
          Text(
            'Do you have children?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'We\'ll recommend pets that are great with kids',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ChildrenInquiryWidget(
            hasChildren: _hasChildren,
            selectedAgeRange: _childrenAgeRange,
            onToggleChanged: (value) {
              setState(() {
                _hasChildren = value;
                if (!value) {
                  _childrenAgeRange = null;
                }
              });
            },
            onAgeRangeSelected: (ageRange) {
              setState(() {
                _childrenAgeRange = ageRange;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageWidget(
            imageUrl:
                'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800',
            width: double.infinity,
            height: 20.h,
            fit: BoxFit.cover,
            semanticLabel:
                'Multiple pets together - a cat and dog sitting peacefully side by side on a couch',
          ),
          SizedBox(height: 3.h),
          Text(
            'Do you have existing pets?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Select all that apply and specify how many',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ExistingPetsWidget(
            selectedPets: _existingPets,
            petCounts: _petCounts,
            onPetToggled: (petType) {
              setState(() {
                if (_existingPets.contains(petType)) {
                  _existingPets.remove(petType);
                  _petCounts.remove(petType);
                } else {
                  _existingPets.add(petType);
                  _petCounts[petType] = 1;
                }
              });
            },
            onCountChanged: (petType, count) {
              setState(() {
                _petCounts[petType] = count;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
              SizedBox(width: 3.w),
            ],
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isStepValid() && !_isSaving ? _nextStep : null,
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(_currentStep == 3 ? 'Complete Setup' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
