import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Header widget for Favorites screen
/// Contains search bar and sort button
class FavoritesHeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSortPressed;

  const FavoritesHeaderWidget({
    super.key,
    required this.searchController,
    required this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'My Favorites',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),

            // Search and sort row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 5.h,
                    child: Material(
                      color: theme.colorScheme.surface,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search by name or breed',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          isDense: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 4.w, right: 2.w),
                            child: CustomIconWidget(
                              iconName: 'search',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: CustomIconWidget(
                              iconName: 'clear',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),

                // Sort button
                Container(
                  height: 6.h,
                  width: 6.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: CustomIconWidget(
                      iconName: 'sort',
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                    onPressed: onSortPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
