-- =====================================================
-- Migration: Role-Based Authentication for Shelter Staff
-- Created: 2026-01-18
-- Description: Adds role enum, shelter_staff junction table,
--              and RLS policies for shelter staff access
-- =====================================================

-- 1. Create user_role enum type
CREATE TYPE public.user_role AS ENUM ('adopter', 'shelter_staff');

-- 2. Add role column to user_profiles with default 'adopter'
ALTER TABLE public.user_profiles
ADD COLUMN role public.user_role DEFAULT 'adopter' NOT NULL;

-- 3. Create shelter_staff junction table
CREATE TABLE public.shelter_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    shelter_id UUID NOT NULL REFERENCES public.shelter_profiles(id) ON DELETE CASCADE,
    is_primary_contact BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, shelter_id)
);

-- Create index for faster lookups
CREATE INDEX idx_shelter_staff_user_id ON public.shelter_staff(user_id);
CREATE INDEX idx_shelter_staff_shelter_id ON public.shelter_staff(shelter_id);

-- 4. Enable RLS on shelter_staff table
ALTER TABLE public.shelter_staff ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for shelter_staff table

-- Staff can view their own assignment
CREATE POLICY "Staff can view own assignment"
ON public.shelter_staff
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Admins (or Supabase service role) can manage shelter_staff
-- Note: For MVP, shelter staff accounts are created manually via Supabase dashboard

-- 6. RLS Policies for shelter_profiles - Staff can update their shelter

-- Drop existing policies if any for shelter_profiles update
DROP POLICY IF EXISTS "Staff can update own shelter" ON public.shelter_profiles;

-- Staff can update their shelter's profile
CREATE POLICY "Staff can update own shelter"
ON public.shelter_profiles
FOR UPDATE
TO authenticated
USING (
    id IN (
        SELECT shelter_id FROM public.shelter_staff
        WHERE user_id = auth.uid()
    )
);

-- 7. RLS Policies for adoption_applications - Staff access

-- Drop existing staff policies if any
DROP POLICY IF EXISTS "Staff can view shelter applications" ON public.adoption_applications;
DROP POLICY IF EXISTS "Staff can update shelter applications" ON public.adoption_applications;

-- Staff can view applications for their shelter's pets
CREATE POLICY "Staff can view shelter applications"
ON public.adoption_applications
FOR SELECT
TO authenticated
USING (
    pet_id IN (
        SELECT id::text FROM public.pets
        WHERE shelter_id IN (
            SELECT shelter_id FROM public.shelter_staff
            WHERE user_id = auth.uid()
        )
    )
);

-- Staff can update application status for their shelter's pets
CREATE POLICY "Staff can update shelter applications"
ON public.adoption_applications
FOR UPDATE
TO authenticated
USING (
    pet_id IN (
        SELECT id::text FROM public.pets
        WHERE shelter_id IN (
            SELECT shelter_id FROM public.shelter_staff
            WHERE user_id = auth.uid()
        )
    )
);

-- 8. RLS Policies for pets - Staff can manage their shelter's pets

-- Drop existing staff pet policies if any
DROP POLICY IF EXISTS "Staff can insert pets for own shelter" ON public.pets;
DROP POLICY IF EXISTS "Staff can update pets for own shelter" ON public.pets;

-- Staff can insert pets for their shelter
CREATE POLICY "Staff can insert pets for own shelter"
ON public.pets
FOR INSERT
TO authenticated
WITH CHECK (
    shelter_id IN (
        SELECT shelter_id FROM public.shelter_staff
        WHERE user_id = auth.uid()
    )
);

-- Staff can update pets for their shelter
CREATE POLICY "Staff can update pets for own shelter"
ON public.pets
FOR UPDATE
TO authenticated
USING (
    shelter_id IN (
        SELECT shelter_id FROM public.shelter_staff
        WHERE user_id = auth.uid()
    )
);

-- 9. Create trigger for updated_at on shelter_staff
CREATE OR REPLACE FUNCTION public.update_shelter_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shelter_staff_updated_at
    BEFORE UPDATE ON public.shelter_staff
    FOR EACH ROW
    EXECUTE FUNCTION public.update_shelter_staff_updated_at();

-- =====================================================
-- Seed Data: Create test shelter staff user
-- =====================================================

-- First, ensure we have a shelter to assign staff to
-- (Using the first shelter from shelter_profiles if it exists)

-- Create a shelter staff test user
-- Note: This creates the auth user and profile via Supabase's create_user function
-- In production, use: supabase auth admin create-user

-- For development, we'll set up the shelter_staff assignment
-- The actual auth user (shelter@petadoption.com) should be created via Supabase Dashboard
-- or via the auth.users insert if using service role

DO $$
DECLARE
    v_shelter_id UUID;
    v_user_id UUID;
BEGIN
    -- Get the first shelter ID
    SELECT id INTO v_shelter_id FROM public.shelter_profiles LIMIT 1;

    IF v_shelter_id IS NULL THEN
        RAISE NOTICE 'No shelter found. Create a shelter first.';
        RETURN;
    END IF;

    -- Check if shelter staff user already exists in user_profiles
    SELECT id INTO v_user_id FROM public.user_profiles
    WHERE email = 'shelter@petadoption.com';

    IF v_user_id IS NOT NULL THEN
        -- Update the user's role to shelter_staff
        UPDATE public.user_profiles
        SET role = 'shelter_staff'
        WHERE id = v_user_id;

        -- Create shelter_staff assignment if not exists
        INSERT INTO public.shelter_staff (user_id, shelter_id, is_primary_contact)
        VALUES (v_user_id, v_shelter_id, true)
        ON CONFLICT (user_id, shelter_id) DO NOTHING;

        RAISE NOTICE 'Shelter staff assignment created for existing user';
    ELSE
        RAISE NOTICE 'Shelter staff user not found. Create user shelter@petadoption.com via Supabase Auth first.';
    END IF;
END $$;

-- =====================================================
-- Helper function to get user role
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_user_role(p_user_id UUID)
RETURNS public.user_role AS $$
DECLARE
    v_role public.user_role;
BEGIN
    SELECT role INTO v_role
    FROM public.user_profiles
    WHERE id = p_user_id;

    RETURN COALESCE(v_role, 'adopter');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Helper function to get staff's shelter ID
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_staff_shelter_id(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
    v_shelter_id UUID;
BEGIN
    SELECT shelter_id INTO v_shelter_id
    FROM public.shelter_staff
    WHERE user_id = p_user_id
    LIMIT 1;

    RETURN v_shelter_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Grant execute permissions on helper functions
-- =====================================================
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_staff_shelter_id(UUID) TO authenticated;
