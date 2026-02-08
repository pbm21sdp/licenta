-- migration_peer_to_peer.sql
-- Migrare pentru transformarea aplicației în model peer-to-peer
-- Orice utilizator poate adăuga animale și poate aproba/respinge cereri de adopție

-- =====================================================
-- 1. ADAUGĂ OWNER_ID LA PETS
-- =====================================================

-- Adaugă coloana owner_id pentru a lega animalele de utilizatori
ALTER TABLE pets ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES users(id) ON DELETE SET NULL;

-- Index pentru căutări rapide după owner
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);

-- Index compus pentru query-uri frecvente (animalele disponibile ale unui owner)
CREATE INDEX IF NOT EXISTS idx_pets_owner_available ON pets(owner_id, is_available);

-- =====================================================
-- 2. ADAUGĂ OWNER INFO LA ADOPTIONS
-- =====================================================

-- Adaugă coloanele pentru informații despre owner (denormalizare pentru istoric)
ALTER TABLE adoptions ADD COLUMN IF NOT EXISTS owner_id INTEGER;
ALTER TABLE adoptions ADD COLUMN IF NOT EXISTS owner_name VARCHAR(100);
ALTER TABLE adoptions ADD COLUMN IF NOT EXISTS owner_email VARCHAR(255);

-- Index pentru căutări rapide după owner în adoptions
CREATE INDEX IF NOT EXISTS idx_adoptions_owner_id ON adoptions(owner_id);

-- Index compus pentru query-uri frecvente (cererile pentru un owner cu un anumit status)
CREATE INDEX IF NOT EXISTS idx_adoptions_owner_status ON adoptions(owner_id, status);

-- =====================================================
-- 3. COMENTARII PENTRU DOCUMENTAȚIE
-- =====================================================

COMMENT ON COLUMN pets.owner_id IS 'ID-ul utilizatorului care a adăugat animalul - NULL pentru animale adăugate de admin sau utilizatori șterși';
COMMENT ON COLUMN adoptions.owner_id IS 'ID-ul proprietarului animalului la momentul cererii - denormalizat pentru istoric';
COMMENT ON COLUMN adoptions.owner_name IS 'Numele proprietarului la momentul cererii - denormalizat pentru istoric';
COMMENT ON COLUMN adoptions.owner_email IS 'Email-ul proprietarului la momentul cererii - denormalizat pentru istoric';

-- =====================================================
-- 4. ACTUALIZARE ANIMALE EXISTENTE
-- =====================================================

-- Opțional: Atribuie animalele existente unui admin sau lasă owner_id NULL
-- Aceasta este o decizie de business - animalele fără owner sunt considerate ale "sistemului"
-- UPDATE pets SET owner_id = (SELECT id FROM users WHERE is_admin = true LIMIT 1) WHERE owner_id IS NULL;
