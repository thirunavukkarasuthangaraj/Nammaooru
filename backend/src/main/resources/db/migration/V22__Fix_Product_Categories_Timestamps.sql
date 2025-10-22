-- Fix product_categories table - ensure all timestamp columns exist
-- This migration safely adds missing columns if they don't exist

-- Add created_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='product_categories' AND column_name='created_at') THEN
        ALTER TABLE product_categories
        ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Add updated_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='product_categories' AND column_name='updated_at') THEN
        ALTER TABLE product_categories
        ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- Add updated_by if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='product_categories' AND column_name='updated_by') THEN
        ALTER TABLE product_categories
        ADD COLUMN updated_by VARCHAR(255);
    END IF;
END $$;

-- Create a function to update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_product_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists and recreate
DROP TRIGGER IF EXISTS product_categories_updated_at_trigger ON product_categories;

CREATE TRIGGER product_categories_updated_at_trigger
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_product_categories_updated_at();

-- Update existing rows to have current timestamp if they're null
UPDATE product_categories
SET updated_at = COALESCE(updated_at, created_at, CURRENT_TIMESTAMP)
WHERE updated_at IS NULL;

UPDATE product_categories
SET created_at = COALESCE(created_at, CURRENT_TIMESTAMP)
WHERE created_at IS NULL;
