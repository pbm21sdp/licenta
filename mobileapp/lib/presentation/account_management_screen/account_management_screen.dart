import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/adoption_status_tracking_widget.dart';
import './widgets/application_history_card_widget.dart';
import './widgets/preference_editor_modal_widget.dart';
import './widgets/saved_preferences_card_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/user_profile_header_widget.dart';

/// Account Management Screen - Comprehensive user profile and preference management
/// Accessible via bottom tab navigation (Profile tab)
/// Features: Profile display, preference editing, application history, adoption tracking, settings
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool _isLoading = false;

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

  // Saved preferences from onboarding
  Map<String, dynamic> _savedPreferences = {
    "petType": "Dog",
    "gardenAccess": "Yes, Private Garden",
    "hasChildren": true,
    "childrenAgeRange": "6-12 years",
    "existingPets": ["Dog", "Cat"],
    "petCounts": {"Dog": 1, "Cat": 1},
  };

  // Application history data
  final List<Map<String, dynamic>> _applicationHistory = [
    {
      "id": 1,
      "petName": "Luna",
      "petImage":
          "https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d",
      "petImageSemanticLabel":
          "Golden Retriever dog with fluffy golden fur sitting outdoors",
      "applicationDate": DateTime.now().subtract(Duration(days: 3)),
      "status": "Pending",
      "statusColor": Color(0xFFFFE66D),
      "shelterName": "Happy Paws Shelter",
      "shelterContact": "(555) 123-4567",
      "estimatedResponse": "2-3 business days",
      "timeline": [
        {"step": "Application Submitted", "completed": true},
        {"step": "Under Review", "completed": true},
        {"step": "Shelter Contact", "completed": false},
        {"step": "Home Visit", "completed": false},
        {"step": "Approval Decision", "completed": false},
      ],
    },
    {
      "id": 2,
      "petName": "Max",
      "petImage":
          "https://images.unsplash.com/photo-1652032252208-676df67e89f2",
      "petImageSemanticLabel":
          "Black Labrador dog with shiny coat sitting on grass",
      "applicationDate": DateTime.now().subtract(Duration(days: 15)),
      "status": "Approved",
      "statusColor": Color(0xFF4ECDC4),
      "shelterName": "Loving Hearts Animal Rescue",
      "shelterContact": "(555) 987-6543",
      "estimatedResponse": "Approved - Schedule pickup",
      "timeline": [
        {"step": "Application Submitted", "completed": true},
        {"step": "Under Review", "completed": true},
        {"step": "Shelter Contact", "completed": true},
        {"step": "Home Visit", "completed": true},
        {"step": "Approval Decision", "completed": true},
      ],
    },
    {
      "id": 3,
      "petName": "Bella",
      "petImage":
          "https://images.unsplash.com/photo-1706534887625-f37ae2832c30",
      "petImageSemanticLabel":
          "Beagle dog with brown and white coat sitting on grass",
      "applicationDate": DateTime.now().subtract(Duration(days: 30)),
      "status": "Declined",
      "statusColor": Color(0xFFFF8E8E),
      "shelterName": "Furry Friends Foundation",
      "shelterContact": "(555) 456-7890",
      "estimatedResponse": "Not approved - See feedback",
      "timeline": [
        {"step": "Application Submitted", "completed": true},
        {"step": "Under Review", "completed": true},
        {"step": "Shelter Contact", "completed": true},
        {"step": "Home Visit", "completed": false},
        {"step": "Approval Decision", "completed": true},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshData() async {
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
        onSave: (updatedPreferences) {
          setState(() {
            _savedPreferences = updatedPreferences;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Preferences updated successfully'),
              backgroundColor: Color(0xFF4ECDC4),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
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
