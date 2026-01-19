import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/shelter_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Screen for adding or editing pet listings
class ShelterPetEditorScreen extends StatefulWidget {
  final String? petId;
  final String? shelterId;

  const ShelterPetEditorScreen({
    super.key,
    this.petId,
    this.shelterId,
  });

  @override
  State<ShelterPetEditorScreen> createState() => _ShelterPetEditorScreenState();
}

class _ShelterPetEditorScreenState extends State<ShelterPetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shelterService = ShelterService.instance;
  final _authService = AuthService.instance;

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthStatusController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _species = 'dog';
  String _gender = 'male';
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _shelterId;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    _shelterId = widget.shelterId;
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Get shelter ID if not provided
    if (_shelterId == null) {
      final shelterId = await _authService.getStaffShelterId();
      if (shelterId == null && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _shelterId = shelterId;
    }

    // Load existing pet data if editing
    if (_isEditing) {
      setState(() => _isLoading = true);
      try {
        final pet = await _shelterService.getPetById(widget.petId!);
        if (pet != null && mounted) {
          setState(() {
            _nameController.text = pet['name'] as String? ?? '';
            _breedController.text = pet['breed'] as String? ?? '';
            _ageController.text = (pet['age_years'] as int?)?.toString() ?? '';
            _descriptionController.text = pet['description'] as String? ?? '';
            _healthStatusController.text = pet['health_status'] as String? ?? '';
            _imageUrlController.text = pet['image_url'] as String? ?? '';
            _species = pet['species'] as String? ?? 'dog';
            _gender = pet['gender'] as String? ?? 'male';
            _isAvailable = pet['is_available'] as bool? ?? true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading pet: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _healthStatusController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shelterId == null) return;

    setState(() => _isSaving = true);

    try {
      final ageYears = int.tryParse(_ageController.text) ?? 1;

      if (_isEditing) {
        await _shelterService.updatePet(
          petId: widget.petId!,
          name: _nameController.text.trim(),
          species: _species,
          breed: _breedController.text.trim(),
          ageYears: ageYears,
          gender: _gender,
          description: _descriptionController.text.trim(),
          healthStatus: _healthStatusController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          imageSemanticLabel:
              'Photo of ${_nameController.text.trim()}, a $_species',
          isAvailable: _isAvailable,
        );
      } else {
        await _shelterService.createPet(
          shelterId: _shelterId!,
          name: _nameController.text.trim(),
          species: _species,
          breed: _breedController.text.trim(),
          ageYears: ageYears,
          gender: _gender,
          description: _descriptionController.text.trim(),
          healthStatus: _healthStatusController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          imageSemanticLabel:
              'Photo of ${_nameController.text.trim()}, a $_species',
          isAvailable: _isAvailable,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Pet updated successfully' : 'Pet added successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pet: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pet' : 'Add Pet'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const CustomIconWidget(iconName: 'arrow_back', size: 24),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePet,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: _imageUrlController.text.isNotEmpty
                              ? Image.network(
                                  _imageUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: CustomIconWidget(
                                      iconName: 'pets',
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: CustomIconWidget(
                                    iconName: 'add_photo_alternate',
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Image URL field
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Enter image URL',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Image URL is required';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 2.h),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter pet name',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 2.h),

                    // Species and Gender row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _species,
                            decoration: const InputDecoration(
                              labelText: 'Species',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'dog',
                                child: Text('Dog'),
                              ),
                              DropdownMenuItem(
                                value: 'cat',
                                child: Text('Cat'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _species = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.transgender),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _gender = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Breed and Age row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _breedController,
                            decoration: const InputDecoration(
                              labelText: 'Breed',
                              hintText: 'e.g., Golden Retriever',
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Breed is required';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              hintText: 'Years',
                              prefixIcon: Icon(Icons.cake),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Health status field
                    TextFormField(
                      controller: _healthStatusController,
                      decoration: const InputDecoration(
                        labelText: 'Health Status',
                        hintText: 'e.g., Vaccinated, Neutered',
                        prefixIcon: Icon(Icons.health_and_safety),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Health status is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell potential adopters about this pet...',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: 2.h),

                    // Availability toggle
                    Card(
                      child: SwitchListTile(
                        title: const Text('Available for Adoption'),
                        subtitle: Text(
                          _isAvailable
                              ? 'This pet will be visible to adopters'
                              : 'This pet is hidden from adopters',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                        },
                        secondary: CustomIconWidget(
                          iconName: _isAvailable ? 'visibility' : 'visibility_off',
                          size: 24,
                          color: _isAvailable
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePet,
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
                            : Text(_isEditing ? 'Update Pet' : 'Add Pet'),
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
    );
  }
}
