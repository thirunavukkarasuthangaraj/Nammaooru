-- Add Tamil name column to master_products table
ALTER TABLE master_products
ADD COLUMN name_tamil VARCHAR(255);

-- Add comment to explain the column
COMMENT ON COLUMN master_products.name_tamil IS 'Product name in Tamil language';
