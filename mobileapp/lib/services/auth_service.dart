import 'package:supabase_flutter/supabase_flutter.dart';

import 'fcm_service.dart';

/// Service class for handling Supabase authentication operations
/// Manages user signup, signin, signout, and email verification
class AuthService {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final _client = Supabase.instance.client;

  /// Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up new user with email and password
  /// Sends email verification link automatically
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'phone': phone ?? '',
          'email_verified': false,
        },
        emailRedirectTo: null, // Uses default from Supabase dashboard
      );

      if (response.user != null) {
        // Email verification sent automatically by Supabase
        return response;
      } else {
        throw Exception('Signup failed: No user returned');
      }
    } on AuthException catch (e) {
      throw Exception('Signup failed: ${e.message}');
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  /// Sign in existing user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Register FCM token for push notifications
        await FCMService.instance.registerToken(response.user!.id);
        return response;
      } else {
        throw Exception('Login failed: No user returned');
      }
    } on AuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Unregister FCM token before signing out
      if (currentUser != null) {
        await FCMService.instance.unregisterToken(currentUser!.id);
      }
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Signout failed: ${e.message}');
    } catch (e) {
      throw Exception('Signout failed: $e');
    }
  }

  /// Resend email verification link
  Future<void> resendVerificationEmail() async {
    try {
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      await _client.auth.resend(
        type: OtpType.signup,
        email: currentUser!.email,
      );
    } on AuthException catch (e) {
      throw Exception('Resend verification failed: ${e.message}');
    } catch (e) {
      throw Exception('Resend verification failed: $e');
    }
  }

  /// Check if current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      if (currentUser == null) return false;

      // Refresh user session to get latest verification status
      await _client.auth.refreshSession();
      final user = _client.auth.currentUser;

      // Check both auth.users confirmation and user_profiles flag
      final isConfirmed = user?.emailConfirmedAt != null;

      if (isConfirmed) {
        // Also check user_profiles table for consistency
        final profile = await _client
            .from('user_profiles')
            .select('email_verified')
            .eq('id', user!.id)
            .maybeSingle();

        return profile?['email_verified'] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final profile = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return profile;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user's password (called after clicking reset email link)
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception('Password update failed: ${e.message}');
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  /// Update user profile data
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _client
            .from('user_profiles')
            .update(updates)
            .eq('id', currentUser!.id);
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
}
