import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual pet card widget for favorites grid
/// Supports tap, long-press, and swipe-to-delete interactions
class FavoritePetCardWidget extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRemove;

  const FavoritePetCardWidget({
    super.key,
    required this.pet,
    required this.onTap,
    required this.onLongPress,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = pet["isAvailable"] as bool? ?? true;

    return Dismissible(
      key: Key(pet["id"].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onRemove(); // Changed from onDismissed() to onRemove()
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomIconWidget(
          iconName: 'delete',
          color: theme.colorScheme.onError,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.petDetail,
            arguments: {...pet, 'isFavorite': true},
          );
        },
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                offset: Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet image with availability overlay
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CustomImageWidget(
                        imageUrl: pet["image"] as String,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: pet["semanticLabel"] as String,
                      ),
                    ),

                    // Availability status badge
                    if (!isAvailable)
                      Positioned(
                        top: 2.w,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Adopted',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Favorite indicator
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'favorite',
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pet details
              Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      pet["name"] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),

                    // Age and breed
                    Text(
                      '${pet["age"]} • ${pet["breed"]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),

                    // Gender
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: (pet["gender"] as String) == 'Male'
                              ? 'male'
                              : 'female',
                          color: (pet["gender"] as String) == 'Male'
                              ? Colors.blue
                              : Colors.pink,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          pet["gender"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}