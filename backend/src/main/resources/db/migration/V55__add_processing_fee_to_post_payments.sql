-- Add processing fee and total amount columns to post_payments
ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS processing_fee INTEGER DEFAULT 0;
ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS total_amount INTEGER;

-- Update existing records: total_amount = amount (no processing fee was charged before)
UPDATE post_payments SET total_amount = amount WHERE total_amount IS NULL;
