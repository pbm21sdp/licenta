import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/fcm_service.dart';

/// Screen for managing notification preferences
/// Allows users to toggle different types of notifications
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;

  // Notification preferences
  bool _applicationUpdates = true;
  bool _newPetAlerts = true;
  bool _promotions = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load push notification preference from database
      final userId = Supabase.instance.client.auth.currentUser?.id;
      bool pushEnabled = true;
      if (userId != null) {
        pushEnabled = await FCMService.instance.getPushEnabled(userId);
      }

      setState(() {
        _applicationUpdates = prefs.getBool('notif_application_updates') ?? true;
        _newPetAlerts = prefs.getBool('notif_new_pet_alerts') ?? true;
        _promotions = prefs.getBool('notif_promotions') ?? false;
        _emailNotifications = prefs.getBool('notif_email') ?? true;
        _pushNotifications = pushEnabled;
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
        title: Text(
          'Notification Preferences',
          style: theme.appBarTheme.titleTextStyle,
        ),
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
                  _buildSectionHeader(theme, 'Notification Types'),
                  SizedBox(height: 1.h),
                  _buildNotificationCard(
                    theme,
                    children: [
                      _buildSwitchTile(
                        theme,
                        icon: Icons.assignment_outlined,
                        title: 'Application Updates',
                        subtitle: 'Get notified about your adoption application status',
                        value: _applicationUpdates,
                        onChanged: (value) {
                          setState(() => _applicationUpdates = value);
                          _savePreference('notif_application_updates', value);
                        },
                      ),
                      _buildDivider(theme),
                      _buildSwitchTile(
                        theme,
                        icon: Icons.pets_outlined,
                        title: 'New Pet Alerts',
                        subtitle: 'Get notified when new pets match your preferences',
                        value: _newPetAlerts,
                        onChanged: (value) {
                          setState(() => _newPetAlerts = value);
                          _savePreference('notif_new_pet_alerts', value);
                        },
                      ),
                      _buildDivider(theme),
                      _buildSwitchTile(
                        theme,
                        icon: Icons.local_offer_outlined,
                        title: 'Promotions & Tips',
                        subtitle: 'Receive pet care tips and special offers',
                        value: _promotions,
                        onChanged: (value) {
                          setState(() => _promotions = value);
                          _savePreference('notif_promotions', value);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  _buildSectionHeader(theme, 'Delivery Methods'),
                  SizedBox(height: 1.h),
                  _buildNotificationCard(
                    theme,
                    children: [
                      _buildSwitchTile(
                        theme,
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        subtitle: 'Receive updates via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                          _savePreference('notif_email', value);
                        },
                      ),
                      _buildDivider(theme),
                      _buildSwitchTile(
                        theme,
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications on your device',
                        value: _pushNotifications,
                        onChanged: (value) async {
                          setState(() => _pushNotifications = value);
                          // Sync with FCM service and database
                          final userId = Supabase.instance.client.auth.currentUser?.id;
                          if (userId != null) {
                            try {
                              await FCMService.instance.setPushEnabled(userId, value);
                            } catch (e) {
                              // Revert on error
                              setState(() => _pushNotifications = !value);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update push notification setting'),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
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
                          size: 24,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'Changes are saved automatically.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, {required List<Widget> children}) {
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

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
      height: 1,
      indent: 4.w,
      endIndent: 4.w,
    );
  }
}
