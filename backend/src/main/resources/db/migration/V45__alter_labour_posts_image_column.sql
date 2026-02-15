-- Rename image_url to image_urls and increase length for up to 3 comma-separated URLs
ALTER TABLE labour_posts RENAME COLUMN image_url TO image_urls;
ALTER TABLE labour_posts ALTER COLUMN image_urls TYPE VARCHAR(1500);
