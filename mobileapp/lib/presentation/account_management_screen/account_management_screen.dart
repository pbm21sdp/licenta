import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/adoption_service.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/preference_service.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/adoption_status_tracking_widget.dart';
import './widgets/application_history_card_widget.dart';
import './widgets/notification_bell_widget.dart';
import './widgets/notification_list_widget.dart';
import './widgets/preference_editor_modal_widget.dart';
import './widgets/saved_preferences_card_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/user_profile_header_widget.dart';

/// Account Management Screen - Comprehensive user profile and preference management
/// Accessible via bottom tab navigation (Profile tab)
/// Features: Profile display, preference editing, application history, adoption tracking, settings, real-time notifications
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  final AdoptionService _adoptionService = AdoptionService();
  final AuthService _authService = AuthService.instance;
  final PetService _petService = PetService();
  final PreferenceService _preferenceService = PreferenceService();
  RealtimeChannel? _notificationChannel;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _applicationHistory = [];

  // User profile data
  final Map<String, dynamic> _userProfile = {
    "name": "Sarah Johnson",
    "email": "user@petadoption.com",
    "memberSince": DateTime(2024, 1, 15),
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1bb0109eb-1763295676769.png",
    "avatarSemanticLabel":
        "Profile photo of woman with brown hair smiling at camera",
  };

  // Saved preferences - will be loaded from database
  Map<String, dynamic> _savedPreferences = {
    "petType": null,
    "gardenAccess": null,
    "hasChildren": false,
    "childrenAgeRange": null,
    "existingPets": <String>[],
    "petCounts": <String, int>{},
  };

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _loadAdoptionHistory();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    try {
      final prefs = await _preferenceService.getUserPreferences(userId);
      if (mounted && prefs != null) {
        setState(() {
          _savedPreferences = {
            'petType': prefs['petType'],
            'gardenAccess': prefs['gardenAccess'],
            'hasChildren': prefs['hasChildren'] ?? false,
            'childrenAgeRange': prefs['childrenAgeRange'],
            'existingPets': prefs['existingPets'] ?? [],
            'petCounts': prefs['petCounts'] ?? {},
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    }
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      _notificationService.unsubscribe(_notificationChannel!);
    }
    super.dispose();
  }

  Future<void> _setupNotifications() async {
    try {
      // Fetch initial notifications
      await _loadNotifications();

      // Subscribe to real-time updates
      _notificationChannel = _notificationService.subscribeToNotifications(
        userEmail: _userProfile['email'] as String,
        onNotification: (notification) {
          setState(() {
            _notifications.insert(0, notification);
            _unreadCount++;
          });

          // Show snackbar for new notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        notification['title'] as String,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.white,
                  onPressed: () => _showNotifications(),
                ),
              ),
            );
          }
        },
      );
    } catch (error) {
      debugPrint('Error setting up notifications: $error');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications(
        _userProfile['email'] as String,
      );
      final unreadCount = await _notificationService.getUnreadCount(
        _userProfile['email'] as String,
      );

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
      });
    } catch (error) {
      debugPrint('Error loading notifications: $error');
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationListWidget(
        notifications: _notifications,
        onMarkAsRead: (notificationId) async {
          try {
            await _notificationService.markAsRead(notificationId);
            await _loadNotifications();
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to mark as read: $error'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        onMarkAllAsRead: () async {
          try {
            await _notificationService.markAllAsRead(
              _userProfile['email'] as String,
            );
            await _loadNotifications();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications marked as read'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to mark all as read: $error'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _loadAdoptionHistory() async {
    setState(() => _isLoading = true);

    try {
      final applications = await _adoptionService.getUserAdoptionHistory();

      // Transform database data to UI format
      final List<Map<String, dynamic>> formattedHistory = [];

      for (final app in applications) {
        // Fetch pet details if we have pet_id
        Map<String, dynamic>? petDetails;
        if (app['pet_id'] != null) {
          try {
            // Use getAvailablePets to fetch pet details
            final pets = await _petService.getAvailablePets();
            petDetails = pets.firstWhere(
              (pet) => pet['id'] == app['pet_id'],
              orElse: () => {},
            );
            if (petDetails.isEmpty ?? true) petDetails = null;
          } catch (e) {
            debugPrint('Failed to fetch pet details: $e');
          }
        }

        final status = _formatStatus(app['application_status'] as String);

        formattedHistory.add({
          "id": app['id'],
          "petName": app['pet_name'],
          "petImage":
              petDetails?['image_url'] ??
              "https://images.unsplash.com/photo-1507270603269-db9a0c1c1cea",
          "petImageSemanticLabel":
              petDetails?['image_semantic_label'] ?? "Pet image",
          "applicationDate": DateTime.parse(app['submitted_at'] as String),
          "status": status['label'],
          "statusColor": status['color'],
          "shelterName": "Pet Shelter",
          "shelterContact": app['applicant_phone'] ?? "Contact shelter",
          "estimatedResponse": _getEstimatedResponse(
            app['application_status'] as String,
          ),
          "timeline": _buildTimeline(app['application_status'] as String),
        });
      }

      setState(() {
        _applicationHistory = formattedHistory;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading adoption history: $error');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'Pending', 'color': Color(0xFFFFE66D)};
      case 'under_review':
        return {'label': 'Under Review', 'color': Color(0xFF64B5F6)};
      case 'interview':
        return {'label': 'Interview', 'color': Color(0xFF9C27B0)};
      case 'approved':
        return {'label': 'Approved', 'color': Color(0xFF4ECDC4)};
      case 'rejected':
        return {'label': 'Rejected', 'color': Color(0xFFFF8E8E)};
      case 'withdrawn':
        return {'label': 'Withdrawn', 'color': Color(0xFF9E9E9E)};
      default:
        return {'label': status, 'color': Color(0xFF9E9E9E)};
    }
  }

  String _getEstimatedResponse(String status) {
    switch (status) {
      case 'pending':
        return '2-3 business days';
      case 'under_review':
        return 'Under review by shelter';
      case 'interview':
        return 'Interview scheduled - shelter will contact you';
      case 'approved':
        return 'Approved - Contact shelter to schedule pickup';
      case 'rejected':
        return 'Application not approved';
      case 'withdrawn':
        return 'Application withdrawn';
      default:
        return 'Contact shelter for details';
    }
  }

  List<Map<String, dynamic>> _buildTimeline(String status) {
    // Special case for withdrawn applications
    if (status == 'withdrawn') {
      return [
        {"step": "Application Submitted", "completed": true},
        {"step": "Withdrawn", "completed": true},
      ];
    }

    // Normal flow: Application Submitted -> Under Review -> Interview -> Approved/Rejected
    return [
      {"step": "Application Submitted", "completed": true},
      {"step": "Under Review", "completed": status != 'pending'},
      {
        "step": "Interview",
        "completed":
            status == 'interview' ||
            status == 'approved' ||
            status == 'rejected',
      },
      {
        "step": status == 'approved'
            ? 'Approved'
            : (status == 'rejected' ? 'Rejected' : 'Decision'),
        "completed": status == 'approved' || status == 'rejected',
      },
    ];
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([_loadNotifications(), _loadAdoptionHistory()]);
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile data updated'),
          duration: Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _showPreferenceEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PreferenceEditorModalWidget(
        currentPreferences: _savedPreferences,
        onSave: (updatedPreferences) async {
          setState(() {
            _savedPreferences = updatedPreferences;
          });

          // Save to database
          final userId = _authService.currentUser?.id;
          if (userId != null) {
            try {
              await _preferenceService.saveUserPreferences(
                userId,
                updatedPreferences,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preferences saved successfully'),
                    backgroundColor: Color(0xFF4ECDC4),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              debugPrint('Failed to save preferences: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save preferences'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preferences updated locally'),
                  backgroundColor: Color(0xFF4ECDC4),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _clearPreferences() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Preferences'),
        content: Text(
          'Are you sure you want to clear all your saved preferences? This will remove your pet type, garden, children, and existing pets settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = _authService.currentUser?.id;
    if (userId != null) {
      try {
        await _preferenceService.clearUserPreferences(userId);
        setState(() {
          _savedPreferences = {
            'petType': null,
            'gardenAccess': null,
            'hasChildren': false,
            'childrenAgeRange': null,
            'existingPets': <String>[],
            'petCounts': <String, int>{},
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Preferences cleared successfully'),
              backgroundColor: Color(0xFF4ECDC4),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to clear preferences: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear preferences'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _showApplicationDetail(Map<String, dynamic> application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildApplicationDetailModal(application),
    );
  }

  Widget _buildApplicationDetailModal(Map<String, dynamic> application) {
    final theme = Theme.of(context);
    return Container(
      height: 75.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Application Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: 2.w),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomImageWidget(
                          imageUrl: application['petImage'] as String,
                          width: 20.w,
                          height: 20.w,
                          fit: BoxFit.cover,
                          semanticLabel:
                              application['petImageSemanticLabel'] as String,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application['petName'] as String,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: application['statusColor'] as Color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                application['status'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Application Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ...(application['timeline'] as List<Map<String, dynamic>>)
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final isCompleted = step['completed'] as bool;
                        final isLast =
                            index ==
                            (application['timeline'] as List).length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface,
                                    border: Border.all(
                                      color: isCompleted
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline,
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isCompleted
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: theme.colorScheme.onPrimary,
                                        )
                                      : null,
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 4.h,
                                    color: isCompleted
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 2.h,
                                ),
                                child: Text(
                                  step['step'] as String,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isCompleted
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isCompleted
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                  SizedBox(height: 3.h),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shelter Contact',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              application['shelterName'] as String,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              application['shelterContact'] as String,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: (application['statusColor'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: application['statusColor'] as Color,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            application['estimatedResponse'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
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
        ],
      ),
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
          'My Account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          NotificationBellWidget(
            unreadCount: _unreadCount,
            onTap: _showNotifications,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 2.h),
              UserProfileHeaderWidget(
                userProfile: _userProfile,
                onEditProfile: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Edit profile coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              SizedBox(height: 2.h),
              SavedPreferencesCardWidget(
                preferences: _savedPreferences,
                onEditPreferences: _showPreferenceEditor,
                onClearPreferences: _clearPreferences,
              ),
              SizedBox(height: 2.h),
              AdoptionStatusTrackingWidget(
                applications: _applicationHistory
                    .where((app) => app['status'] == 'Pending')
                    .toList(),
              ),
              SizedBox(height: 2.h),
              ApplicationHistoryCardWidget(
                applications: _applicationHistory,
                onApplicationTap: _showApplicationDetail,
              ),
              SizedBox(height: 2.h),
              SettingsSectionWidget(),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
