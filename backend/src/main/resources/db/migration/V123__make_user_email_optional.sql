-- Customer registration already verifies accounts via mobile/SMS OTP
-- (MobileOtpService), not email — email was only ever a required form
-- field, causing signup drop-off for users who don't want to give one.
-- Drop the NOT NULL/unique constraint and replace it with a partial
-- unique index so multiple users can have no email, but any email that
-- IS set still has to be unique.
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique_idx ON users (email) WHERE email IS NOT NULL;
