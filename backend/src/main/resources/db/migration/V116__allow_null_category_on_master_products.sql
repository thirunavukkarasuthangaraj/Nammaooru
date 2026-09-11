-- Deleting a category is supposed to detach its products (they stay listed as
-- "uncategorized") instead of blocking the delete - see
-- ProductCategoryService.deleteCategory / MasterProductRepository
-- .detachProductsFromCategory, and getUncategorizedProductCount() which already
-- assumes "no category" means category_id IS NULL. But category_id was still
-- NOT NULL at the database level, so that detach UPDATE would fail whenever it
-- actually ran, making it unsafe to delete any category that has products.
ALTER TABLE master_products ALTER COLUMN category_id DROP NOT NULL;
