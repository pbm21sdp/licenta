-- Location: supabase/migrations/20260117180000_user_preferences.sql
-- Schema Analysis: Existing tables - user_profiles, pets, user_favorites, pet_interactions
-- Integration Type: NEW_TABLE - Adding user preferences for pet filtering
-- Dependencies: user_profiles for user relationships

-- 1. Core Table
CREATE TABLE public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    preferred_pet_types TEXT[] DEFAULT '{}',
    has_garden BOOLEAN DEFAULT false,
    has_children BOOLEAN DEFAULT false,
    children_ages TEXT[] DEFAULT '{}',
    has_other_pets BOOLEAN DEFAULT false,
    other_pet_types TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Indexes
CREATE INDEX idx_user_preferences_user_id ON public.user_preferences(user_id);

-- 3. Enable RLS
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies

-- Users can view their own preferences
CREATE POLICY "users_can_view_own_preferences"
ON public.user_preferences
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own preferences
CREATE POLICY "users_can_insert_own_preferences"
ON public.user_preferences
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own preferences
CREATE POLICY "users_can_update_own_preferences"
ON public.user_preferences
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own preferences
CREATE POLICY "users_can_delete_own_preferences"
ON public.user_preferences
FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- 5. Trigger for updated_at
CREATE OR REPLACE FUNCTION public.update_user_preferences_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_user_preferences_timestamp
BEFORE UPDATE ON public.user_preferences
FOR EACH ROW
EXECUTE FUNCTION public.update_user_preferences_updated_at();

-- 6. Comments
COMMENT ON TABLE public.user_preferences IS 'Stores user preferences for pet filtering and matching';
COMMENT ON COLUMN public.user_preferences.preferred_pet_types IS 'Array of preferred pet types (e.g., Dog, Cat)';
COMMENT ON COLUMN public.user_preferences.has_garden IS 'Whether the user has access to a garden';
COMMENT ON COLUMN public.user_preferences.has_children IS 'Whether the user has children in the household';
COMMENT ON COLUMN public.user_preferences.children_ages IS 'Array of children age ranges (e.g., 0-5, 6-12)';
COMMENT ON COLUMN public.user_preferences.has_other_pets IS 'Whether the user has other pets';
COMMENT ON COLUMN public.user_preferences.other_pet_types IS 'Array of existing pet types in the household';
