-- Location: supabase/migrations/20260117122700_authentication_with_email_verification.sql
-- Schema Analysis: Existing tables - adoption_applications, notifications, shelter_profiles
-- Integration Type: NEW_MODULE - Authentication system with email verification
-- Dependencies: auth.users (Supabase managed)

-- 1. Create user_profiles table (intermediary for public schema)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_email_verified ON public.user_profiles(email_verified);

-- 3. Create trigger function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, phone, email_verified)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE((NEW.raw_user_meta_data->>'email_verified')::boolean, false)
    );
    RETURN NEW;
END;
$$;

-- 4. Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Create function to update user profile email verification status
CREATE OR REPLACE FUNCTION public.update_user_email_verification()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update user_profiles when auth.users email is confirmed
    IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
        UPDATE public.user_profiles
        SET email_verified = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

-- 6. Create trigger for email verification updates
DROP TRIGGER IF EXISTS on_user_email_verified ON auth.users;
CREATE TRIGGER on_user_email_verified
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_email_verification();

-- 7. Enable RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS policies for user_profiles (Pattern 1 - Core User Table)
CREATE POLICY "users_can_view_own_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "users_can_update_own_profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 9. Create function to check if user email is verified
CREATE OR REPLACE FUNCTION public.is_user_email_verified()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COALESCE(
        (SELECT email_verified FROM public.user_profiles WHERE id = auth.uid()),
        false
    );
$$;

-- 10. Update existing adoption_applications to reference user_profiles instead of direct email
-- Add user_id column for future use (migration preparation)
ALTER TABLE public.adoption_applications
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;

-- 11. Create updated_at trigger function for user_profiles
CREATE OR REPLACE FUNCTION public.update_user_profiles_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 12. Create trigger for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at_trigger ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at_trigger
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_profiles_updated_at();

-- 13. Mock data for testing (creates auth users that trigger profile creation)
DO $$
DECLARE
    test_user1_id UUID := gen_random_uuid();
    test_user2_id UUID := gen_random_uuid();
BEGIN
    -- Insert test users into auth.users (trigger will create profiles automatically)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (test_user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'verified@petadoption.com', crypt('VerifiedUser123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Verified User", "email_verified": true}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (test_user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'unverified@petadoption.com', crypt('UnverifiedUser123', gen_salt('bf', 10)), null, now(), now(),
         '{"full_name": "Unverified User", "email_verified": false}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);
END $$;

-- 14. Add comment for documentation
COMMENT ON TABLE public.user_profiles IS 'User profile data synced from auth.users with email verification tracking';
COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates user_profiles entry when auth.users record is created';
COMMENT ON FUNCTION public.update_user_email_verification() IS 'Updates email_verified flag when user confirms email in auth.users';
COMMENT ON FUNCTION public.is_user_email_verified() IS 'Returns true if current user has verified their email address';