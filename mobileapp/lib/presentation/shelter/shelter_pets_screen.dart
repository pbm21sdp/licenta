import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/shelter_service.dart';
import '../../widgets/custom_icon_widget.dart';
import 'widgets/pet_management_card_widget.dart';

/// Screen for managing shelter's pet listings
/// Includes add, edit, and availability toggle functionality
class ShelterPetsScreen extends StatefulWidget {
  final String shelterId;

  const ShelterPetsScreen({
    super.key,
    required this.shelterId,
  });

  @override
  State<ShelterPetsScreen> createState() => _ShelterPetsScreenState();
}

class _ShelterPetsScreenState extends State<ShelterPetsScreen> {
  final _shelterService = ShelterService.instance;

  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    if (widget.shelterId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final pets = await _shelterService.getShelterPets(
        widget.shelterId,
        availableOnly: _showAvailableOnly ? true : null,
      );

      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pets: $e')),
        );
      }
    }
  }

  Future<void> _togglePetAvailability(String petId, bool currentValue) async {
    try {
      await _shelterService.togglePetAvailability(petId, !currentValue);
      _loadPets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentValue ? 'Pet marked as available' : 'Pet marked as unavailable',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error updating availability: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with filter and add button
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              // Filter toggle
              FilterChip(
                label: Text(
                  _showAvailableOnly ? 'Available Only' : 'All Pets',
                ),
                selected: _showAvailableOnly,
                onSelected: (selected) {
                  setState(() {
                    _showAvailableOnly = selected;
                  });
                  _loadPets();
                },
                avatar: CustomIconWidget(
                  iconName: _showAvailableOnly ? 'check_circle' : 'pets',
                  size: 16,
                  color: _showAvailableOnly
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Add pet button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(
                        '/shelter-pet-editor',
                        arguments: {'shelterId': widget.shelterId},
                      )
                      .then((_) => _loadPets());
                },
                icon: const CustomIconWidget(
                  iconName: 'add',
                  size: 18,
                ),
                label: const Text('Add Pet'),
              ),
            ],
          ),
        ),

        // Pets list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pets.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadPets,
                      child: ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _pets.length,
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          return PetManagementCardWidget(
                            pet: pet,
                            onEdit: () {
                              Navigator.of(context)
                                  .pushNamed(
                                    '/shelter-pet-editor',
                                    arguments: {
                                      'shelterId': widget.shelterId,
                                      'petId': pet['id'],
                                    },
                                  )
                                  .then((_) => _loadPets());
                            },
                            onToggleAvailability: () {
                              _togglePetAvailability(
                                pet['id'] as String,
                                pet['is_available'] as bool? ?? false,
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'pets',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            _showAvailableOnly ? 'No available pets' : 'No pets yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add your first pet listing to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(
                    '/shelter-pet-editor',
                    arguments: {'shelterId': widget.shelterId},
                  )
                  .then((_) => _loadPets());
            },
            icon: const CustomIconWidget(iconName: 'add', size: 18),
            label: const Text('Add Pet'),
          ),
        ],
      ),
    );
  }
}
