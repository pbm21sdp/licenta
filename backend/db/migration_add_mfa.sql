-- migration_add_mfa.sql

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS mfa_secret VARCHAR(255), -- Secret key pentru Google Authenticator (base32 encoded)
ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false; -- Flag care indica daca MFA e activ pentru user

-- Comentarii pentru documentatie
COMMENT ON COLUMN users.mfa_secret IS 'TOTP secret for Google Authenticator (base32 encoded)';
COMMENT ON COLUMN users.mfa_enabled IS 'Whether MFA is enabled for this user';

-- Index
CREATE INDEX IF NOT EXISTS idx_users_mfa_enabled ON users(mfa_enabled) WHERE mfa_enabled = true;