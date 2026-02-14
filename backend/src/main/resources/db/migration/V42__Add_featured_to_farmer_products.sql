-- Add featured flag for promoted farmer product posts
ALTER TABLE farmer_products ADD COLUMN featured BOOLEAN DEFAULT FALSE;

-- Index for efficient featured post queries
CREATE INDEX idx_farmer_products_featured_status ON farmer_products (featured, status);
