import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/adoption_form_widget.dart';
import './widgets/bio_section_widget.dart';
import './widgets/health_status_widget.dart';
import './widgets/pet_info_header_widget.dart';
import './widgets/pet_stats_grid_widget.dart';
import './widgets/photo_gallery_widget.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Map<String, dynamic>? _petData;
  bool _isFavorite = false;
  bool _isLoading = false;

  // Owner info for peer-to-peer model
  bool get _isCurrentUserOwner => _petData?['isCurrentUserOwner'] ?? false;
  int? get _ownerId => _petData?['ownerId'];
  String? get _ownerName => _petData?['ownerName'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        _petData = args;
        _isFavorite = args['isFavorite'] ?? false;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAdoptionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdoptionFormWidget(
        petId: _petData?['id'] as int? ?? 0,
        petName: _petData?['name'] ?? '',
      ),
    );
  }

  Future<void> _refreshPetData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pet information updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToEditPet() {
    // Import PetModel and create from _petData
    Navigator.pushNamed(
      context,
      '/edit-pet',
      arguments: _petData,
    ).then((result) {
      if (result == true) {
        // Pet was updated, refresh or go back
        Navigator.pop(context, true);
      } else if (result == 'deleted') {
        Navigator.pop(context, 'deleted');
      }
    });
  }

  void _navigateToOwnerProfile() {
    if (_ownerId != null) {
      Navigator.pushNamed(
        context,
        '/public-profile',
        arguments: _ownerId,
      );
    }
  }

  Widget _buildOwnerSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: InkWell(
        onTap: _navigateToOwnerProfile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listed by',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _ownerName ?? 'Unknown',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _navigateToEditPet,
            icon: Icon(Icons.edit),
            label: Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/adoption-requests');
            },
            icon: Icon(Icons.inbox),
            label: Text('Requests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_petData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No pet data available',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final gallery = _petData!['gallery'] as List<dynamic>? ?? [];
    final galleryImages = gallery.isNotEmpty
        ? gallery
        : [
            {
              'url': _petData!['image'],
              'semanticLabel': _petData!['semanticLabel'],
            },
          ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshPetData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PhotoGalleryWidget(images: galleryImages),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: theme.colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2.h),
                        PetInfoHeaderWidget(
                          name: _petData!['name'] as String,
                          gender: _petData!['gender'] as String,
                        ),
                        SizedBox(height: 2.h),
                        PetStatsGridWidget(
                          age: _petData!['age'] as String,
                          breed: _petData!['breed'] as String,
                          gender: _petData!['gender'] as String,
                        ),
                        SizedBox(height: 3.h),
                        BioSectionWidget(bio: _petData!['bio'] as String),
                        SizedBox(height: 3.h),
                        HealthStatusWidget(
                          healthStatus: _petData!['healthStatus'] as String,
                        ),
                        SizedBox(height: 3.h),
                        // Owner info section
                        if (_ownerName != null && !_isCurrentUserOwner)
                          _buildOwnerSection(theme),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 1.h,
                left: 4.w,
                right: 4.w,
                bottom: 1.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.white, size: 24),
                        onPressed: _shareProfile,
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite
                              ? theme.colorScheme.secondary
                              : Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.12),
                    offset: Offset(0, -4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: _isCurrentUserOwner
                    ? _buildOwnerActions(theme)
                    : ElevatedButton(
                        onPressed: _showAdoptionForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 1.8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply to Adopt',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
