# Handling Database Changes Already in Production

## Your Situation

You manually added a column to production database. Now you need to create a migration so:
- ✅ Local database gets the change
- ✅ Staging gets the change
- ✅ Production won't break (column already exists)
- ✅ Everything stays in sync

---

## Step-by-Step Solution

### Step 1: Create Migration File

```bash
create-migration.bat "Add your_column_name to your_table"
```

Example:
```bash
create-migration.bat "Add status column to orders"
```

This creates: `backend/src/main/resources/db/migration/V23__Add_status_column_to_orders.sql`

---

### Step 2: Write Safe SQL

Edit the created file with this pattern:

```sql
-- Migration: Add status column to orders
-- Version: V23
-- Note: This column already exists in production

DO $$
BEGIN
    -- Check if column exists
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'orders'          -- Your table name
        AND column_name = 'status'           -- Your column name
    ) THEN
        -- Add the column (matches what you did in prod)
        ALTER TABLE orders ADD COLUMN status VARCHAR(50) DEFAULT 'pending';

        -- Add index if you created one in prod
        CREATE INDEX idx_orders_status ON orders(status);

        RAISE NOTICE 'Added status column';
    ELSE
        RAISE NOTICE 'Status column already exists, skipping';
    END IF;
END $$;

-- Update existing rows if needed
UPDATE orders SET status = 'pending' WHERE status IS NULL;
```

**Important:** Make the migration match EXACTLY what you did in production!

---

### Step 3: Test Locally

```bash
# Run your backend
cd backend
mvn spring-boot:run
```

**Check logs for:**
```
Migrating schema to version "23 - Add status column to orders"
Successfully applied 1 migration
```

**Verify in database:**
```sql
-- Check migration was applied
SELECT * FROM flyway_schema_history WHERE version = '23';

-- Check column exists
\d orders
-- Should show 'status' column
```

---

### Step 4: Commit and Push

```bash
git add backend/src/main/resources/db/migration/V23__*.sql
git commit -m "Migration: Add status column to orders (already in prod)"
git push
```

---

### Step 5: What Happens in Each Environment

#### Production (column already exists):
```
1. Flyway checks: "Does status column exist?"
2. Answer: YES (you added it manually)
3. Action: Skips ALTER TABLE
4. Result: ✅ No error, migration marked as applied
```

#### Local/Staging (column doesn't exist):
```
1. Flyway checks: "Does status column exist?"
2. Answer: NO
3. Action: Runs ALTER TABLE, adds column
4. Result: ✅ Column added, migration marked as applied
```

#### All Environments:
```
✅ Database structure is now identical everywhere
✅ Migration history is synchronized
✅ Future migrations will work correctly
```

---

## Real Example from Your Project

Let's say you manually added `delivery_fee` column to `orders` table in production:

### Create Migration:
```bash
create-migration.bat "Add delivery fee to orders"
```

### Write Safe SQL:
```sql
-- V24__Add_delivery_fee_to_orders.sql

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders' AND column_name = 'delivery_fee'
    ) THEN
        ALTER TABLE orders ADD COLUMN delivery_fee DECIMAL(10,2) DEFAULT 0.00;

        RAISE NOTICE 'Added delivery_fee column to orders';
    ELSE
        RAISE NOTICE 'delivery_fee column already exists';
    END IF;
END $$;

-- Set default for existing orders
UPDATE orders SET delivery_fee = 0.00 WHERE delivery_fee IS NULL;
```

### Result:
- ✅ Production: Skips (already has column)
- ✅ Local: Adds column
- ✅ All synced!

---

## Common Patterns

### Pattern 1: Add Single Column
```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'your_table'
        AND column_name = 'your_column'
    ) THEN
        ALTER TABLE your_table
        ADD COLUMN your_column VARCHAR(255) DEFAULT 'default_value';
    END IF;
END $$;
```

### Pattern 2: Add Multiple Columns
```sql
DO $$
BEGIN
    -- Column 1
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'first_name') THEN
        ALTER TABLE users ADD COLUMN first_name VARCHAR(100);
    END IF;

    -- Column 2
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'users' AND column_name = 'last_name') THEN
        ALTER TABLE users ADD COLUMN last_name VARCHAR(100);
    END IF;
END $$;
```

### Pattern 3: Add Column with Index
```sql
DO $$
BEGIN
    -- Add column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'sku'
    ) THEN
        ALTER TABLE products ADD COLUMN sku VARCHAR(50) UNIQUE;
    END IF;

    -- Add index (only if not exists)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'products' AND indexname = 'idx_products_sku'
    ) THEN
        CREATE INDEX idx_products_sku ON products(sku);
    END IF;
END $$;
```

### Pattern 4: Add Foreign Key
```sql
DO $$
BEGIN
    -- Add column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders' AND column_name = 'shop_id'
    ) THEN
        ALTER TABLE orders ADD COLUMN shop_id BIGINT;
    END IF;

    -- Add foreign key constraint
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_orders_shop'
    ) THEN
        ALTER TABLE orders
        ADD CONSTRAINT fk_orders_shop
        FOREIGN KEY (shop_id) REFERENCES shops(id);
    END IF;
END $$;
```

### Pattern 5: Modify Column Type (Careful!)
```sql
-- This one requires checking current type first
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products'
        AND column_name = 'price'
        AND data_type = 'integer'  -- Current type
    ) THEN
        -- Convert integer to decimal
        ALTER TABLE products
        ALTER COLUMN price TYPE DECIMAL(10,2);

        RAISE NOTICE 'Changed price from integer to decimal';
    ELSE
        RAISE NOTICE 'Price already correct type';
    END IF;
END $$;
```

---

## Troubleshooting

### Q: Migration fails in production?
**A:** Check what you actually did in production and make migration match EXACTLY.

```sql
-- Check column details in production
SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'your_table' AND column_name = 'your_column';
```

### Q: Migration applied but column missing locally?
**A:** Check flyway_schema_history:

```sql
SELECT version, description, installed_on, success
FROM flyway_schema_history
WHERE version = '23';
```

If success = true but column missing, the IF condition might be wrong.

### Q: Want to undo the migration?
**A:** Create a new migration to remove it:

```sql
-- V25__Remove_status_column.sql
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders' AND column_name = 'status'
    ) THEN
        ALTER TABLE orders DROP COLUMN status;
    END IF;
END $$;
```

---

## Best Practices

1. **Always check before adding:**
   ```sql
   IF NOT EXISTS (SELECT 1 FROM information_schema.columns ...)
   ```

2. **Match production exactly:**
   - Same column type
   - Same default value
   - Same constraints
   - Same indexes

3. **Test locally first:**
   ```bash
   mvn spring-boot:run
   # Check logs
   # Verify in database
   ```

4. **Document what you did:**
   ```sql
   -- Migration: Add status column
   -- Note: This column was manually added to production on 2025-10-22
   -- Reason: Emergency fix for order tracking
   ```

5. **One migration per logical change:**
   - Don't mix unrelated changes
   - Easier to debug if something fails

---

## Summary

**Your Workflow:**
```bash
1. create-migration.bat "Add your change"
2. Write safe SQL with IF NOT EXISTS
3. Test locally (mvn spring-boot:run)
4. git add + commit + push
5. ✅ Production: Skips (already has it)
6. ✅ Local/Staging: Applies change
7. ✅ All environments in sync!
```

**Key Point:** The migration is "idempotent" - safe to run multiple times, won't break if change already exists!

---

## Need Help?

Check:
- `EXAMPLE_SAFE_MIGRATION.sql` - Full examples
- `MIGRATIONS_SIMPLE_GUIDE.md` - Quick reference
- `DATABASE_MIGRATION_GUIDE.md` - Complete guide
