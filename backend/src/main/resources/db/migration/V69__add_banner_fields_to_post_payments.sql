-- Add banner support fields to post_payments table
ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS includes_banner BOOLEAN DEFAULT FALSE;
ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS banner_amount INTEGER DEFAULT 0;
