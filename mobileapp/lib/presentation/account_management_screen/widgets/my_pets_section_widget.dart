// lib/presentation/account_management_screen/widgets/my_pets_section_widget.dart
// Widget pentru afișarea animalelor proprii în profilul utilizatorului

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../data/models/pet_model.dart';
import '../../../services/user_pets_service.dart';
import '../../../services/api_client.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../routes/app_routes.dart';

class MyPetsSectionWidget extends StatefulWidget {
  final VoidCallback? onRefreshRequested;

  const MyPetsSectionWidget({
    super.key,
    this.onRefreshRequested,
  });

  @override
  State<MyPetsSectionWidget> createState() => _MyPetsSectionWidgetState();
}

class _MyPetsSectionWidgetState extends State<MyPetsSectionWidget> {
  final UserPetsService _userPetsService = UserPetsService();

  bool _isLoading = true;
  List<PetModel> _pets = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userPetsService.getMyPets(limit: 5);
      if (mounted) {
        setState(() {
          _pets = response.pets;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          // Handle specific error codes gracefully
          if (e.statusCode == 403) {
            // User not verified - treat as empty list with a message
            _pets = [];
            _errorMessage = null;
          } else {
            _errorMessage = e.message;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load pets. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddPet() async {
    final result = await Navigator.pushNamed(context, AppRoutes.addPet);
    if (result == true) {
      _loadPets();
      widget.onRefreshRequested?.call();
    }
  }

  void _navigateToEditPet(PetModel pet) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editPet,
      arguments: pet,
    );
    if (result != null) {
      _loadPets();
      widget.onRefreshRequested?.call();
    }
  }

  void _navigateToAdoptionRequests() {
    Navigator.pushNamed(context, AppRoutes.adoptionRequests);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pets,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'My Listed Pets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _navigateToAddPet,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextButton(
                      onPressed: _loadPets,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_pets.isEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'You haven\'t listed any pets yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Share your pet with the community and help them find a loving home',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddPet,
                      icon: const Icon(Icons.add),
                      label: const Text('List Your First Pet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Pet list
                ...(_pets.take(3).map((pet) => _buildPetTile(theme, pet))),

                // View all link
                if (_pets.length > 3)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full pets list
                    },
                    child: Text('View all ${_pets.length} pets'),
                  ),

                // Adoption requests button
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _navigateToAdoptionRequests,
                      icon: const Icon(Icons.inbox),
                      label: const Text('View Adoption Requests'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPetTile(ThemeData theme, PetModel pet) {
    final statusColor = _getStatusColor(pet.adoptionStatus);

    return InkWell(
      onTap: () => _navigateToEditPet(pet),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Pet image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImageWidget(
                imageUrl: pet.imageUrl,
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
                semanticLabel: 'Photo of ${pet.name}',
              ),
            ),
            SizedBox(width: 3.w),

            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${pet.breed ?? pet.type} - ${pet.ageDisplay}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatStatus(pet.adoptionStatus),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (pet.pendingApplications != null && pet.pendingApplications! > 0) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${pet.pendingApplications} pending',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Edit icon
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFFFE66D);
      case 'adopted':
        return const Color(0xFF95E1D3);
      case 'in_review':
        return const Color(0xFFFFAB91);
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
