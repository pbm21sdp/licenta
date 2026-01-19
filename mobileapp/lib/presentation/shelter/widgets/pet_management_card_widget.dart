import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Card widget for displaying pet in management list
class PetManagementCardWidget extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

  const PetManagementCardWidget({
    super.key,
    required this.pet,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = pet['is_available'] as bool? ?? false;
    final hasActiveApplication = pet['has_active_application'] as bool? ?? false;
    final species = pet['species'] as String? ?? 'other';
    final gender = pet['gender'] as String? ?? 'unknown';

    // Determine display status: adoption in progress takes precedence
    final String statusLabel;
    final Color statusColor;
    final String badgeIcon;
    if (hasActiveApplication) {
      statusLabel = 'Adoption In Progress';
      statusColor = Colors.amber.shade700;
      badgeIcon = 'schedule';
    } else if (isAvailable) {
      statusLabel = 'Available';
      statusColor = theme.colorScheme.tertiary;
      badgeIcon = 'check';
    } else {
      statusLabel = 'Unavailable';
      statusColor = theme.colorScheme.error;
      badgeIcon = 'close';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            // Pet image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: pet['image_url'] != null
                        ? Image.network(
                            pet['image_url'] as String,
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
                // Availability badge
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: badgeIcon,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 3.w),

            // Pet info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] as String? ?? 'Unknown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${pet['breed'] ?? 'Unknown breed'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      _buildInfoChip(
                        theme,
                        _capitalizeFirst(species),
                        species == 'dog'
                            ? Icons.cruelty_free
                            : species == 'cat'
                                ? Icons.pets
                                : Icons.pets,
                      ),
                      SizedBox(width: 2.w),
                      _buildInfoChip(
                        theme,
                        _capitalizeFirst(gender),
                        gender == 'male' ? Icons.male : Icons.female,
                      ),
                      SizedBox(width: 2.w),
                      if (pet['age'] != null)
                        Expanded(
                          child: Text(
                            pet['age'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Action buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const CustomIconWidget(
                          iconName: 'edit',
                          size: 14,
                        ),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          minimumSize: Size.zero,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      OutlinedButton.icon(
                        // Disable button when pet has active application
                        onPressed: hasActiveApplication ? null : onToggleAvailability,
                        icon: CustomIconWidget(
                          iconName: isAvailable ? 'visibility_off' : 'visibility',
                          size: 14,
                          color: hasActiveApplication
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                              : null,
                        ),
                        label: Text(isAvailable ? 'Hide' : 'Show'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          minimumSize: Size.zero,
                          textStyle: theme.textTheme.labelSmall,
                          foregroundColor: hasActiveApplication
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                              : isAvailable
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 0.5.w),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
