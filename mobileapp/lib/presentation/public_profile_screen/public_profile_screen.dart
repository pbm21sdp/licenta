// lib/presentation/public_profile_screen/public_profile_screen.dart
// Ecran pentru profilul public al unui utilizator

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/pet_model.dart';
import '../../data/models/public_profile_model.dart';
import '../../services/public_profile_service.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_image_widget.dart';
import '../../routes/app_routes.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final PublicProfileService _profileService = PublicProfileService();

  bool _isLoading = true;
  String? _errorMessage;
  int? _userId;
  PublicProfileModel? _profile;
  List<PetModel> _pets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is int && _userId == null) {
      _userId = args;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _profileService.getUserProfile(_userId!),
        _profileService.getUserPets(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as PublicProfileModel;
          _pets = (results[1] as UserPetsResponse).pets;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPetDetail(PetModel pet) {
    Navigator.pushNamed(
      context,
      AppRoutes.petDetail,
      arguments: {
        'id': pet.id,
        'name': pet.name,
        'image': pet.imageUrl,
        'breed': pet.breed ?? pet.type,
        'age': pet.ageDisplay,
        'gender': pet.genderDisplay,
        'bio': pet.description ?? 'No description available',
        'healthStatus': pet.healthStatus ?? 'Not specified',
        'gallery': pet.galleryUrls.map((url) => {'url': url}).toList(),
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
          _profile?.name ?? 'User Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        _buildProfileHeader(theme),

                        SizedBox(height: 3.h),

                        // Stats
                        _buildStats(theme),

                        SizedBox(height: 3.h),

                        // Pets section
                        _buildPetsSection(theme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          backgroundImage: _profile?.avatar != null
              ? NetworkImage(_profile!.avatar!)
              : null,
          child: _profile?.avatar == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: theme.colorScheme.primary,
                )
              : null,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _profile?.name ?? 'Unknown',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              if (_profile?.memberSince != null)
                Text(
                  'Member since ${_formatDate(_profile!.memberSince!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    final stats = _profile?.stats;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, 'Total', stats?.totalPets ?? 0),
          _buildStatDivider(theme),
          _buildStatItem(theme, 'Available', stats?.availablePets ?? 0),
          _buildStatDivider(theme),
          _buildStatItem(theme, 'Adopted', stats?.adoptedPets ?? 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      height: 40,
      width: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildPetsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${_profile?.name ?? 'User'}'s Pets",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        if (_pets.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.pets_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                SizedBox(height: 1.h),
                Text(
                  'No pets listed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
            ),
            itemCount: _pets.length,
            itemBuilder: (context, index) {
              return _buildPetCard(theme, _pets[index]);
            },
          ),
      ],
    );
  }

  Widget _buildPetCard(ThemeData theme, PetModel pet) {
    return GestureDetector(
      onTap: () => _navigateToPetDetail(pet),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CustomImageWidget(
                imageUrl: pet.imageUrl,
                width: double.infinity,
                height: 15.h,
                fit: BoxFit.cover,
                semanticLabel: 'Photo of ${pet.name}',
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    pet.breed ?? pet.type,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                    decoration: BoxDecoration(
                      color: pet.isAvailable
                          ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pet.isAvailable ? 'Available' : 'Not Available',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: pet.isAvailable
                            ? const Color(0xFF22C55E)
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
