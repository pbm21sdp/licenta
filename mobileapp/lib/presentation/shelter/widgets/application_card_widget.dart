import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Card widget for displaying application summary in list
class ApplicationCardWidget extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onTap;

  const ApplicationCardWidget({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = application['application_status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status, theme);
    final petData = application['pets'] as Map<String, dynamic>?;

    // Parse submitted date
    String submittedDate = 'Unknown date';
    final submittedAt = application['submitted_at'] as String?;
    if (submittedAt != null) {
      try {
        final date = DateTime.parse(submittedAt);
        submittedDate = '${date.day}/${date.month}/${date.year}';
      } catch (_) {}
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              // Pet image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: petData?['image_url'] != null
                      ? Image.network(
                          petData!['image_url'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: CustomIconWidget(
                              iconName: 'pets',
                              size: 24,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Center(
                          child: CustomIconWidget(
                            iconName: 'pets',
                            size: 24,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              SizedBox(width: 3.w),

              // Application info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['applicant_name'] as String? ?? 'Unknown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'For: ${petData?['name'] ?? application['pet_name'] ?? 'Unknown Pet'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calendar_today',
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          submittedDate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
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
}
