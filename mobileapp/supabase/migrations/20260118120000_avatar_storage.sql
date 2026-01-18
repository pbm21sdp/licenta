-- Location: supabase/migrations/20260118120000_avatar_storage.sql
-- Schema Analysis: Storage configuration for user avatars
-- Integration Type: STORAGE_BUCKET - Creating avatars bucket with RLS policies
-- Dependencies: auth.users for user authentication
-- File structure: avatars/{user_id}/avatar_timestamp.{extension}

-- 1. Create storage bucket for avatars (public bucket for avatar URLs)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Storage Policies for avatars bucket

-- Users can upload avatars to their own folder
CREATE POLICY "users_can_upload_own_avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own avatars
CREATE POLICY "users_can_update_own_avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own avatars
CREATE POLICY "users_can_delete_own_avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Public read access for all avatars (since bucket is public)
CREATE POLICY "public_can_view_avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');
