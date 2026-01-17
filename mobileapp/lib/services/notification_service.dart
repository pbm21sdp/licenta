import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Service for managing application notifications and real-time updates
class NotificationService {
  final SupabaseClient _client = SupabaseService.instance.client;

  /// Fetch all notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications(String userEmail) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('applicant_email', userEmail)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch notifications: $error');
    }
  }

  /// Fetch unread notifications count
  Future<int> getUnreadCount(String userEmail) async {
    try {
      final response = await _client.rpc(
        'get_unread_notification_count',
        params: {'user_email': userEmail},
      );
      return response as int;
    } catch (error) {
      throw Exception('Failed to fetch unread count: $error');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.rpc(
        'mark_notification_read',
        params: {'notification_id': notificationId},
      );
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userEmail) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('applicant_email', userEmail)
          .eq('is_read', false);
    } catch (error) {
      throw Exception('Failed to mark all as read: $error');
    }
  }

  /// Subscribe to real-time notification changes
  RealtimeChannel subscribeToNotifications({
    required String userEmail,
    required Function(Map<String, dynamic>) onNotification,
  }) {
    return _client
        .channel('notifications:$userEmail')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'applicant_email',
            value: userEmail,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
                    },
        )
        .subscribe();
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
