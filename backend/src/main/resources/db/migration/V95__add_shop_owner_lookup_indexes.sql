-- Speeds up the shop-by-owner lookup (ShopService.getShopByOwner) that runs on
-- every /api/shop-products/** request (payment gate filter + controller), and
-- the default updatedAt-sorted product listing used by POS/my-products paging.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_created_by ON shops(created_by);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_shop_updated_at ON shop_products(shop_id, updated_at);

COMMIT;
