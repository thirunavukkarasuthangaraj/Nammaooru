-- Image-only banners on the customer home "SPECIAL OFFERS" carousel.
--
-- Until now every row in promotions was a promo CODE: code / type /
-- discount_value were NOT NULL and the carousel card always carried a code.
-- An admin now also needs plain artwork on the carousel (a festival greeting,
-- a "we deliver to X now" announcement) with no code behind it. Rather than a
-- second table and a second approval queue, such a banner is a promotions row
-- with banner_type = 'IMAGE_BANNER' and no code/type/discount_value; the
-- existing image approval trail (V133) and the admin review page apply to it
-- unchanged.
--
-- The promotions table itself pre-dates Flyway (Hibernate ddl-auto created it),
-- so the NOT NULLs below are plain column constraints, not named ones.

ALTER TABLE promotions
    ADD COLUMN IF NOT EXISTS banner_type VARCHAR(20) NOT NULL DEFAULT 'PROMO_CODE',
    -- Optional tap-through target for an image banner (deep link or https URL).
    ADD COLUMN IF NOT EXISTS link_url VARCHAR(500);

-- An image banner has no code, no discount type and no discount value.
-- (The UNIQUE index on code is unaffected: Postgres treats NULLs as distinct.)
ALTER TABLE promotions ALTER COLUMN code DROP NOT NULL;
ALTER TABLE promotions ALTER COLUMN type DROP NOT NULL;
ALTER TABLE promotions ALTER COLUMN discount_value DROP NOT NULL;

-- ...but a promo code must still have all three. Enforced here so a bug in any
-- writer (admin controller, shop-owner controller, a future import) cannot
-- produce a code-less promo code that the app would try to redeem.
ALTER TABLE promotions DROP CONSTRAINT IF EXISTS chk_promotions_banner_type_fields;
ALTER TABLE promotions
    ADD CONSTRAINT chk_promotions_banner_type_fields
    CHECK (
        banner_type = 'IMAGE_BANNER'
        OR (code IS NOT NULL AND type IS NOT NULL AND discount_value IS NOT NULL)
    );

-- The customer feed and the admin list both read "active rows of one kind".
CREATE INDEX IF NOT EXISTS idx_promotions_banner_type_status
    ON promotions (banner_type, status);
