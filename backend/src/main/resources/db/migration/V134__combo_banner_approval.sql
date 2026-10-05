-- Combos need SUPER_ADMIN approval before they appear on the customer home
-- "SPECIAL OFFERS" carousel - same rule as promotion banners (V132/V133).
--
-- Combos are always shop-owner content (every combo belongs to a shop), and
-- until now /customer/combos fed every active one straight onto the home
-- screen with no review at all.

ALTER TABLE product_combos
    ADD COLUMN IF NOT EXISTS banner_status VARCHAR(20),
    ADD COLUMN IF NOT EXISTS banner_review_note TEXT,
    ADD COLUMN IF NOT EXISTS banner_reviewed_by VARCHAR(100),
    ADD COLUMN IF NOT EXISTS banner_reviewed_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS banner_submitted_at TIMESTAMP;

-- Every existing combo goes into the queue: none of them was ever approved by
-- anyone, so they drop off the home screen until a SUPER_ADMIN looks at them.
-- They stay visible on their own shop's page - the deal itself is still valid.
UPDATE product_combos
   SET banner_status = 'PENDING',
       banner_submitted_at = COALESCE(updated_at, created_at, NOW())
 WHERE banner_status IS NULL;

CREATE INDEX IF NOT EXISTS idx_product_combos_banner_status
    ON product_combos (banner_status);
