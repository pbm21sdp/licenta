import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/shelter_service.dart';
import '../../widgets/custom_icon_widget.dart';
import 'shelter_applications_screen.dart';
import 'shelter_pets_screen.dart';
import 'shelter_settings_screen.dart';
import 'widgets/dashboard_stats_widget.dart';

/// Main dashboard screen for shelter staff
/// Provides navigation shell with bottom bar and overview statistics
class ShelterDashboardScreen extends StatefulWidget {
  const ShelterDashboardScreen({super.key});

  @override
  State<ShelterDashboardScreen> createState() => _ShelterDashboardScreenState();
}

class _ShelterDashboardScreenState extends State<ShelterDashboardScreen> {
  final _authService = AuthService.instance;
  final _shelterService = ShelterService.instance;

  int _currentIndex = 0;
  String? _shelterId;
  String? _shelterName;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final shelterId = await _authService.getStaffShelterId();
      if (shelterId == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login-screen');
        }
        return;
      }

      final shelter = await _shelterService.getShelterProfile(shelterId);
      final stats = await _shelterService.getDashboardStats(shelterId);
      final recentApps = await _shelterService.getRecentApplications(shelterId);

      if (mounted) {
        setState(() {
          _shelterId = shelterId;
          _shelterName = shelter?['name'] as String? ?? 'Shelter';
          _stats = stats;
          _recentApplications = recentApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildDashboardHome() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome back!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              _shelterName ?? 'Shelter Dashboard',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),

            // Stats cards
            DashboardStatsWidget(stats: _stats),
            SizedBox(height: 3.h),

            // Recent applications section
            Text(
              'Recent Applications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            if (_recentApplications.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'inbox',
                        size: 24,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'No recent applications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_recentApplications.map((app) => _buildRecentApplicationCard(
                    app,
                    theme,
                  ))),

            SizedBox(height: 2.h),

            // Quick actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.w),

            IntrinsicHeight(
              child: Row(
                children: [
                  SizedBox(
                    width: 44.w,
                    child: _buildQuickActionCard(
                      theme,
                      'Add New Pet \nto Shelter',
                      'pets',
                      theme.colorScheme.primary,
                          () {
                        Navigator.of(context).pushNamed('/shelter-pet-editor');
                      },
                    ),
                  ),
                  SizedBox(width: 2.w),
                  SizedBox(
                    width: 44.w,
                    child: _buildQuickActionCard(
                      theme,
                      'View All Applications',
                      'assignment',
                      theme.colorScheme.secondary,
                          () {
                        setState(() => _currentIndex = 1);
                      },
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

  Widget _buildRecentApplicationCard(
    Map<String, dynamic> app,
    ThemeData theme,
  ) {
    final status = app['application_status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status, theme);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/shelter-application-detail',
            arguments: {'applicationId': app['id']},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['applicant_name'] as String? ?? 'Unknown',
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Applied for ${app['pet_name'] ?? 'Unknown Pet'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatus(status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    ThemeData theme,
    String title,
    String iconName,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  size: 24,
                  color: color,
                ),
              ),
              SizedBox(height: 1.5.h),
              Text(
                title,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'interview':
        return Colors.purple;
      case 'approved':
        return theme.colorScheme.tertiary;
      case 'rejected':
        return theme.colorScheme.error;
      case 'withdrawn':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build the current screen based on index
    Widget currentScreen;
    String currentTitle;

    switch (_currentIndex) {
      case 0:
        currentScreen = _buildDashboardHome();
        currentTitle = 'Dashboard';
        break;
      case 1:
        currentScreen = ShelterApplicationsScreen(shelterId: _shelterId ?? '');
        currentTitle = 'Applications';
        break;
      case 2:
        currentScreen = ShelterPetsScreen(shelterId: _shelterId ?? '');
        currentTitle = 'Pets';
        break;
      case 3:
        currentScreen = ShelterSettingsScreen(shelterId: _shelterId ?? '');
        currentTitle = 'Settings';
        break;
      default:
        currentScreen = _buildDashboardHome();
        currentTitle = 'Dashboard';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: _loadDashboardData,
              icon: const CustomIconWidget(
                iconName: 'refresh',
                size: 24,
              ),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'dashboard', size: 24),
            activeIcon: CustomIconWidget(iconName: 'dashboard', size: 24),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'assignment', size: 24),
            activeIcon: CustomIconWidget(iconName: 'assignment', size: 24),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'pets', size: 24),
            activeIcon: CustomIconWidget(iconName: 'pets', size: 24),
            label: 'Pets',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(iconName: 'settings', size: 24),
            activeIcon: CustomIconWidget(iconName: 'settings', size: 24),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
