-- Migration: Add added_by_shop_owner column to order_items table
-- This tracks whether an item was added by shop owner after the original order

-- Add the column with default value false for existing items
ALTER TABLE order_items
ADD COLUMN IF NOT EXISTS added_by_shop_owner BOOLEAN NOT NULL DEFAULT FALSE;

-- Update comment
COMMENT ON COLUMN order_items.added_by_shop_owner IS 'True if item was added by shop owner after original order, false if ordered by customer';
