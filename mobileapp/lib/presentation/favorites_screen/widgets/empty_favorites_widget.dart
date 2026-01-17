import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget for when user has no favorites
/// Displays encouraging message and CTA to start swiping
class EmptyFavoritesWidget extends StatelessWidget {
  final VoidCallback onStartSwipingPressed;

  const EmptyFavoritesWidget({super.key, required this.onStartSwipingPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'favorite_border',
                  color: theme.colorScheme.primary,
                  size: 80,
                ),
              ),
            ),
            SizedBox(height: 4.h),

            // Title
            Text(
              'No Favorites Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),

            // Description
            Text(
              'Start swiping to build your favorites collection and find your perfect pet companion!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // CTA Button
            ElevatedButton(
              onPressed: onStartSwipingPressed,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Start Swiping'),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: 'arrow_forward',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
