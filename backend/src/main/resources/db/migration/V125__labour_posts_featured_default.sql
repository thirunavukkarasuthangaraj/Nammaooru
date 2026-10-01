-- Featured labour posts are sorted to the top of the public listing.
-- The column was added by ddl-auto before Flyway, so legacy rows may hold NULL.
UPDATE labour_posts SET featured = FALSE WHERE featured IS NULL;
ALTER TABLE labour_posts ALTER COLUMN featured SET DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_labour_posts_featured_status_created
    ON labour_posts (featured, status, created_at DESC);
