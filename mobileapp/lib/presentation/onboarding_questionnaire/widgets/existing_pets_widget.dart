import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Existing Pets Selection Widget
/// Displays multi-select options for existing pets with count selectors
class ExistingPetsWidget extends StatelessWidget {
  final List<String> selectedPets;
  final Map<String, int> petCounts;
  final ValueChanged<String> onPetToggled;
  final Function(String, int) onCountChanged;

  const ExistingPetsWidget({
    super.key,
    required this.selectedPets,
    required this.petCounts,
    required this.onPetToggled,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final petTypes = [
      {'type': 'Cat', 'icon': 'pets'},
      {'type': 'Dog', 'icon': 'pets'},
      {'type': 'Bird', 'icon': 'flutter_dash'},
      {'type': 'Fish', 'icon': 'water'},
      {'type': 'Rabbit', 'icon': 'cruelty_free'},
      {'type': 'Other', 'icon': 'more_horiz'},
    ];

    return Column(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Select all pets you currently have',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        ...petTypes.map((pet) {
          final petType = pet['type'] as String;
          final iconName = pet['icon'] as String;
          final isSelected = selectedPets.contains(petType);
          final count = petCounts[petType] ?? 1;

          return Column(
            children: [
              _buildPetOption(
                context,
                theme,
                petType,
                iconName,
                isSelected,
                count,
              ),
              SizedBox(height: 1.5.h),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildPetOption(
    BuildContext context,
    ThemeData theme,
    String petType,
    String iconName,
    bool isSelected,
    int count,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  petType,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => onPetToggled(petType),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),

          if (isSelected) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'How many?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: count > 1
                            ? () => onCountChanged(petType, count - 1)
                            : null,
                        icon: CustomIconWidget(
                          iconName: 'remove_circle_outline',
                          color: count > 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                          size: 24,
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 10.w),
                        alignment: Alignment.center,
                        child: Text(
                          count.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: count < 10
                            ? () => onCountChanged(petType, count + 1)
                            : null,
                        icon: CustomIconWidget(
                          iconName: 'add_circle_outline',
                          color: count < 10
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
