-- Location: supabase/migrations/20260117133600_pet_swiping_system.sql
-- Schema Analysis: Existing tables - user_profiles, adoption_applications, shelter_profiles, notifications
-- Integration Type: NEW_MODULE - Adding pet swiping system
-- Dependencies: user_profiles for user relationships

-- 1. Types
CREATE TYPE public.pet_species AS ENUM ('dog', 'cat', 'other');
CREATE TYPE public.pet_gender AS ENUM ('male', 'female');
CREATE TYPE public.interaction_type AS ENUM ('like', 'skip');

-- 2. Core Tables
CREATE TABLE public.pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    species public.pet_species NOT NULL,
    breed TEXT NOT NULL,
    age_years INTEGER NOT NULL CHECK (age_years >= 0),
    gender public.pet_gender NOT NULL,
    description TEXT,
    health_status TEXT,
    image_url TEXT NOT NULL,
    image_semantic_label TEXT NOT NULL,
    shelter_id UUID REFERENCES public.shelter_profiles(id) ON DELETE CASCADE,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.pet_gallery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_semantic_label TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, pet_id)
);

CREATE TABLE public.pet_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE,
    interaction_type public.interaction_type NOT NULL,
    cooldown_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX idx_pets_shelter_id ON public.pets(shelter_id);
CREATE INDEX idx_pets_species ON public.pets(species);
CREATE INDEX idx_pets_is_available ON public.pets(is_available);
CREATE INDEX idx_pet_gallery_pet_id ON public.pet_gallery(pet_id);
CREATE INDEX idx_user_favorites_user_id ON public.user_favorites(user_id);
CREATE INDEX idx_user_favorites_pet_id ON public.user_favorites(pet_id);
CREATE INDEX idx_pet_interactions_user_id ON public.pet_interactions(user_id);
CREATE INDEX idx_pet_interactions_pet_id ON public.pet_interactions(pet_id);
CREATE INDEX idx_pet_interactions_cooldown ON public.pet_interactions(cooldown_until);

-- 4. Functions
CREATE OR REPLACE FUNCTION public.update_pet_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pet_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pet_interactions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- Pets: Public read, authenticated users can see available pets
CREATE POLICY "public_can_view_available_pets"
ON public.pets
FOR SELECT
TO public
USING (is_available = true);

-- Pet Gallery: Public read for available pets
CREATE POLICY "public_can_view_pet_gallery"
ON public.pet_gallery
FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.pets p
        WHERE p.id = pet_gallery.pet_id AND p.is_available = true
    )
);

-- User Favorites: Users manage their own favorites
CREATE POLICY "users_manage_own_favorites"
ON public.user_favorites
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pet Interactions: Users manage their own interactions
CREATE POLICY "users_manage_own_interactions"
ON public.pet_interactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers
CREATE TRIGGER trigger_update_pet_timestamp
BEFORE UPDATE ON public.pets
FOR EACH ROW
EXECUTE FUNCTION public.update_pet_updated_at();

-- 8. Mock Data
DO $$
DECLARE
    shelter1_id UUID;
    pet1_id UUID := gen_random_uuid();
    pet2_id UUID := gen_random_uuid();
    pet3_id UUID := gen_random_uuid();
    pet4_id UUID := gen_random_uuid();
    pet5_id UUID := gen_random_uuid();
    pet6_id UUID := gen_random_uuid();
BEGIN
    -- Get existing shelter ID
    SELECT id INTO shelter1_id FROM public.shelter_profiles LIMIT 1;
    
    -- If no shelter exists, create a default one
    IF shelter1_id IS NULL THEN
        shelter1_id := gen_random_uuid();
        INSERT INTO public.shelter_profiles (id, name, email, phone, address, description)
        VALUES (
            shelter1_id,
            'Happy Paws Shelter',
            'contact@happypaws.org',
            '555-0123',
            '123 Pet Street, Animalville, ST 12345',
            'A loving shelter dedicated to finding forever homes for pets in need'
        );
    END IF;

    -- Insert pets
    INSERT INTO public.pets (id, name, species, breed, age_years, gender, description, health_status, image_url, image_semantic_label, shelter_id, is_available)
    VALUES
        (pet1_id, 'Luna', 'dog'::public.pet_species, 'Golden Retriever', 2, 'female'::public.pet_gender,
         'Luna is a friendly and energetic Golden Retriever who loves playing fetch and swimming. She is great with children and other pets.',
         'Vaccinated, Spayed, Microchipped',
         'https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d',
         'Golden Retriever dog with fluffy golden fur sitting outdoors in natural lighting',
         shelter1_id, true),
        
        (pet2_id, 'Max', 'dog'::public.pet_species, 'Labrador', 3, 'male'::public.pet_gender,
         'Max is a loyal and intelligent Labrador who enjoys long walks and training sessions. He is well-behaved and house-trained.',
         'Vaccinated, Neutered, Microchipped',
         'https://images.unsplash.com/photo-1507270603269-dbbf5099b47c',
         'Black Labrador dog with shiny coat sitting attentively with alert expression',
         shelter1_id, true),
        
        (pet3_id, 'Bella', 'cat'::public.pet_species, 'Persian Cat', 1, 'female'::public.pet_gender,
         'Bella is a gentle and affectionate Persian cat who loves cuddles and quiet environments. She is perfect for apartment living.',
         'Vaccinated, Spayed, Dewormed',
         'https://images.unsplash.com/photo-1612801143784-84b527938e53',
         'White Persian cat with fluffy fur and blue eyes looking directly at camera',
         shelter1_id, true),
        
        (pet4_id, 'Charlie', 'dog'::public.pet_species, 'Beagle', 4, 'male'::public.pet_gender,
         'Charlie is a playful and curious Beagle with a great sense of smell. He loves outdoor adventures and exploring new places.',
         'Vaccinated, Neutered, Microchipped',
         'https://images.unsplash.com/photo-1603088839340-d73e99dd831a',
         'Beagle dog with brown and white coat sitting on wooden deck with curious expression',
         shelter1_id, true),
        
        (pet5_id, 'Daisy', 'cat'::public.pet_species, 'Siamese Cat', 2, 'female'::public.pet_gender,
         'Daisy is a vocal and social Siamese cat who loves attention and interactive play. She is very intelligent and learns tricks quickly.',
         'Vaccinated, Spayed, Microchipped',
         'https://images.unsplash.com/photo-1709262315195-3254daf9068c',
         'Siamese cat with cream and brown points sitting elegantly with blue eyes',
         shelter1_id, true),
        
        (pet6_id, 'Rocky', 'dog'::public.pet_species, 'German Shepherd', 5, 'male'::public.pet_gender,
         'Rocky is a protective and loyal German Shepherd who makes an excellent guard dog. He is well-trained and responds to commands.',
         'Vaccinated, Neutered, Microchipped',
         'https://images.unsplash.com/photo-1582660482303-0b292b0971fe',
         'German Shepherd dog with black and tan coat sitting alert with pointed ears',
         shelter1_id, true);

    -- Insert pet gallery images
    INSERT INTO public.pet_gallery (pet_id, image_url, image_semantic_label, display_order)
    VALUES
        (pet1_id, 'https://images.unsplash.com/photo-1692050751434-e72e29ddcc5d', 'Golden Retriever dog with fluffy golden fur sitting outdoors in natural lighting', 0),
        (pet1_id, 'https://images.unsplash.com/photo-1632366941290-f3248eb1699f', 'Golden Retriever puppy lying on grass with tongue out', 1),
        
        (pet2_id, 'https://images.unsplash.com/photo-1507270603269-dbbf5099b47c', 'Black Labrador dog with shiny coat sitting attentively with alert expression', 0),
        (pet2_id, 'https://images.unsplash.com/photo-1575493125700-d31ebbc72b09', 'Black Labrador running through water with joyful expression', 1),
        
        (pet3_id, 'https://images.unsplash.com/photo-1612801143784-84b527938e53', 'White Persian cat with fluffy fur and blue eyes looking directly at camera', 0),
        (pet3_id, 'https://images.unsplash.com/photo-1575408824052-8f497497f04b', 'White Persian cat grooming itself on soft blanket', 1),
        
        (pet4_id, 'https://images.unsplash.com/photo-1603088839340-d73e99dd831a', 'Beagle dog with brown and white coat sitting on wooden deck with curious expression', 0),
        (pet4_id, 'https://images.unsplash.com/photo-1548980939-59b205ca539d', 'Beagle dog running through autumn leaves with happy expression', 1),
        
        (pet5_id, 'https://images.unsplash.com/photo-1709262315195-3254daf9068c', 'Siamese cat with cream and brown points sitting elegantly with blue eyes', 0),
        (pet5_id, 'https://images.unsplash.com/photo-1624268898688-2e745a947348', 'Siamese cat playing with toy on carpet', 1),
        
        (pet6_id, 'https://images.unsplash.com/photo-1582660482303-0b292b0971fe', 'German Shepherd dog with black and tan coat sitting alert with pointed ears', 0),
        (pet6_id, 'https://img.rocket.new/generatedImages/rocket_gen_img_1c0db7698-1764889533933.png', 'German Shepherd running through field with focused expression', 1);

END $$;