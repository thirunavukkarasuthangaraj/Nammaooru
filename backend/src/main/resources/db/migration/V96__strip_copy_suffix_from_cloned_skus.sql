-- Cloned master products (created when a shop changes the category of a shared
-- catalog product) were given an internal "-COPY"/"-COPY-n" SKU suffix to satisfy
-- the unique constraint on master_products.sku. Strip the suffix wherever the
-- plain code is free (original was deleted or never conflicted). Rows whose
-- original still owns the plain code must keep the suffix in the DB - the API
-- now hides it from every shop-facing view instead (SkuUtil.displaySku).
UPDATE master_products mp
SET sku = regexp_replace(mp.sku, '-COPY(-[0-9]+)?$', '')
WHERE mp.sku ~ '-COPY(-[0-9]+)?$'
  AND NOT EXISTS (
      SELECT 1 FROM master_products o
      WHERE o.sku = regexp_replace(mp.sku, '-COPY(-[0-9]+)?$', '')
  )
  -- when several clones strip to the same plain code, rename only one of them
  AND mp.id = (
      SELECT MIN(o2.id) FROM master_products o2
      WHERE o2.sku ~ '-COPY(-[0-9]+)?$'
        AND regexp_replace(o2.sku, '-COPY(-[0-9]+)?$', '')
            = regexp_replace(mp.sku, '-COPY(-[0-9]+)?$', '')
  );
