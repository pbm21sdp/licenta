import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Notification bell widget with unread count badge
class NotificationBellWidget extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const NotificationBellWidget({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(2.w),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 28,
              color: theme.colorScheme.onSurface,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: unreadCount > 9 ? 1.5.w : 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
