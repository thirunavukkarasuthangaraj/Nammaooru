-- Speeds up the shop-by-owner lookup (ShopService.getShopByOwner) that runs on
-- every /api/shop-products/** request (payment gate filter + controller), and
-- the default updatedAt-sorted product listing used by POS/my-products paging.
--
-- Plain CREATE INDEX (not CONCURRENTLY): this project's Flyway runs each
-- migration inside a transaction (the default, unmodified here), and Postgres
-- rejects CREATE INDEX CONCURRENTLY inside a transaction block - that combo
-- crashed the app on startup and left a failed migration record behind.

CREATE INDEX IF NOT EXISTS idx_shops_created_by ON shops(created_by);
CREATE INDEX IF NOT EXISTS idx_shop_products_shop_updated_at ON shop_products(shop_id, updated_at);
