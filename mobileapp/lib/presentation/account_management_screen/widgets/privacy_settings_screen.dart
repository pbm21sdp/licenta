// lib/presentation/account_management_screen/widgets/privacy_settings_screen.dart
// Screen for managing profile privacy and visibility settings

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Privacy settings
  bool _showEmail = false;
  bool _showPhone = false;
  bool _showLocation = true;
  bool _showPetsPublicly = true;
  bool _allowMessages = true;
  bool _showActivityStatus = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _showEmail = prefs.getBool('privacy_show_email') ?? false;
        _showPhone = prefs.getBool('privacy_show_phone') ?? false;
        _showLocation = prefs.getBool('privacy_show_location') ?? true;
        _showPetsPublicly = prefs.getBool('privacy_show_pets') ?? true;
        _allowMessages = prefs.getBool('privacy_allow_messages') ?? true;
        _showActivityStatus = prefs.getBool('privacy_show_activity') ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Privacy Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    theme,
                    title: 'Profile Visibility',
                    description: 'Control what others can see on your profile',
                    children: [
                      _buildToggleSetting(
                        theme,
                        icon: Icons.email_outlined,
                        title: 'Show Email Address',
                        subtitle: 'Allow others to see your email',
                        value: _showEmail,
                        onChanged: (value) {
                          setState(() => _showEmail = value);
                          _saveSetting('privacy_show_email', value);
                        },
                      ),
                      _buildToggleSetting(
                        theme,
                        icon: Icons.phone_outlined,
                        title: 'Show Phone Number',
                        subtitle: 'Display your phone on your profile',
                        value: _showPhone,
                        onChanged: (value) {
                          setState(() => _showPhone = value);
                          _saveSetting('privacy_show_phone', value);
                        },
                      ),
                      _buildToggleSetting(
                        theme,
                        icon: Icons.location_on_outlined,
                        title: 'Show Location',
                        subtitle: 'Display your city on your profile',
                        value: _showLocation,
                        onChanged: (value) {
                          setState(() => _showLocation = value);
                          _saveSetting('privacy_show_location', value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildSection(
                    theme,
                    title: 'Pet Listings',
                    description: 'Control visibility of your listed pets',
                    children: [
                      _buildToggleSetting(
                        theme,
                        icon: Icons.pets,
                        title: 'Public Pet Listings',
                        subtitle: 'Allow anyone to see your listed pets',
                        value: _showPetsPublicly,
                        onChanged: (value) {
                          setState(() => _showPetsPublicly = value);
                          _saveSetting('privacy_show_pets', value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildSection(
                    theme,
                    title: 'Communication',
                    description: 'Manage how others can contact you',
                    children: [
                      _buildToggleSetting(
                        theme,
                        icon: Icons.message_outlined,
                        title: 'Allow Messages',
                        subtitle: 'Let other users send you messages',
                        value: _allowMessages,
                        onChanged: (value) {
                          setState(() => _allowMessages = value);
                          _saveSetting('privacy_allow_messages', value);
                        },
                      ),
                      _buildToggleSetting(
                        theme,
                        icon: Icons.circle,
                        title: 'Show Activity Status',
                        subtitle: 'Let others see when you\'re active',
                        value: _showActivityStatus,
                        onChanged: (value) {
                          setState(() => _showActivityStatus = value);
                          _saveSetting('privacy_show_activity', value);
                        },
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'Your pet adoption applications are always private and only visible to you and the pet owner.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
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
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
