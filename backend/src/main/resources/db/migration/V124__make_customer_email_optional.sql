-- Same reasoning as V123 (users.email): a Customer row can now be created
-- from a User that registered with no email (OrderService creates one on a
-- user's first order if it doesn't exist yet). With customers.email still
-- NOT NULL, that insert would hard-fail for any email-less customer placing
-- their first order.
ALTER TABLE customers ALTER COLUMN email DROP NOT NULL;
ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_email_key;
CREATE UNIQUE INDEX IF NOT EXISTS customers_email_unique_idx ON customers (email) WHERE email IS NOT NULL;
