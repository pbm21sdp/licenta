import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class HealthStatusWidget extends StatelessWidget {
  final String healthStatus;

  const HealthStatusWidget({super.key, required this.healthStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusItems = healthStatus.split(',').map((e) => e.trim()).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Status',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: statusItems.map((status) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            status,
                            theme,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: _getStatusIcon(status),
                          color: _getStatusColor(status, theme),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          status,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            status,
                            theme,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'Up-to-date',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(status, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('vaccinated')) {
      return Color(0xFF22C55E);
    } else if (lowerStatus.contains('spayed') ||
        lowerStatus.contains('neutered')) {
      return theme.colorScheme.primary;
    } else if (lowerStatus.contains('microchipped')) {
      return Color(0xFF22C55E);
    } else if (lowerStatus.contains('dewormed')) {
      return Color(0xFF22C55E);
    }
    return theme.colorScheme.primary;
  }

  String _getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('vaccinated')) {
      return 'check_circle';
    } else if (lowerStatus.contains('spayed') ||
        lowerStatus.contains('neutered')) {
      return 'verified';
    } else if (lowerStatus.contains('microchipped')) {
      return 'verified_user';
    } else if (lowerStatus.contains('dewormed')) {
      return 'check_circle';
    }
    return 'check_circle';
  }
}
