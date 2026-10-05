-- Promotion banner video for the customer home "SPECIAL OFFERS" carousel.
--
-- A promotion can carry a short video that plays in place of its banner image.
-- Shop owners may upload one, but it only reaches customers once a SUPER_ADMIN
-- approves it, so video_url alone is never enough to show it - the app is only
-- ever handed a video whose video_status is APPROVED.

ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS video_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS video_thumbnail_url VARCHAR(500),
    -- PENDING / APPROVED / REJECTED; NULL means no video has ever been attached
    ADD COLUMN IF NOT EXISTS video_status VARCHAR(20),
    ADD COLUMN IF NOT EXISTS video_review_note TEXT,
    ADD COLUMN IF NOT EXISTS video_reviewed_by VARCHAR(100),
    ADD COLUMN IF NOT EXISTS video_reviewed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS video_submitted_at TIMESTAMP;

-- The approval queue reads "every promotion waiting on review"; without this it
-- is a full scan of promotions on every load of the admin screen.
CREATE INDEX IF NOT EXISTS idx_promotions_video_status
    ON promotions (video_status)
    WHERE video_url IS NOT NULL;
