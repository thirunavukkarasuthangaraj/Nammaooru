# Database Migration Guide - Flyway

## Overview

Your project uses **Flyway** for database version control. This ensures that database changes made locally are automatically applied to production during deployment.

---

## How It Works

### 1. **Local Development**
When you make database changes locally:
1. Create a new migration SQL file
2. Flyway applies it to your local database
3. Commit the file to git

### 2. **Production Deployment**
When you deploy (via CI/CD):
1. Backend JAR contains all migration files
2. On startup, Spring Boot runs Flyway
3. Flyway checks which migrations are already applied
4. Automatically applies new migrations
5. Production database is updated ✅

**No manual SQL execution needed in production!**

---

## Migration File Naming Convention

**Format:** `V{version}__{description}.sql`

```
V3__Create_Shop_Documents_Table.sql
V4__Create_Product_Tables.sql
V9__Add_Payment_Settlement_Tables.sql
V22__Fix_Product_Categories_Timestamps.sql
```

**Rules:**
- Start with `V` (uppercase)
- Version number (integer): `V3`, `V4`, `V22`, etc.
- Two underscores `__` after version
- Description with underscores: `Create_Shop_Documents_Table`
- Must be `.sql` file

**Version Numbers:**
- Must be unique
- Should be sequential (but gaps are OK)
- Use current highest version + 1
- Format: `V23`, `V24`, etc. (not V23.1 or V23_1)

---

## How to Create a New Migration

### Step 1: Find the Next Version Number

```bash
# List existing migrations
ls backend/src/main/resources/db/migration/

# Current highest: V22__Fix_Product_Categories_Timestamps.sql
# Next version: V23
```

### Step 2: Create New Migration File

**Location:** `backend/src/main/resources/db/migration/`

**Example 1: Add a new column**
```sql
-- File: V23__Add_user_profile_picture.sql

ALTER TABLE users
ADD COLUMN profile_picture_url VARCHAR(500);
```

**Example 2: Create a new table**
```sql
-- File: V24__Create_notifications_table.sql

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

**Example 3: Safe migration (checking if exists)**
```sql
-- File: V25__Add_shop_rating_safely.sql

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='shops' AND column_name='rating'
    ) THEN
        ALTER TABLE shops ADD COLUMN rating DECIMAL(3,2) DEFAULT 0.0;
    END IF;
END $$;
```

### Step 3: Test Locally

```bash
# Run your Spring Boot application
cd backend
./mvnw spring-boot:run

# OR
java -jar target/shop-management-backend-1.0.0.jar
```

**Flyway will automatically:**
- Detect the new migration
- Apply it to your local database
- Create entry in `flyway_schema_history` table

**Check logs for:**
```
Migrating schema to version "23 - Add user profile picture"
Successfully applied 1 migration
```

### Step 4: Verify Migration

```bash
# Connect to local database
psql -U postgres -d shop_management_db

# Check if changes applied
\d users  -- Show users table structure
SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;
```

### Step 5: Commit and Push

```bash
git add backend/src/main/resources/db/migration/V23__Add_user_profile_picture.sql
git commit -m "Migration: Add user profile picture column"
git push
```

---

## Production Deployment Process

### Automatic Migration Flow

```
1. Code pushed to GitHub
   ↓
2. CI/CD builds backend JAR
   (contains all migration files)
   ↓
3. JAR deployed to production server
   ↓
4. Spring Boot starts
   ↓
5. Flyway checks flyway_schema_history table
   ↓
6. Flyway sees V23 not applied yet
   ↓
7. Flyway runs V23__Add_user_profile_picture.sql
   ↓
8. Production database updated ✅
   ↓
9. Application starts normally
```

**No manual intervention required!**

---

## Current Migration Files

```
V3__Create_Shop_Documents_Table.sql
V4__Create_Product_Tables.sql
V9__Add_Payment_Settlement_Tables.sql
V15__Create_delivery_fee_ranges_table.sql
V16__Drop_shop_delivery_fee_column.sql
V20251007111822__add_delivery_type.sql
V21__create_app_version_table.sql
V22__Fix_Product_Categories_Timestamps.sql
```

**Next available version: V23**

---

## Best Practices

### ✅ DO:

1. **Always use sequential version numbers**
   ```
   V23, V24, V25...
   ```

2. **Make migrations idempotent (safe to run multiple times)**
   ```sql
   -- Good: Checks before adding
   DO $$
   BEGIN
       IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                      WHERE table_name='users' AND column_name='status') THEN
           ALTER TABLE users ADD COLUMN status VARCHAR(50);
       END IF;
   END $$;
   ```

3. **Add descriptive comments**
   ```sql
   -- This migration adds user status tracking feature
   -- Created: 2025-10-22
   -- Related to: Issue #123
   ```

4. **Test on local database first**

5. **Use transactions for complex migrations**
   ```sql
   BEGIN;

   ALTER TABLE orders ADD COLUMN discount DECIMAL(10,2);
   UPDATE orders SET discount = 0.0 WHERE discount IS NULL;

   COMMIT;
   ```

### ❌ DON'T:

1. **Never modify existing migration files**
   - Once deployed, they're locked
   - Create a new migration to fix issues

2. **Never delete migration files**
   - Even old ones
   - They're part of your database history

3. **Don't use V999 for regular migrations**
   - Reserved for hotfixes/emergency patches
   - Use sequential numbers instead

4. **Avoid direct SQL in production**
   - Always use migration files
   - Ensures consistency across environments

---

## Checking Migration Status

### Local Database
```bash
psql -U postgres -d shop_management_db -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank;"
```

### Production Database (via SSH)
```bash
ssh your-server
psql -U postgres -d shop_management_db -c "SELECT version, description, installed_on FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 10;"
```

---

## Common Scenarios

### Adding a Column
```sql
-- V23__Add_user_phone_verified.sql
ALTER TABLE users ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;
UPDATE users SET phone_verified = FALSE WHERE phone_verified IS NULL;
```

### Modifying a Column
```sql
-- V24__Increase_shop_name_length.sql
ALTER TABLE shops ALTER COLUMN name TYPE VARCHAR(500);
```

### Creating an Index
```sql
-- V25__Add_orders_status_index.sql
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
```

### Adding Foreign Key
```sql
-- V26__Add_order_shop_fk.sql
ALTER TABLE orders
ADD CONSTRAINT fk_order_shop
FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE;
```

### Data Migration
```sql
-- V27__Migrate_old_user_types.sql
-- Convert old user_type values to new role system
UPDATE users SET role = 'SHOP_OWNER' WHERE user_type = 'owner';
UPDATE users SET role = 'CUSTOMER' WHERE user_type = 'customer';
UPDATE users SET role = 'DELIVERY_PARTNER' WHERE user_type = 'driver';
```

---

## Troubleshooting

### Migration Failed in Production

1. **Check logs:**
   ```bash
   journalctl -u your-app-service -n 100
   ```

2. **Check Flyway history:**
   ```sql
   SELECT * FROM flyway_schema_history WHERE success = FALSE;
   ```

3. **Fix the issue:**
   - Create a new migration (V28) to fix the problem
   - Don't modify the failed migration file

### Rolling Back a Migration

Flyway doesn't support automatic rollback. To rollback:

1. **Create a reverse migration:**
   ```sql
   -- V28__Rollback_user_status.sql
   ALTER TABLE users DROP COLUMN IF EXISTS status;
   ```

2. **Or manually fix in production:**
   ```sql
   -- Only in emergency, document everything
   ALTER TABLE users DROP COLUMN status;
   DELETE FROM flyway_schema_history WHERE version = '27';
   ```

---

## Summary

**Local Changes → Git → CI/CD → Auto-Deploy → Production Updated ✅**

1. Make DB changes locally
2. Create migration file: `V{next}__{description}.sql`
3. Test locally (Spring Boot auto-runs it)
4. Commit and push
5. CI/CD deploys
6. Flyway auto-applies to production

**No manual SQL needed in production!**

---

## Quick Reference

```bash
# Create new migration
cd backend/src/main/resources/db/migration/
# Find next version: V23, V24, etc.
# Create: V23__Your_Description.sql

# Test locally
cd backend
./mvnw spring-boot:run

# Commit
git add backend/src/main/resources/db/migration/V23__*.sql
git commit -m "Migration: Your description"
git push

# Production: Automatic! ✅
```

---

## Need Help?

- **Check migration status:** `SELECT * FROM flyway_schema_history;`
- **View migration logs:** Check Spring Boot startup logs
- **Flyway docs:** https://flywaydb.org/documentation/

---

**Remember:** Database migrations are code! They should be:
- Version controlled ✅
- Tested ✅
- Reviewed ✅
- Deployed automatically ✅
