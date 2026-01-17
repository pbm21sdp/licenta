-- Location: supabase/migrations/20260117171930_fix_adoption_applications_rls.sql
-- Module: Fix Adoption Applications RLS Policy
-- Integration Type: PARTIAL_EXISTS (Fixing existing RLS policy)
-- Dependencies: adoption_applications table

-- ============================================================================
-- DROP EXISTING POLICY
-- ============================================================================

DROP POLICY IF EXISTS "public_create_applications" ON public.adoption_applications;

-- ============================================================================
-- CREATE NEW RLS POLICIES
-- ============================================================================

-- Allow authenticated users to insert their own applications
CREATE POLICY "authenticated_create_applications"
ON public.adoption_applications
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Allow anonymous users to insert applications (without user_id)
CREATE POLICY "anon_create_applications"
ON public.adoption_applications
FOR INSERT
TO anon
WITH CHECK (user_id IS NULL);

-- Allow users to read their own applications
CREATE POLICY "users_read_own_applications"
ON public.adoption_applications
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow users to update their own applications (e.g., withdraw)
CREATE POLICY "users_update_own_applications"
ON public.adoption_applications
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON POLICY "authenticated_create_applications" ON public.adoption_applications IS 
'Allows authenticated users to create adoption applications with their user_id';

COMMENT ON POLICY "anon_create_applications" ON public.adoption_applications IS 
'Allows anonymous users to create adoption applications without user_id';

COMMENT ON POLICY "users_read_own_applications" ON public.adoption_applications IS 
'Allows users to read their own adoption applications';

COMMENT ON POLICY "users_update_own_applications" ON public.adoption_applications IS 
'Allows users to update their own adoption applications';