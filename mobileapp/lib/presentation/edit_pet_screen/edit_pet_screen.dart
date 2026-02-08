// lib/presentation/edit_pet_screen/edit_pet_screen.dart
// Ecran pentru editarea unui animal existent

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/pet_model.dart';
import '../../services/user_pets_service.dart';
import '../../services/api_client.dart';

class EditPetScreen extends StatefulWidget {
  const EditPetScreen({super.key});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserPetsService _userPetsService = UserPetsService();

  bool _isLoading = false;
  bool _isDeleting = false;
  PetModel? _pet;

  // Form controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthStatusController = TextEditingController();
  final _storyController = TextEditingController();
  final _cityController = TextEditingController();
  final _feeController = TextEditingController();

  // Selected values
  String _selectedType = 'dog';
  String _selectedAge = 'adult';
  String _selectedGender = 'male';
  String _selectedSize = 'medium';
  String _selectedStatus = 'available';

  final List<String> _petTypes = ['dog', 'cat', 'bird', 'rabbit', 'other'];
  final List<String> _ageCategories = ['puppy', 'young', 'adult', 'senior'];
  final List<String> _genders = ['male', 'female', 'unknown'];
  final List<String> _sizes = ['small', 'medium', 'large'];
  final List<String> _statuses = ['available', 'pending', 'adopted'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is PetModel && _pet == null) {
      _pet = args;
      _populateForm(args);
    }
  }

  void _populateForm(PetModel pet) {
    _nameController.text = pet.name;
    _breedController.text = pet.breed ?? '';
    _descriptionController.text = pet.description ?? '';
    _healthStatusController.text = pet.healthStatus ?? '';
    _storyController.text = pet.story ?? '';
    _cityController.text = pet.locationCity ?? '';
    _feeController.text = pet.fee?.toString() ?? '';

    setState(() {
      _selectedType = pet.type;
      _selectedAge = pet.ageCategory ?? 'adult';
      _selectedGender = pet.gender ?? 'unknown';
      _selectedSize = pet.size ?? 'medium';
      _selectedStatus = pet.adoptionStatus ?? 'available';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _descriptionController.dispose();
    _healthStatusController.dispose();
    _storyController.dispose();
    _cityController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _updatePet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pet == null) return;

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'ageCategory': _selectedAge,
        'gender': _selectedGender,
        'size': _selectedSize,
        'adoptionStatus': _selectedStatus,
      };

      if (_breedController.text.trim().isNotEmpty) {
        updates['breed'] = _breedController.text.trim();
      }
      if (_descriptionController.text.trim().isNotEmpty) {
        updates['description'] = _descriptionController.text.trim();
      }
      if (_healthStatusController.text.trim().isNotEmpty) {
        updates['healthStatus'] = _healthStatusController.text.trim();
      }
      if (_storyController.text.trim().isNotEmpty) {
        updates['story'] = _storyController.text.trim();
      }
      if (_cityController.text.trim().isNotEmpty) {
        updates['locationCity'] = _cityController.text.trim();
      }
      if (_feeController.text.trim().isNotEmpty) {
        updates['fee'] = double.tryParse(_feeController.text.trim()) ?? 0;
      }

      await _userPetsService.updatePet(_pet!.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pet updated successfully!'),
            backgroundColor: Color(0xFF22C55E),
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

  Future<void> _deletePet() async {
    if (_pet == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
          'Are you sure you want to remove ${_pet!.name} from your listings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _userPetsService.deletePet(_pet!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pet!.name} has been removed from your listings.'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        Navigator.pop(context, 'deleted');
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
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Pet')),
        body: const Center(child: Text('No pet data available')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Edit ${_pet!.name}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isDeleting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.error,
                    ),
                  )
                : Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _isDeleting ? null : _deletePet,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _buildSectionTitle(theme, 'Basic Information'),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              _buildChipSelector(
                theme,
                'Pet Type',
                _petTypes,
                _selectedType,
                (value) => setState(() => _selectedType = value),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                ),
              ),

              SizedBox(height: 3.h),
              _buildSectionTitle(theme, 'Characteristics'),
              SizedBox(height: 2.h),
              _buildChipSelector(
                theme,
                'Age',
                _ageCategories,
                _selectedAge,
                (value) => setState(() => _selectedAge = value),
              ),
              SizedBox(height: 2.h),
              _buildChipSelector(
                theme,
                'Gender',
                _genders,
                _selectedGender,
                (value) => setState(() => _selectedGender = value),
              ),
              SizedBox(height: 2.h),
              _buildChipSelector(
                theme,
                'Size',
                _sizes,
                _selectedSize,
                (value) => setState(() => _selectedSize = value),
              ),

              SizedBox(height: 3.h),
              _buildSectionTitle(theme, 'Status'),
              SizedBox(height: 2.h),
              _buildChipSelector(
                theme,
                'Adoption Status',
                _statuses,
                _selectedStatus,
                (value) => setState(() => _selectedStatus = value),
              ),

              SizedBox(height: 3.h),
              _buildSectionTitle(theme, 'Details'),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _healthStatusController,
                decoration: const InputDecoration(
                  labelText: 'Health Status',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _storyController,
                decoration: const InputDecoration(
                  labelText: 'Story',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                ),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Adoption Fee',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChipSelector(
    ThemeData theme,
    String label,
    List<String> options,
    String selected,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(_formatLabel(option)),
              selected: selected == option,
              onSelected: (isSelected) {
                if (isSelected) onSelected(option);
              },
            );
          }).toList(),
        ),
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
