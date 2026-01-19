import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/shelter_service.dart';
import '../../widgets/custom_icon_widget.dart';
import 'widgets/status_update_modal_widget.dart';

/// Detailed view of a single adoption application
/// Allows staff to view applicant info and update status
class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _shelterService = ShelterService.instance;

  Map<String, dynamic>? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() => _isLoading = true);

    try {
      final application = await _shelterService.getApplicationById(
        widget.applicationId,
      );

      if (mounted) {
        setState(() {
          _application = application;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading application: $e')),
        );
      }
    }
  }

  void _showStatusUpdateModal() {
    if (_application == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatusUpdateModalWidget(
        currentStatus: _application!['application_status'] as String? ??
            'pending',
        onStatusUpdate: (newStatus, notes) async {
          try {
            await _shelterService.updateApplicationStatus(
              widget.applicationId,
              newStatus,
              notes: notes,
            );

            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status updated to ${_formatStatus(newStatus)}',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
              _loadApplication();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating status: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const CustomIconWidget(iconName: 'arrow_back', size: 24),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _application == null
              ? _buildNotFoundState(theme)
              : _buildContent(theme),
    );
  }

  Widget _buildNotFoundState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            size: 64,
            color: theme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Application not found',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final status = _application!['application_status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status, theme);
    final petData = _application!['pets'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadApplication,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: _getStatusIcon(status),
                      size: 24,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                          ),
                        ),
                        Text(
                          _formatStatus(status),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _showStatusUpdateModal,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.w,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Update',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.all(1.5.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: CustomIconWidget(
                              iconName: 'edit',
                              size: 20,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Pet info card
            if (petData != null) ...[
              Text(
                'Pet Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.5.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 20.w,
                          height: 20.w,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: petData['image_url'] != null
                              ? Image.network(
                                  petData['image_url'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: CustomIconWidget(
                                      iconName: 'pets',
                                      size: 32,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: CustomIconWidget(
                                    iconName: 'pets',
                                    size: 32,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              petData['name'] as String? ?? 'Unknown',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${petData['breed'] ?? 'Unknown breed'} ${petData['species'] ?? ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (petData['age_years'] != null) ...[
                              SizedBox(height: 0.5.h),
                              Text(
                                '${petData['age_years']} years old',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 3.h),
            ],

            // Applicant info
            Text(
              'Applicant Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    _buildInfoRow(
                      theme,
                      'Name',
                      _application!['applicant_name'] as String? ?? 'N/A',
                      'person',
                    ),
                    Divider(height: 3.h),
                    _buildInfoRow(
                      theme,
                      'Email',
                      _application!['applicant_email'] as String? ?? 'N/A',
                      'email',
                    ),
                    Divider(height: 3.h),
                    _buildInfoRow(
                      theme,
                      'Phone',
                      _application!['applicant_phone'] as String? ?? 'N/A',
                      'phone',
                    ),
                    Divider(height: 3.h),
                    _buildInfoRow(
                      theme,
                      'Address',
                      _application!['applicant_address'] as String? ?? 'N/A',
                      'location_on',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Living situation
            Text(
              'Living Situation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    _buildInfoRow(
                      theme,
                      'Housing Type',
                      _formatHousingType(
                        _application!['housing_type'] as String?,
                      ),
                      'home',
                    ),
                    Divider(height: 3.h),
                    _buildBooleanRow(
                      theme,
                      'Has Garden',
                      _application!['has_garden'] as bool? ?? false,
                    ),
                    Divider(height: 3.h),
                    _buildBooleanRow(
                      theme,
                      'Has Existing Pets',
                      _application!['has_existing_pets'] as bool? ?? false,
                    ),
                    Divider(height: 3.h),
                    _buildInfoRow(
                      theme,
                      'Experience Level',
                      _formatExperience(
                        _application!['experience_level'] as String?,
                      ),
                      'star',
                    ),
                  ],
                ),
              ),
            ),

            // Additional notes
            if (_application!['additional_notes'] != null &&
                (_application!['additional_notes'] as String).isNotEmpty) ...[
              SizedBox(height: 3.h),
              Text(
                'Additional Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.5.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    _application!['additional_notes'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],

            // Submission date
            SizedBox(height: 3.h),
            Center(
              child: Text(
                'Submitted: ${_formatDate(_application!['submitted_at'] as String?)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    String iconName,
  ) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBooleanRow(ThemeData theme, String label, bool value) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: value ? 'check_circle' : 'cancel',
          size: 20,
          color: value ? theme.colorScheme.tertiary : theme.colorScheme.error,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value ? 'Yes' : 'No',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatHousingType(String? type) {
    if (type == null) return 'N/A';
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatExperience(String? level) {
    if (level == null) return 'N/A';
    return level.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown';
    }
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

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'hourglass_empty';
      case 'under_review':
        return 'search';
      case 'interview':
        return 'event';
      case 'approved':
        return 'check_circle';
      case 'rejected':
        return 'cancel';
      case 'withdrawn':
        return 'undo';
      default:
        return 'help';
    }
  }
}
