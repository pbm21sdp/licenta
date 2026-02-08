// lib/presentation/add_pet_screen/add_pet_screen.dart
// Ecran pentru adăugarea unui animal nou

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/user_pets_service.dart';
import '../../services/api_client.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserPetsService _userPetsService = UserPetsService();

  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthStatusController = TextEditingController();
  final _storyController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Selected values
  String _selectedType = 'dog';
  String _selectedAge = 'adult';
  String _selectedGender = 'male';
  String _selectedSize = 'medium';
  String? _selectedColor;
  final List<String> _selectedTraits = [];
  final List<String> _photoUrls = [];

  final List<String> _petTypes = ['dog', 'cat', 'bird', 'rabbit', 'other'];
  final List<String> _ageCategories = ['puppy', 'young', 'adult', 'senior'];
  final List<String> _genders = ['male', 'female', 'unknown'];
  final List<String> _sizes = ['small', 'medium', 'large'];
  final List<String> _availableTraits = [
    'friendly', 'energetic', 'calm', 'playful', 'good_with_kids',
    'good_with_pets', 'trained', 'vaccinated', 'neutered', 'house_trained',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    _healthStatusController.dispose();
    _storyController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _feeController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pet = await _userPetsService.createPet(
        name: _nameController.text.trim(),
        type: _selectedType,
        breed: _breedController.text.trim().isNotEmpty ? _breedController.text.trim() : null,
        ageCategory: _selectedAge,
        gender: _selectedGender,
        size: _selectedSize,
        color: _selectedColor,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        healthStatus: _healthStatusController.text.trim().isNotEmpty
            ? _healthStatusController.text.trim()
            : null,
        story: _storyController.text.trim().isNotEmpty
            ? _storyController.text.trim()
            : null,
        locationCity: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        locationAddress: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        fee: _feeController.text.trim().isNotEmpty
            ? double.tryParse(_feeController.text.trim())
            : null,
        shelterContactEmail: _contactEmailController.text.trim().isNotEmpty
            ? _contactEmailController.text.trim()
            : null,
        shelterContactPhone: _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : null,
        traits: _selectedTraits.isNotEmpty ? _selectedTraits : null,
        photos: _photoUrls.isNotEmpty ? _photoUrls : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pet.name} has been listed successfully!'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPhotoUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Photo URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Photo URL',
              hintText: 'https://example.com/photo.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _photoUrls.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'List a Pet',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: _isLoading && _currentStep == 3
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(_currentStep == 3 ? 'List Pet' : 'Continue'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    SizedBox(width: 3.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              subtitle: const Text('Name, type, breed'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildBasicInfoStep(theme),
            ),
            Step(
              title: const Text('Characteristics'),
              subtitle: const Text('Age, gender, size'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildCharacteristicsStep(theme),
            ),
            Step(
              title: const Text('Details'),
              subtitle: const Text('Description, health, story'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildDetailsStep(theme),
            ),
            Step(
              title: const Text('Contact & Photos'),
              subtitle: const Text('Location, contact, photos'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: _buildContactStep(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Pet Name *',
            hintText: 'Enter pet name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a name';
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),
        Text('Pet Type *', style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _petTypes.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(_formatLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
            );
          }).toList(),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _breedController,
          decoration: const InputDecoration(
            labelText: 'Breed',
            hintText: 'Enter breed (optional)',
          ),
        ),
      ],
    );
  }

  Widget _buildCharacteristicsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Category', style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _ageCategories.map((age) {
            return ChoiceChip(
              label: Text(_formatLabel(age)),
              selected: _selectedAge == age,
              onSelected: (selected) {
                if (selected) setState(() => _selectedAge = age);
              },
            );
          }).toList(),
        ),
        SizedBox(height: 2.h),
        Text('Gender', style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _genders.map((gender) {
            return ChoiceChip(
              label: Text(_formatLabel(gender)),
              selected: _selectedGender == gender,
              onSelected: (selected) {
                if (selected) setState(() => _selectedGender = gender);
              },
            );
          }).toList(),
        ),
        SizedBox(height: 2.h),
        Text('Size', style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _sizes.map((size) {
            return ChoiceChip(
              label: Text(_formatLabel(size)),
              selected: _selectedSize == size,
              onSelected: (selected) {
                if (selected) setState(() => _selectedSize = size);
              },
            );
          }).toList(),
        ),
        SizedBox(height: 2.h),
        Text('Traits', style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _availableTraits.map((trait) {
            final isSelected = _selectedTraits.contains(trait);
            return FilterChip(
              label: Text(_formatLabel(trait)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTraits.add(trait);
                  } else {
                    _selectedTraits.remove(trait);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Tell us about your pet...',
          ),
          maxLines: 3,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _healthStatusController,
          decoration: const InputDecoration(
            labelText: 'Health Status',
            hintText: 'Vaccinations, medical conditions...',
          ),
          maxLines: 2,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _storyController,
          decoration: const InputDecoration(
            labelText: 'Story',
            hintText: 'How did you get this pet?',
          ),
          maxLines: 3,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _feeController,
          decoration: const InputDecoration(
            labelText: 'Adoption Fee',
            hintText: '0 for free adoption',
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildContactStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            hintText: 'Where is the pet located?',
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Street address (optional)',
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _contactEmailController,
          decoration: const InputDecoration(
            labelText: 'Contact Email',
            hintText: 'Leave empty to use your account email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _contactPhoneController,
          decoration: const InputDecoration(
            labelText: 'Contact Phone',
            hintText: 'Phone number (optional)',
          ),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Photos', style: theme.textTheme.bodyMedium),
            TextButton.icon(
              onPressed: _addPhotoUrl,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add URL'),
            ),
          ],
        ),
        if (_photoUrls.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _photoUrls.asMap().entries.map((entry) {
              return Chip(
                label: Text('Photo ${entry.key + 1}'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() => _photoUrls.removeAt(entry.key));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _formatLabel(String value) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
