-- =====================================================
-- Migration: Reset User Cooldowns Feature
-- Created: 2026-01-19
-- Description: Adds shelter staff functionality to reset adopter
--              skip cooldowns and view adopter list
-- Dependencies:
--   - 20260117122700_authentication_with_email_verification.sql (user_profiles)
--   - 20260117133600_pet_swiping_system.sql (pet_interactions)
--   - 20260118180000_role_based_authentication.sql (user_role enum, get_user_role())
-- =====================================================

-- =====================================================
-- 1. RLS Policy: Expand user_profiles SELECT policy
-- =====================================================
-- Replaces the original policy to also allow shelter staff
-- to view adopter profiles for cooldown management

DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;

CREATE POLICY "users_can_view_own_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    -- User is viewing their own profile
    auth.uid() = id
    OR
    -- User is shelter_staff and target is an adopter
    -- Note: Uses get_user_role() SECURITY DEFINER function to avoid RLS recursion
    (
        public.get_user_role(auth.uid()) = 'shelter_staff'
        AND role = 'adopter'
    )
);

-- =====================================================
-- 2. RPC Function: get_adopters()
-- =====================================================
-- Returns all users with adopter role for shelter staff
-- Uses SECURITY DEFINER to bypass RLS

CREATE OR REPLACE FUNCTION public.get_adopters()
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    caller_role public.user_role;
BEGIN
    -- Verify caller is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify caller is shelter_staff
    SELECT role INTO caller_role
    FROM public.user_profiles
    WHERE user_profiles.id = auth.uid();

    IF caller_role IS NULL OR caller_role != 'shelter_staff' THEN
        RAISE EXCEPTION 'Only shelter staff can view adopters';
    END IF;

    -- Return all adopters ordered by name
    RETURN QUERY
    SELECT
        up.id,
        up.email,
        up.full_name,
        up.avatar_url
    FROM public.user_profiles up
    WHERE up.role = 'adopter'
    ORDER BY up.full_name ASC NULLS LAST;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_adopters() TO authenticated;

COMMENT ON FUNCTION public.get_adopters() IS
    'Returns all users with adopter role. Only callable by shelter staff.';

-- =====================================================
-- 3. RPC Function: reset_user_cooldowns()
-- =====================================================
-- Allows shelter staff to reset skip cooldowns for an adopter
-- Deletes all 'skip' interactions from pet_interactions table

CREATE OR REPLACE FUNCTION public.reset_user_cooldowns(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    caller_role public.user_role;
BEGIN
    -- Verify caller is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify caller is shelter_staff
    SELECT role INTO caller_role
    FROM public.user_profiles
    WHERE id = auth.uid();

    IF caller_role IS NULL OR caller_role != 'shelter_staff' THEN
        RAISE EXCEPTION 'Only shelter staff can reset cooldowns';
    END IF;

    -- Verify target user exists and is an adopter
    IF NOT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = target_user_id AND role = 'adopter'
    ) THEN
        RAISE EXCEPTION 'Target user not found or is not an adopter';
    END IF;

    -- Delete all skip interactions for the target user
    DELETE FROM public.pet_interactions
    WHERE user_id = target_user_id
      AND interaction_type = 'skip';
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_user_cooldowns(UUID) TO authenticated;

COMMENT ON FUNCTION public.reset_user_cooldowns(UUID) IS
    'Allows shelter staff to reset all skip cooldowns for an adopter. '
    'Deletes all skip interactions from pet_interactions table for the specified user.';
