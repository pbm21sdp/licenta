import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/shelter_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Settings screen for shelter staff
/// Includes shelter profile management and logout
class ShelterSettingsScreen extends StatefulWidget {
  final String shelterId;

  const ShelterSettingsScreen({
    super.key,
    required this.shelterId,
  });

  @override
  State<ShelterSettingsScreen> createState() => _ShelterSettingsScreenState();
}

class _ShelterSettingsScreenState extends State<ShelterSettingsScreen> {
  final _shelterService = ShelterService.instance;
  final _authService = AuthService.instance;

  Map<String, dynamic>? _shelter;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final shelter = await _shelterService.getShelterProfile(widget.shelterId);
      final userProfile = await _authService.getUserProfile();

      if (mounted) {
        setState(() {
          _shelter = shelter;
          _userProfile = userProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushReplacementNamed(
            '/welcome-screen',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  void _showEditShelterProfileSheet() {
    if (_shelter == null) return;

    final nameController = TextEditingController(
      text: _shelter!['name'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: _shelter!['description'] as String? ?? '',
    );
    final addressController = TextEditingController(
      text: _shelter!['address'] as String? ?? '',
    );
    final phoneController = TextEditingController(
      text: _shelter!['phone'] as String? ?? '',
    );
    final emailController = TextEditingController(
      text: _shelter!['email'] as String? ?? '',
    );
    final websiteController = TextEditingController(
      text: _shelter!['website'] as String? ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 10.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Edit Shelter Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 3.h),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Shelter Name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _shelterService.updateShelterProfile(
                            shelterId: widget.shelterId,
                            name: nameController.text.trim().isEmpty
                                ? null
                                : nameController.text.trim(),
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            address: addressController.text.trim().isEmpty
                                ? null
                                : addressController.text.trim(),
                            phone: phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                            email: emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            website: websiteController.text.trim().isEmpty
                                ? null
                                : websiteController.text.trim(),
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Profile updated'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.tertiary,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff info card
          Card(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 8.w,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: CustomIconWidget(
                      iconName: 'person',
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile?['full_name'] as String? ?? 'Staff Member',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _userProfile?['email'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
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
                            'Shelter Staff',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Shelter profile section
          Text(
            'Shelter Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CustomIconWidget(
                    iconName: 'business',
                    size: 24,
                  ),
                  title: const Text('Shelter Name'),
                  subtitle: Text(_shelter?['name'] as String? ?? 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CustomIconWidget(
                    iconName: 'location_on',
                    size: 24,
                  ),
                  title: const Text('Address'),
                  subtitle: Text(_shelter?['address'] as String? ?? 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CustomIconWidget(
                    iconName: 'phone',
                    size: 24,
                  ),
                  title: const Text('Phone'),
                  subtitle: Text(_shelter?['phone'] as String? ?? 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CustomIconWidget(
                    iconName: 'email',
                    size: 24,
                  ),
                  title: const Text('Email'),
                  subtitle: Text(_shelter?['email'] as String? ?? 'Not set'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CustomIconWidget(
                    iconName: 'edit',
                    size: 24,
                  ),
                  title: const Text('Edit Shelter Profile'),
                  trailing: const CustomIconWidget(
                    iconName: 'chevron_right',
                    size: 24,
                  ),
                  onTap: _showEditShelterProfileSheet,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Account section
          Text(
            'Account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          Card(
            child: ListTile(
              leading: CustomIconWidget(
                iconName: 'logout',
                size: 24,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: _handleLogout,
            ),
          ),
          SizedBox(height: 4.h),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Paws - Shelter Dashboard',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
