-- Location: supabase/migrations/20260117120700_adoption_applications.sql
-- Module: Adoption Application System
-- Integration Type: NEW_MODULE
-- Dependencies: None (Fresh project - no existing tables)

-- ============================================================================
-- 1. CUSTOM TYPES
-- ============================================================================

CREATE TYPE public.application_status AS ENUM (
    'pending',
    'under_review',
    'approved',
    'rejected',
    'withdrawn'
);

CREATE TYPE public.housing_type AS ENUM (
    'house',
    'apartment',
    'condo',
    'other'
);

CREATE TYPE public.experience_level AS ENUM (
    'first_time',
    'some_experience',
    'very_experienced'
);

-- ============================================================================
-- 2. CORE TABLES
-- ============================================================================

-- Shelter Profiles Table
CREATE TABLE public.shelter_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    address TEXT,
    description TEXT,
    website_url TEXT,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Adoption Applications Table
CREATE TABLE public.adoption_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id TEXT NOT NULL,
    pet_name TEXT NOT NULL,
    shelter_id UUID REFERENCES public.shelter_profiles(id) ON DELETE SET NULL,
    applicant_name TEXT NOT NULL,
    applicant_email TEXT NOT NULL,
    applicant_phone TEXT NOT NULL,
    applicant_address TEXT NOT NULL,
    housing_type public.housing_type NOT NULL,
    has_garden BOOLEAN DEFAULT false,
    has_existing_pets BOOLEAN DEFAULT false,
    experience_level public.experience_level NOT NULL,
    additional_notes TEXT,
    application_status public.application_status DEFAULT 'pending'::public.application_status,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ,
    reviewer_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. INDEXES
-- ============================================================================

CREATE INDEX idx_shelter_profiles_email ON public.shelter_profiles(email);
CREATE INDEX idx_shelter_profiles_active ON public.shelter_profiles(is_active);
CREATE INDEX idx_adoption_applications_pet_id ON public.adoption_applications(pet_id);
CREATE INDEX idx_adoption_applications_shelter_id ON public.adoption_applications(shelter_id);
CREATE INDEX idx_adoption_applications_email ON public.adoption_applications(applicant_email);
CREATE INDEX idx_adoption_applications_status ON public.adoption_applications(application_status);
CREATE INDEX idx_adoption_applications_submitted ON public.adoption_applications(submitted_at DESC);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.shelter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adoption_applications ENABLE ROW LEVEL SECURITY;

-- Shelter Profiles - Public read access, no write access (admin only in production)
CREATE POLICY "public_read_shelters"
ON public.shelter_profiles
FOR SELECT
TO public
USING (is_active = true);

-- Adoption Applications - Public can create, no read access (privacy)
CREATE POLICY "public_create_applications"
ON public.adoption_applications
FOR INSERT
TO public
WITH CHECK (true);

-- ============================================================================
-- 5. FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$func$;

-- ============================================================================
-- 6. TRIGGERS
-- ============================================================================

CREATE TRIGGER update_shelter_profiles_updated_at
    BEFORE UPDATE ON public.shelter_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_adoption_applications_updated_at
    BEFORE UPDATE ON public.adoption_applications
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 7. MOCK DATA
-- ============================================================================

DO $$
DECLARE
    shelter1_id UUID := gen_random_uuid();
    shelter2_id UUID := gen_random_uuid();
    shelter3_id UUID := gen_random_uuid();
BEGIN
    -- Insert sample shelters
    INSERT INTO public.shelter_profiles (id, name, email, phone, address, description, website_url, is_active)
    VALUES
        (
            shelter1_id,
            'Paws & Hearts Animal Shelter',
            'contact@pawsandhearts.org',
            '+1-555-0101',
            '123 Animal Lane, Pet City, PC 12345',
            'Dedicated to finding loving homes for abandoned and rescued animals. We provide medical care, shelter, and adoption services.',
            'https://pawsandhearts.org',
            true
        ),
        (
            shelter2_id,
            'Forever Friends Pet Rescue',
            'info@foreverfriends.org',
            '+1-555-0102',
            '456 Rescue Road, Animal Town, AT 67890',
            'A no-kill shelter focused on rehabilitation and rehoming pets in need. We work with local communities to promote responsible pet ownership.',
            'https://foreverfriends.org',
            true
        ),
        (
            shelter3_id,
            'Happy Tails Sanctuary',
            'hello@happytails.org',
            '+1-555-0103',
            '789 Sanctuary Street, Pet Haven, PH 11223',
            'Providing a safe haven for pets awaiting their forever homes. We specialize in senior pets and special needs animals.',
            'https://happytails.org',
            true
        );

    -- Insert sample applications
    INSERT INTO public.adoption_applications (
        pet_id,
        pet_name,
        shelter_id,
        applicant_name,
        applicant_email,
        applicant_phone,
        applicant_address,
        housing_type,
        has_garden,
        has_existing_pets,
        experience_level,
        additional_notes,
        application_status,
        submitted_at
    )
    VALUES
        (
            'pet_001',
            'Max',
            shelter1_id,
            'John Smith',
            'john.smith@example.com',
            '+1-555-1001',
            '101 Main Street, Hometown, HT 54321',
            'house'::public.housing_type,
            true,
            false,
            'some_experience'::public.experience_level,
            'I have a large backyard and work from home, so I can give Max plenty of attention.',
            'pending'::public.application_status,
            CURRENT_TIMESTAMP - INTERVAL '2 days'
        ),
        (
            'pet_002',
            'Bella',
            shelter2_id,
            'Sarah Johnson',
            'sarah.j@example.com',
            '+1-555-1002',
            '202 Oak Avenue, Petville, PV 98765',
            'apartment'::public.housing_type,
            false,
            true,
            'very_experienced'::public.experience_level,
            'I currently have a cat and would love to give Bella a loving home. My apartment allows two pets.',
            'under_review'::public.application_status,
            CURRENT_TIMESTAMP - INTERVAL '5 days'
        ),
        (
            'pet_003',
            'Charlie',
            shelter3_id,
            'Michael Brown',
            'mbrown@example.com',
            '+1-555-1003',
            '303 Elm Drive, Dogtown, DT 13579',
            'house'::public.housing_type,
            true,
            false,
            'first_time'::public.experience_level,
            'This will be my first pet, and I am committed to providing a safe and loving environment.',
            'approved'::public.application_status,
            CURRENT_TIMESTAMP - INTERVAL '7 days'
        );

    RAISE NOTICE 'Mock data inserted successfully';
END $$;

-- ============================================================================
-- 8. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.shelter_profiles IS 'Stores information about animal shelters';
COMMENT ON TABLE public.adoption_applications IS 'Stores pet adoption applications submitted by users';
COMMENT ON TYPE public.application_status IS 'Status of adoption application';
COMMENT ON TYPE public.housing_type IS 'Type of housing for applicant';
COMMENT ON TYPE public.experience_level IS 'Level of pet ownership experience';