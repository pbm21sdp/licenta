import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/shelter_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Modal widget for resetting user cooldowns
/// Allows shelter staff to browse adopters and reset their skip cooldowns
class ResetCooldownModalWidget extends StatefulWidget {
  final VoidCallback? onSuccess;

  const ResetCooldownModalWidget({
    super.key,
    this.onSuccess,
  });

  @override
  State<ResetCooldownModalWidget> createState() =>
      _ResetCooldownModalWidgetState();
}

class _ResetCooldownModalWidgetState extends State<ResetCooldownModalWidget> {
  final _shelterService = ShelterService.instance;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _adopters = [];
  bool _isLoading = true;
  bool _isResetting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdopters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdopters({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adopters = await _shelterService.getAdopters(searchQuery: searchQuery);
      if (mounted) {
        setState(() {
          _adopters = adopters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _loadAdopters(searchQuery: value.trim().isEmpty ? null : value.trim());
  }

  Future<void> _showResetConfirmation(Map<String, dynamic> adopter) async {
    final theme = Theme.of(context);
    final userName = adopter['full_name'] as String? ?? adopter['email'] as String? ?? 'this user';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Cooldowns'),
        content: Text(
          'Are you sure you want to reset all skip cooldowns for $userName?\n\n'
          'This will allow them to see all previously skipped pets again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resetCooldowns(adopter);
    }
  }

  Future<void> _resetCooldowns(Map<String, dynamic> adopter) async {
    setState(() => _isResetting = true);

    try {
      await _shelterService.resetUserCooldowns(adopter['id'] as String);

      if (mounted) {
        final userName = adopter['full_name'] as String? ?? adopter['email'] as String?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cooldowns reset for $userName'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset cooldowns: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed header section
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 10.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // Title
                Text(
                  'Reset User Cooldowns',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Select a user to reset their skip cooldowns',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2.h),

                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  enabled: !_isResetting,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const CustomIconWidget(
                      iconName: 'search',
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _loadAdopters();
                            },
                            icon: const CustomIconWidget(
                              iconName: 'close',
                              size: 20,
                            ),
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable adopters list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'error_outline',
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Failed to load users',
                              style: theme.textTheme.bodyLarge,
                            ),
                            SizedBox(height: 1.h),
                            TextButton(
                              onPressed: () => _loadAdopters(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _adopters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIconWidget(
                                  iconName: 'people_outline',
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No users found'
                                      : 'No adopters registered',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: _adopters.length,
                            itemBuilder: (context, index) {
                              final adopter = _adopters[index];
                              return _buildAdopterCard(adopter, theme);
                            },
                          ),
          ),

          // Loading overlay indicator
          if (_isResetting)
            Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Resetting cooldowns...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdopterCard(Map<String, dynamic> adopter, ThemeData theme) {
    final fullName = adopter['full_name'] as String?;
    final email = adopter['email'] as String? ?? 'No email';
    final avatarUrl = adopter['avatar_url'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: InkWell(
        onTap: _isResetting ? null : () => _showResetConfirmation(adopter),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? CustomIconWidget(
                        iconName: 'person',
                        size: 24,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              SizedBox(width: 3.w),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName ?? 'Unknown User',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              CustomIconWidget(
                iconName: 'chevron_right',
                size: 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
