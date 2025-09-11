# Manual Database Cleanup Commands

## Step 1: Check Current Data Count
Copy and paste this SQL to see what data exists:

```sql
SELECT 
    'master_products' as table_name, COUNT(*) as count FROM master_products
UNION ALL
SELECT 
    'shop_products' as table_name, COUNT(*) as count FROM shop_products
UNION ALL
SELECT 
    'shops' as table_name, COUNT(*) as count FROM shops
UNION ALL
SELECT 
    'shop_product_images' as table_name, COUNT(*) as count FROM shop_product_images
UNION ALL
SELECT 
    'master_product_images' as table_name, COUNT(*) as count FROM master_product_images;
```

## Step 2: Execute Cleanup (Run these commands ONE BY ONE)

### Delete Images First (no dependencies)
```sql
DELETE FROM shop_product_images;
```

```sql
DELETE FROM master_product_images;
```

```sql
DELETE FROM shop_images;
```

```sql
DELETE FROM shop_documents;
```

### Delete Shop Products (pricing data)
```sql
DELETE FROM shop_products;
```

### Delete Shops
```sql
DELETE FROM shops;
```

### Delete Master Products
```sql
DELETE FROM master_products;
```

## Step 3: Reset ID Sequences
```sql
SELECT setval('shops_id_seq', 1, false);
SELECT setval('master_products_id_seq', 1, false);
SELECT setval('shop_products_id_seq', 1, false);
SELECT setval('shop_product_images_id_seq', 1, false);
SELECT setval('master_product_images_id_seq', 1, false);
SELECT setval('shop_images_id_seq', 1, false);
SELECT setval('shop_documents_id_seq', 1, false);
```

## Step 4: Verify Cleanup (All should return 0)
```sql
SELECT 
    'master_products' as table_name, COUNT(*) as count FROM master_products
UNION ALL
SELECT 
    'shop_products' as table_name, COUNT(*) as count FROM shop_products
UNION ALL
SELECT 
    'shops' as table_name, COUNT(*) as count FROM shops
UNION ALL
SELECT 
    'shop_product_images' as table_name, COUNT(*) as count FROM shop_product_images
UNION ALL
SELECT 
    'master_product_images' as table_name, COUNT(*) as count FROM master_product_images;
```

## Instructions:
1. Open your PostgreSQL client (pgAdmin, DBeaver, etc.)
2. Connect to `shop_management` database  
3. Copy each SQL block above and execute them one by one
4. After Step 4, all counts should be 0

This will completely clean your database and reset it for fresh shop and product creation!