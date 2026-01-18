import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for handling Supabase storage operations
/// Manages avatar image uploads and deletions
class StorageService {
  static final StorageService instance = StorageService._internal();
  factory StorageService() => instance;
  StorageService._internal();

  final _client = Supabase.instance.client;
  static const String _avatarBucket = 'avatars';

  /// Upload avatar image and return public URL
  /// Automatically deletes existing avatar before uploading new one
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No user signed in');
      }

      // Delete existing avatar first
      await _deleteExistingAvatar(userId);

      // Generate unique filename with timestamp
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$fileName';

      // Upload new avatar
      await _client.storage.from(_avatarBucket).upload(
            filePath,
            imageFile,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Avatar upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Avatar upload failed: $e');
    }
  }

  /// Delete existing avatar files for a user
  Future<void> _deleteExistingAvatar(String userId) async {
    try {
      // List all files in user's folder
      final files = await _client.storage.from(_avatarBucket).list(path: userId);

      if (files.isNotEmpty) {
        // Delete all existing avatar files
        final filePaths = files.map((file) => '$userId/${file.name}').toList();
        await _client.storage.from(_avatarBucket).remove(filePaths);
      }
    } catch (e) {
      // Ignore errors when deleting - folder might not exist yet
    }
  }

  /// Get content type based on file extension
  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
