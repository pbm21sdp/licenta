import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../onboarding_questionnaire/widgets/pet_type_card_widget.dart';
import '../../onboarding_questionnaire/widgets/garden_option_widget.dart';
import '../../onboarding_questionnaire/widgets/children_inquiry_widget.dart';
import '../../onboarding_questionnaire/widgets/existing_pets_widget.dart';

class PreferenceEditorModalWidget extends StatefulWidget {
  final Map<String, dynamic> currentPreferences;
  final Function(Map<String, dynamic>) onSave;

  const PreferenceEditorModalWidget({
    super.key,
    required this.currentPreferences,
    required this.onSave,
  });

  @override
  State<PreferenceEditorModalWidget> createState() =>
      _PreferenceEditorModalWidgetState();
}

class _PreferenceEditorModalWidgetState
    extends State<PreferenceEditorModalWidget> {
  late PageController _pageController;
  int _currentStep = 0;

  late String? _selectedPetType;
  late String? _selectedGardenType;
  late bool _hasChildren;
  late String? _childrenAgeRange;
  late List<String> _existingPets;
  late Map<String, int> _petCounts;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedPetType = widget.currentPreferences['petType'] as String?;
    _selectedGardenType = widget.currentPreferences['gardenAccess'] as String?;
    _hasChildren = widget.currentPreferences['hasChildren'] as bool? ?? false;
    _childrenAgeRange =
        widget.currentPreferences['childrenAgeRange'] as String?;
    _existingPets = List<String>.from(
      widget.currentPreferences['existingPets'] ?? [],
    );
    _petCounts = Map<String, int>.from(
      widget.currentPreferences['petCounts'] as Map? ?? {},
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedPetType != null;
      case 1:
        return _selectedGardenType != null;
      case 2:
        return true;
      case 3:
        return true;
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
      _savePreferences();
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

  void _savePreferences() {
    final updatedPreferences = {
      'petType': _selectedPetType,
      'gardenAccess': _selectedGardenType,
      'hasChildren': _hasChildren,
      'childrenAgeRange': _childrenAgeRange,
      'existingPets': _existingPets,
      'petCounts': _petCounts,
    };
    widget.onSave(updatedPreferences);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Edit Preferences',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 2.w),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildPetTypeStep(theme),
                _buildGardenStep(theme),
                _buildChildrenStep(theme),
                _buildExistingPetsStep(theme),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.08),
                  offset: Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 4.w),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _isStepValid() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        disabledBackgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.3),
                      ),
                      child: Text(_currentStep == 3 ? 'Save' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetTypeStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of pet are you looking for?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Select your preferred pet type',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          PetTypeCardWidget(
            petType: 'Dog',
            iconName: 'pets',
            isSelected: _selectedPetType == 'Dog',
            onTap: () => setState(() => _selectedPetType = 'Dog'),
          ),
          SizedBox(height: 2.h),
          PetTypeCardWidget(
            petType: 'Cat',
            iconName: 'pets',
            isSelected: _selectedPetType == 'Cat',
            onTap: () => setState(() => _selectedPetType = 'Cat'),
          ),
          SizedBox(height: 2.h),
          PetTypeCardWidget(
            petType: 'Both',
            iconName: 'pets',
            isSelected: _selectedPetType == 'Both',
            onTap: () => setState(() => _selectedPetType = 'Both'),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have garden access?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'This helps us match you with suitable pets',
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
              setState(() => _selectedGardenType = 'Open Garden');
            },
          ),
          SizedBox(height: 2.h),
          GardenOptionWidget(
            title: 'Closed Garden',
            description: 'Fenced or enclosed outdoor space',
            iconName: 'fence',
            isSelected: _selectedGardenType == 'Closed Garden',
            onTap: () {
              setState(() => _selectedGardenType = 'Closed Garden');
            },
          ),
          SizedBox(height: 2.h),
          GardenOptionWidget(
            title: 'No Garden',
            description: 'Indoor living only',
            iconName: 'home',
            isSelected: _selectedGardenType == 'No Garden',
            onTap: () {
              setState(() => _selectedGardenType = 'No Garden');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have children?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'We\'ll recommend child-friendly pets',
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
                if (!value) _childrenAgeRange = null;
              });
            },
            onAgeRangeSelected: (ageRange) {
              setState(() => _childrenAgeRange = ageRange);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExistingPetsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have existing pets?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'We\'ll find pets that get along well',
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
}
