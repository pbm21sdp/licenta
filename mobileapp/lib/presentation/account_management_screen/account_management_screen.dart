import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/auth_service.dart';
import '../../services/preference_service.dart';
import '../../services/adoption_service.dart';
import '../../services/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/models/adoption_model.dart';
import './widgets/adoption_status_tracking_widget.dart';
import './widgets/application_history_card_widget.dart';
import './widgets/edit_profile_modal_widget.dart';
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
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Services
  final AuthService _authService = AuthService();
  final PreferenceService _preferenceService = PreferenceService();
  final AdoptionService _adoptionService = AdoptionService();

  // User profile data
  UserModel? _user;
  Map<String, dynamic> _userProfile = {
    "name": "Loading...",
    "email": "",
    "memberSince": DateTime.now(),
    "avatar": "",
    "avatarSemanticLabel": "User profile photo",
  };

  // Saved preferences from onboarding
  Map<String, dynamic> _savedPreferences = {
    "petType": "Not set",
    "gardenAccess": "Not set",
    "hasChildren": false,
    "childrenAgeRange": "",
    "existingPets": <String>[],
    "petCounts": <String, int>{},
  };

  // Application history data
  List<Map<String, dynamic>> _applicationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Încarcă datele în paralel
      await Future.wait([
        _loadUserProfile(),
        _loadPreferences(),
        _loadAdoptions(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading account data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load account data. Please try again.';
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _user = user;
          _userProfile = {
            "name": user.name ?? user.email.split('@')[0],
            "email": user.email,
            "memberSince": user.createdAt ?? DateTime.now(),
            "avatar": user.avatarUrl ?? "",
            "avatarSemanticLabel": "Profile photo of ${user.name ?? 'user'}",
          };
        });
      }
    } on ApiException catch (e) {
      print('API Error loading profile: ${e.message}');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _preferenceService.getPreferences();
      print('Preferences loaded: $prefs');
      if (prefs != null && mounted) {
        print('  - preferredPetTypes: ${prefs.preferredPetTypes}');
        print('  - hasGarden: ${prefs.hasGarden}');
        print('  - hasChildren: ${prefs.hasChildren}');

        // Convertește tipul de pet din format API în format UI
        String petTypeDisplay = 'Not set';
        if (prefs.preferredPetTypes != null && prefs.preferredPetTypes!.isNotEmpty) {
          if (prefs.preferredPetTypes!.contains('dog') && prefs.preferredPetTypes!.contains('cat')) {
            petTypeDisplay = 'Both';
          } else if (prefs.preferredPetTypes!.contains('dog')) {
            petTypeDisplay = 'Dog';
          } else if (prefs.preferredPetTypes!.contains('cat')) {
            petTypeDisplay = 'Cat';
          } else {
            petTypeDisplay = prefs.preferredPetTypes!.first;
          }
        }

        // Convertește garden din boolean în text
        String gardenDisplay = 'Not set';
        if (prefs.hasGarden == true) {
          gardenDisplay = 'Yes';
        } else if (prefs.hasGarden == false) {
          gardenDisplay = 'No';
        }

        setState(() {
          _savedPreferences = {
            "petType": petTypeDisplay,
            "gardenAccess": gardenDisplay,
            "hasChildren": prefs.hasChildren ?? false,
            "childrenAgeRange": prefs.childrenAges?.join(', ') ?? '',
            "existingPets": prefs.otherPetTypes ?? <String>[],
            "petCounts": <String, int>{},
            "hasOtherPets": prefs.hasOtherPets ?? false,
          };
        });
        print('Preferences UI state updated: $_savedPreferences');
      } else {
        print('No preferences found or widget not mounted');
      }
    } on ApiException catch (e) {
      print('API Error loading preferences: ${e.message}');
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _loadAdoptions() async {
    try {
      final response = await _adoptionService.getMyAdoptions();
      print('Adoptions loaded: ${response.applications.length} applications');
      for (var app in response.applications) {
        print('  - ${app.petName} (${app.status})');
      }
      if (mounted) {
        setState(() {
          _applicationHistory = response.applications.map((adoption) => _adoptionToMap(adoption)).toList();
        });
      }
    } on ApiException catch (e) {
      print('API Error loading adoptions: ${e.message}');
    } catch (e) {
      print('Error loading adoptions: $e');
    }
  }

  Map<String, dynamic> _adoptionToMap(AdoptionModel adoption) {
    Color statusColor;
    switch (adoption.status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFFFE66D);
        break;
      case 'approved':
        statusColor = const Color(0xFF4ECDC4);
        break;
      case 'rejected':
      case 'declined':
        statusColor = const Color(0xFFFF8E8E);
        break;
      default:
        statusColor = Colors.grey;
    }

    return {
      "id": adoption.id,
      "petName": adoption.petName,
      "petImage": adoption.petPhoto ?? "",
      "petImageSemanticLabel": "Photo of ${adoption.petName}",
      "applicationDate": adoption.createdAt ?? DateTime.now(),
      "status": adoption.statusDisplay,
      "statusColor": statusColor,
      "shelterName": "Pet Shelter",
      "shelterContact": adoption.phone ?? "",
      "estimatedResponse": _getEstimatedResponse(adoption.status),
      "timeline": _buildTimeline(adoption.status),
    };
  }

  String _getEstimatedResponse(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '2-3 business days';
      case 'approved':
        return 'Approved - Schedule pickup';
      case 'rejected':
      case 'declined':
        return 'Not approved - See feedback';
      default:
        return 'Processing';
    }
  }

  List<Map<String, dynamic>> _buildTimeline(String status) {
    final steps = [
      {"step": "Application Submitted", "completed": true},
      {"step": "Under Review", "completed": status != 'pending'},
      {"step": "Shelter Contact", "completed": status == 'approved' || status == 'rejected'},
      {"step": "Home Visit", "completed": status == 'approved'},
      {"step": "Approval Decision", "completed": status == 'approved' || status == 'rejected'},
    ];
    return steps;
  }

  Future<void> _refreshData() async {
    await _loadData();
    if (mounted && !_hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile data updated'),
          duration: const Duration(seconds: 2),
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
          // Actualizează local imediat pentru feedback rapid
          setState(() {
            _savedPreferences = updatedPreferences;
          });

          // Trimite la API
          try {
            final apiPreferences = _mapToApiPreferences(updatedPreferences);
            await _preferenceService.updatePreferences(apiPreferences);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preferences updated successfully'),
                  backgroundColor: Color(0xFF4ECDC4),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } on ApiException catch (e) {
            print('Error saving preferences: ${e.message}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not save preferences: ${e.message}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              // Reîncarcă preferințele din API pentru a resincroniza
              _loadPreferences();
            }
          }
        },
      ),
    );
  }

  // Convertește preferințele din UI în format API
  Map<String, dynamic> _mapToApiPreferences(Map<String, dynamic> uiPrefs) {
    // Convertește petType în lista de tipuri
    List<String> petTypes = [];
    final petType = uiPrefs['petType'] as String?;
    if (petType == 'Dog') {
      petTypes = ['dog'];
    } else if (petType == 'Cat') {
      petTypes = ['cat'];
    } else if (petType == 'Both') {
      petTypes = ['dog', 'cat'];
    }

    // Convertește gardenAccess în boolean
    final gardenAccess = uiPrefs['gardenAccess'] as String?;
    bool? hasGarden;
    if (gardenAccess == 'Open Garden' || gardenAccess == 'Closed Garden') {
      hasGarden = true;
    } else if (gardenAccess == 'No Garden' || gardenAccess == 'No') {
      hasGarden = false;
    }

    return {
      'preferredPetTypes': petTypes,
      'hasGarden': hasGarden,
      'hasChildren': uiPrefs['hasChildren'] ?? false,
      'childrenAges': uiPrefs['childrenAgeRange'] != null
          ? [uiPrefs['childrenAgeRange']]
          : null,
      'hasOtherPets': (uiPrefs['existingPets'] as List?)?.isNotEmpty ?? false,
      'otherPetTypes': uiPrefs['existingPets'],
    };
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModalWidget(
        currentProfile: _userProfile,
        onSave: (name) async {
          try {
            final updatedUser = await _authService.updateProfile(name: name);
            if (updatedUser != null && mounted) {
              setState(() {
                _user = updatedUser;
                _userProfile = {
                  "name": updatedUser.name,
                  "email": updatedUser.email,
                  "memberSince": updatedUser.createdAt ?? DateTime.now(),
                  "avatar": updatedUser.avatarUrl ?? "",
                  "avatarSemanticLabel": "Profile photo of ${updatedUser.name}",
                };
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: Color(0xFF4ECDC4),
                  duration: Duration(seconds: 2),
                ),
              );
              return true;
            }
            return false;
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            return false;
          }
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
                onEditProfile: _showEditProfile,
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
