-- Extend banner review from video-only to the banner IMAGE as well.
--
-- Before this, a shop owner's banner image went straight onto the customer
-- home banner with no review - only videos were gated. Now both assets carry
-- their own review state, and the customer APIs hand out neither until it is
-- APPROVED.

ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS image_status VARCHAR(20),
    ADD COLUMN IF NOT EXISTS image_review_note TEXT,
    ADD COLUMN IF NOT EXISTS image_reviewed_by VARCHAR(100),
    ADD COLUMN IF NOT EXISTS image_reviewed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS image_submitted_at TIMESTAMP;

-- Platform/admin promotions (no shop) were created by an approver in the first
-- place, so they stay live.
UPDATE promotions
   SET image_status = 'APPROVED',
       image_reviewed_by = 'system (pre-existing admin banner)',
       image_reviewed_at = NOW(),
       image_submitted_at = COALESCE(updated_at, created_at, NOW())
 WHERE image_url IS NOT NULL
   AND image_url <> ''
   AND shop_id IS NULL
   AND image_status IS NULL;

-- Shop-owner banners that pre-date this review step go back in the queue:
-- they were never approved by anyone, so they drop off the home banner until
-- a SUPER_ADMIN looks at them.
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
