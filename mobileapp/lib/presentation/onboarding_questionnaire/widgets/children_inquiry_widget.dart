import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Children Presence Inquiry Widget
/// Displays toggle for children presence and age range selector
class ChildrenInquiryWidget extends StatelessWidget {
  final bool hasChildren;
  final String? selectedAgeRange;
  final ValueChanged<bool> onToggleChanged;
  final ValueChanged<String> onAgeRangeSelected;

  const ChildrenInquiryWidget({
    super.key,
    required this.hasChildren,
    required this.selectedAgeRange,
    required this.onToggleChanged,
    required this.onAgeRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: hasChildren
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'child_care',
                  color: hasChildren
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  'I have children',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: hasChildren,
                onChanged: onToggleChanged,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),

        if (hasChildren) ...[
          SizedBox(height: 3.h),
          Text(
            'Children\'s age range',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildAgeRangeOption(context, theme, '0-3 years', 'Toddlers'),
          SizedBox(height: 1.5.h),
          _buildAgeRangeOption(context, theme, '4-8 years', 'Young children'),
          SizedBox(height: 1.5.h),
          _buildAgeRangeOption(context, theme, '9-12 years', 'Pre-teens'),
          SizedBox(height: 1.5.h),
          _buildAgeRangeOption(context, theme, '13+ years', 'Teenagers'),
        ],
      ],
    );
  }

  Widget _buildAgeRangeOption(
    BuildContext context,
    ThemeData theme,
    String ageRange,
    String description,
  ) {
    final isSelected = selectedAgeRange == ageRange;

    return GestureDetector(
      onTap: () => onAgeRangeSelected(ageRange),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ageRange,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
