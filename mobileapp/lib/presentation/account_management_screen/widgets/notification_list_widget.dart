import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Widget displaying list of notifications in a bottom sheet
class NotificationListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  const NotificationListWidget({
    super.key,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (notifications.any((n) => n['is_read'] == false))
                  TextButton(
                    onPressed: onMarkAllAsRead,
                    child: Text(
                      'Mark all as read',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Notification list
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 80,
                          color: theme.colorScheme.outline,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No notifications yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['is_read'] as bool;
                      final createdAt = DateTime.parse(
                        notification['created_at'] as String,
                      );
                      final timeAgo = _formatTimeAgo(createdAt);

                      return InkWell(
                        onTap: () {
                          if (!isRead) {
                            onMarkAsRead(notification['id'] as String);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          color: isRead
                              ? Colors.transparent
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(
                                    notification['new_status'] as String,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(
                                  _getNotificationIcon(
                                    notification['new_status'] as String,
                                  ),
                                  color: _getNotificationColor(
                                    notification['new_status'] as String,
                                  ),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification['title'] as String,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      notification['message'] as String,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      timeAgo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String status) {
    switch (status) {
      case 'approved':
        return Color(0xFF4ECDC4);
      case 'rejected':
        return Color(0xFFFF8E8E);
      case 'under_review':
        return Color(0xFFFFE66D);
      default:
        return Color(0xFF9E9E9E);
    }
  }

  IconData _getNotificationIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'under_review':
        return Icons.schedule_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
