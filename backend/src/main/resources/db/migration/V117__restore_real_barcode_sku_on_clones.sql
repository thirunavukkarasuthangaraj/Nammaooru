-- Category-change clones previously appended -COPY/-COPY-n to the real SKU.
-- The SKU is used for scanning, so shop-exclusive clones must retain the real
-- value. Shared catalog rows remain globally unique; duplicate usage inside a
-- single shop is rejected by the preflight check and application validation.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT sp.shop_id,
                   LOWER(regexp_replace(mp.sku, '(-COPY(-[0-9]+)?)+$', '', 'gi')) AS normalized_sku
            FROM shop_products sp
            JOIN master_products mp ON mp.id = sp.master_product_id
            WHERE mp.sku IS NOT NULL AND BTRIM(mp.sku) <> ''
            GROUP BY sp.shop_id,
                     LOWER(regexp_replace(mp.sku, '(-COPY(-[0-9]+)?)+$', '', 'gi'))
            HAVING COUNT(*) > 1
        ) duplicates
    ) THEN
        RAISE EXCEPTION
            'Cannot remove COPY suffixes: normalized duplicate SKUs exist within at least one shop';
    END IF;
END $$;

-- Suffixed rows are shop-specific clones, not shared catalog records.
UPDATE master_products
SET is_global = FALSE
WHERE sku ~* '(-COPY(-[0-9]+)?)+$';

-- Hibernate created the old one-column UNIQUE constraint with generated names
-- such as uk_4mr2q9tc8gyymy9pind6uwg8. Remove only UNIQUE constraints/indexes
-- whose definition is exactly the master_products SKU column.
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = current_schema()
          AND t.relname = 'master_products'
          AND c.contype = 'u'
          AND pg_get_constraintdef(c.oid) ~* '^UNIQUE \(sku\)'
    LOOP
        EXECUTE format('ALTER TABLE %I.master_products DROP CONSTRAINT %I',
                       current_schema(), rec.conname);
    END LOOP;

    FOR rec IN
        SELECT i.relname AS index_name
        FROM pg_index x
        JOIN pg_class t ON t.oid = x.indrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_class i ON i.oid = x.indexrelid
        WHERE n.nspname = current_schema()
          AND t.relname = 'master_products'
          AND x.indisunique
          AND NOT x.indisprimary
          AND pg_get_indexdef(x.indexrelid) ~* '\(sku\)( WHERE|$)'
          AND i.relname <> 'uk_master_products_global_sku'
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I.%I', current_schema(), rec.index_name);
    END LOOP;
END $$;

UPDATE master_products
SET sku = regexp_replace(sku, '(-COPY(-[0-9]+)?)+$', '', 'gi')
WHERE sku ~* '(-COPY(-[0-9]+)?)+$';

CREATE UNIQUE INDEX IF NOT EXISTS uk_master_products_global_sku
    ON master_products (sku)
    WHERE COALESCE(is_global, TRUE) = TRUE;
