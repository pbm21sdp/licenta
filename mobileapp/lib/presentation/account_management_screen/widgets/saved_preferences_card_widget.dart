import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class SavedPreferencesCardWidget extends StatelessWidget {
  final Map<String, dynamic> preferences;
  final VoidCallback onEditPreferences;
  final VoidCallback? onClearPreferences;

  const SavedPreferencesCardWidget({
    super.key,
    required this.preferences,
    required this.onEditPreferences,
    this.onClearPreferences,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingPets = preferences['existingPets'] as List<String>? ?? [];
    final petCounts = preferences['petCounts'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saved Preferences',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClearPreferences != null)
                TextButton.icon(
                  onPressed: onClearPreferences,
                  icon: Icon(Icons.clear_all, size: 16),
                  label: Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              TextButton.icon(
                onPressed: onEditPreferences,
                icon: Icon(Icons.edit_outlined, size: 16),
                label: Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildPreferenceItem(
            context,
            icon: Icons.pets,
            label: 'Pet Type',
            value: preferences['petType'] as String? ?? 'Not specified',
          ),
          SizedBox(height: 1.5.h),
          _buildPreferenceItem(
            context,
            icon: Icons.yard_outlined,
            label: 'Garden Access',
            value: preferences['gardenAccess'] as String? ?? 'Not specified',
          ),
          SizedBox(height: 1.5.h),
          _buildPreferenceItem(
            context,
            icon: Icons.child_care_outlined,
            label: 'Children',
            value: preferences['hasChildren'] == true
                ? 'Yes (${preferences['childrenAgeRange'] ?? 'Age not specified'})'
                : 'No',
          ),
          SizedBox(height: 1.5.h),
          _buildPreferenceItem(
            context,
            icon: Icons.home_outlined,
            label: 'Existing Pets',
            value: existingPets.isEmpty
                ? 'None'
                : existingPets
                      .map((pet) => '$pet (${petCounts[pet] ?? 1})')
                      .join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
