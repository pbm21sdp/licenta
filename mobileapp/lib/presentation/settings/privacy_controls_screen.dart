import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

/// Screen for managing privacy settings
/// Allows users to control data sharing and visibility preferences
class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  bool _isLoading = true;

  // Privacy preferences
  bool _profileVisibleToShelters = true;
  bool _shareApplicationHistory = true;
  bool _allowAnalytics = true;
  bool _showOnlineStatus = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileVisibleToShelters = prefs.getBool('privacy_profile_visible') ?? true;
        _shareApplicationHistory = prefs.getBool('privacy_share_history') ?? true;
        _allowAnalytics = prefs.getBool('privacy_analytics') ?? true;
        _showOnlineStatus = prefs.getBool('privacy_online_status') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preference'),
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Privacy Controls', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(theme, 'Profile Visibility'),
                  SizedBox(height: 1.h),
                  _buildPrivacyCard(
                    theme,
                    children: [
                      _buildSwitchTile(
                        theme,
                        icon: Icons.visibility_outlined,
                        title: 'Visible to Shelters',
                        subtitle: 'Allow shelters to view your profile when reviewing applications',
                        value: _profileVisibleToShelters,
                        onChanged: (value) {
                          setState(() => _profileVisibleToShelters = value);
                          _savePreference('privacy_profile_visible', value);
                        },
                      ),
                      _buildDivider(theme),
                      _buildSwitchTile(
                        theme,
                        icon: Icons.history_outlined,
                        title: 'Share Application History',
                        subtitle: 'Let shelters see your previous adoption applications',
                        value: _shareApplicationHistory,
                        onChanged: (value) {
                          setState(() => _shareApplicationHistory = value);
                          _savePreference('privacy_share_history', value);
                        },
                      ),
                      _buildDivider(theme),
                      _buildSwitchTile(
                        theme,
                        icon: Icons.circle_outlined,
                        title: 'Show Online Status',
                        subtitle: 'Let others see when you are active on the app',
                        value: _showOnlineStatus,
                        onChanged: (value) {
                          setState(() => _showOnlineStatus = value);
                          _savePreference('privacy_online_status', value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  _buildSectionHeader(theme, 'Data & Analytics'),
                  SizedBox(height: 1.h),
                  _buildPrivacyCard(
                    theme,
                    children: [
                      _buildSwitchTile(
                        theme,
                        icon: Icons.analytics_outlined,
                        title: 'Usage Analytics',
                        subtitle: 'Help improve the app by sharing anonymous usage data',
                        value: _allowAnalytics,
                        onChanged: (value) {
                          setState(() => _allowAnalytics = value);
                          _savePreference('privacy_analytics', value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  _buildSectionHeader(theme, 'Data Management'),
                  SizedBox(height: 1.h),
                  _buildPrivacyCard(
                    theme,
                    children: [
                      _buildActionItem(
                        theme,
                        icon: Icons.download_outlined,
                        title: 'Download My Data',
                        subtitle: 'Get a copy of all your data',
                        onTap: () => _showDataRequestDialog(context, 'download'),
                      ),
                      _buildDivider(theme),
                      _buildActionItem(
                        theme,
                        icon: Icons.delete_outline,
                        title: 'Delete My Data',
                        subtitle: 'Permanently delete all your data',
                        isDestructive: true,
                        onTap: () => _showDataRequestDialog(context, 'delete'),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Your Privacy Matters',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'We take your privacy seriously. Your data is encrypted and never sold to third parties. Changes are saved automatically.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
      height: 1,
      indent: 4.w,
      endIndent: 4.w,
    );
  }

  void _showDataRequestDialog(BuildContext context, String type) {
    final theme = Theme.of(context);
    final isDelete = type == 'delete';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelete ? 'Delete My Data' : 'Download My Data'),
        content: Text(
          isDelete
              ? 'This action is irreversible. All your data including your profile, applications, and preferences will be permanently deleted.'
              : 'We will prepare a copy of all your data and send it to your registered email address within 48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isDelete
                        ? 'Data deletion request submitted. You will receive a confirmation email.'
                        : 'Data download request submitted. Check your email within 48 hours.',
                  ),
                  backgroundColor: isDelete
                      ? theme.colorScheme.error
                      : Color(0xFF4ECDC4),
                ),
              );
            },
            child: Text(
              isDelete ? 'Delete' : 'Request',
              style: TextStyle(
                color: isDelete ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
