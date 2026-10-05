-- ============================================================================
-- Promotion banner approval - run-by-hand version of Flyway V132 + V133.
--
-- Use this to apply the change to prod immediately instead of waiting for the
-- next deploy. It is IDEMPOTENT and safe to run before or after Flyway: every
-- ADD COLUMN uses IF NOT EXISTS and every UPDATE only touches rows whose
-- status is still NULL, so the real migrations will still apply cleanly later
-- and will not overwrite any decision you make in between.
--
--   ssh thiru@65.21.4.236
--   psql -U <user> -d <db> -f promotion_banner_approval.sql
--
-- WHAT IT DOES
--   * adds the banner video + banner image review columns
--   * leaves platform/admin banners live (they were made by an approver)
--   * puts every EXISTING SHOP-OWNER banner image back to PENDING, so old
--     shop-owner banners stop showing on the customer home screen until a
--     SUPER_ADMIN approves them in Marketing > Banner Video Approvals
--
-- NOTE: the API side of this ships with the same release. Running the SQL
-- alone marks the rows but the running backend will keep serving the images
-- until the new build is deployed.
-- ============================================================================

BEGIN;

-- --- V132: banner video --------------------------------------------------
ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS video_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS video_thumbnail_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS video_status VARCHAR(20),
    ADD COLUMN IF NOT EXISTS video_review_note TEXT,
    ADD COLUMN IF NOT EXISTS video_reviewed_by VARCHAR(100),
    ADD COLUMN IF NOT EXISTS video_reviewed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS video_submitted_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_promotions_video_status
    ON promotions (video_status)
    WHERE video_url IS NOT NULL;

-- --- V133: banner image --------------------------------------------------
ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS image_status VARCHAR(20),
    ADD COLUMN IF NOT EXISTS image_review_note TEXT,
    ADD COLUMN IF NOT EXISTS image_reviewed_by VARCHAR(100),
    ADD COLUMN IF NOT EXISTS image_reviewed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS image_submitted_at TIMESTAMP;

-- Platform/admin banners (no shop) were created by an approver: keep them live.
UPDATE promotions
   SET image_status = 'APPROVED',
       image_reviewed_by = 'system (pre-existing admin banner)',
       image_reviewed_at = NOW(),
       image_submitted_at = COALESCE(updated_at, created_at, NOW())
 WHERE image_url IS NOT NULL
   AND image_url <> ''
   AND shop_id IS NULL
   AND image_status IS NULL;

-- Shop-owner banners nobody ever approved -> back in the queue, off the app.
UPDATE promotions
   SET image_status = 'PENDING',
       image_submitted_at = COALESCE(updated_at, created_at, NOW())
 WHERE image_url IS NOT NULL
   AND image_url <> ''
   AND shop_id IS NOT NULL
   AND image_status IS NULL;

CREATE INDEX IF NOT EXISTS idx_promotions_image_status
    ON promotions (image_status)
    WHERE image_url IS NOT NULL;

COMMIT;

-- --- What you will see in the approvals queue ------------------------------
SELECT COALESCE(image_status, 'no image')  AS image_review,
       COALESCE(video_status, 'no video')  AS video_review,
       CASE WHEN shop_id IS NULL THEN 'platform' ELSE 'shop owner' END AS source,
       COUNT(*)
  FROM promotions
 WHERE image_url IS NOT NULL OR video_url IS NOT NULL
 GROUP BY 1, 2, 3
 ORDER BY 3, 1, 2;
