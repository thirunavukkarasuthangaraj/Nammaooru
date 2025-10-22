-- Migration: Add user phone column safely
-- Version: V23
-- Scenario: Column already exists in production
-- This migration is "idempotent" - safe to run multiple times

-- ============================================
-- SAFE APPROACH: Check if column exists first
-- ============================================

DO $$
BEGIN
    -- Check if the column already exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'phone_number'
    ) THEN
        -- Column doesn't exist, so add it
        ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);

        -- Optional: Add index if needed
        CREATE INDEX idx_users_phone_number ON users(phone_number);

        RAISE NOTICE 'Added phone_number column to users table';
    ELSE
        -- Column already exists (production), skip
        RAISE NOTICE 'Column phone_number already exists, skipping';
    END IF;
END $$;

-- ============================================
-- ADDITIONAL SAFE OPERATIONS
-- ============================================

-- Add default value for existing rows if needed
UPDATE users SET phone_number = NULL WHERE phone_number IS NULL;

-- Add constraint if needed (also check if exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'check_phone_format'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT check_phone_format
        CHECK (phone_number IS NULL OR length(phone_number) >= 10);
    END IF;
END $$;

-- ============================================
-- REAL WORLD EXAMPLE: Multiple Operations
-- ============================================

-- Example: Add multiple columns safely
DO $$
BEGIN
    -- Add email_verified column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add phone_verified column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'phone_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add verification_token column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'verification_token'
    ) THEN
        ALTER TABLE users ADD COLUMN verification_token VARCHAR(255);
    END IF;
END $$;

-- ============================================
-- SAFE INDEX CREATION
-- ============================================

-- Create index only if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);
CREATE INDEX IF NOT EXISTS idx_users_phone_verified ON users(phone_verified);

-- ============================================
-- SAFE TABLE CREATION
-- ============================================

-- Create table only if it doesn't exist
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    session_token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- WHAT HAPPENS IN EACH ENVIRONMENT?
-- ============================================

/*
PRODUCTION (column already exists):
- Check finds existing column
- Skips ALTER TABLE
- Migration completes successfully ✅
- Flyway marks it as applied

LOCAL (column doesn't exist):
- Check doesn't find column
- Runs ALTER TABLE
- Adds the column ✅
- Migration completes successfully

RESULT:
- All environments are now in sync! ✅
- Migration is safe to run anywhere
- No manual SQL needed
*/
