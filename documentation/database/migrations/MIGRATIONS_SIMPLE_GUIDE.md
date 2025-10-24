# Database Migrations - SIMPLE GUIDE

## TL;DR - 3 Easy Steps ⚡

```bash
# Step 1: Create migration file
create-migration.bat "Add user status"

# Step 2: Add your SQL to the file (it will open automatically)
ALTER TABLE users ADD COLUMN status VARCHAR(50);

# Step 3: Commit and push
git add backend/src/main/resources/db/migration/*.sql
git commit -m "Migration: Add user status"
git push
```

**DONE! Production will update automatically when deployed! ✅**

---

## How It Works (No Manual Work!)

```
┌─────────────────┐
│  1. You Create  │
│  Migration File │──┐
└─────────────────┘  │
                     │
┌─────────────────┐  │
│   2. Push to    │◄─┘
│     GitHub      │──┐
└─────────────────┘  │
                     │
┌─────────────────┐  │
│  3. CI/CD Auto  │◄─┘
│     Deploys     │──┐
└─────────────────┘  │
                     │
┌─────────────────┐  │
│  4. Backend     │◄─┘
│  Starts & Auto  │
│  Runs Migration │ ✅ AUTOMATIC!
└─────────────────┘
```

---

## Quick Start

### Create New Migration (Automated)

```bash
# Windows
create-migration.bat "Add user profile pic"

# Linux/Mac
chmod +x create-migration.sh
./create-migration.sh "Add user profile pic"
```

The script will:
1. ✅ Find the next version number automatically
2. ✅ Create the migration file with template
3. ✅ Open it in your editor
4. ✅ Show you what to do next

### Example Output:
```
============================================
✅ Migration file created successfully!
============================================

File: V23__Add_user_profile_pic.sql
Location: backend/src/main/resources/db/migration/V23__Add_user_profile_pic.sql

Next steps:
1. Edit the file and add your SQL
2. Run backend to test locally
3. git add backend/src/main/resources/db/migration/V23__Add_user_profile_pic.sql
4. git commit -m "Migration: Add user profile pic"
5. git push (CI/CD will auto-apply to production)
```

---

## Real World Examples

### Example 1: Add Column

```bash
create-migration.bat "Add user phone number"
```

Edit the file:
```sql
-- Migration: Add user phone number
-- Version: V23

ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);
```

Commit:
```bash
git add backend/src/main/resources/db/migration/V23__Add_user_phone_number.sql
git commit -m "Migration: Add user phone number"
git push
```

**Production updates automatically on next deployment!** ✅

---

### Example 2: Create New Table

```bash
create-migration.bat "Create notifications table"
```

Edit the file:
```sql
-- Migration: Create notifications table
-- Version: V24

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
```

Commit and push:
```bash
git add backend/src/main/resources/db/migration/V24__Create_notifications_table.sql
git commit -m "Migration: Create notifications table"
git push
```

**Done! Production gets it automatically!** ✅

---

### Example 3: Update Data

```bash
create-migration.bat "Set default user role"
```

Edit the file:
```sql
-- Migration: Set default user role
-- Version: V25

UPDATE users SET role = 'CUSTOMER' WHERE role IS NULL;
ALTER TABLE users ALTER COLUMN role SET NOT NULL;
```

Commit and push - **automatic deployment!** ✅

---

## What Happens in Production?

### Automatic Flow:

1. **You push code** → GitHub
2. **CI/CD builds** → Creates JAR with migration files
3. **Backend deploys** → New JAR on server
4. **Backend starts** → Spring Boot runs Flyway
5. **Flyway checks** → "V23 not applied yet? Let me run it!"
6. **Migration runs** → Production database updated
7. **App continues** → Starts normally

**You do NOTHING manually in production!** 🎉

---

## Frequently Asked Questions

### Q: Do I need to run SQL manually in production?
**A: NO!** Flyway does it automatically when backend starts.

### Q: How does production know about my changes?
**A: The migration files are in your JAR. When backend starts, Flyway sees them and runs them automatically.**

### Q: What if migration fails in production?
**A: Create a new migration (V24) to fix it. Never modify old migrations.**

### Q: Can I undo a migration?
**A: Create a new "rollback" migration that reverses the changes.**

Example:
```sql
-- V24__Rollback_user_status.sql
ALTER TABLE users DROP COLUMN IF EXISTS status;
```

### Q: How do I know if a migration ran in production?
**A: Check the flyway_schema_history table:**
```sql
SELECT version, description, installed_on, success
FROM flyway_schema_history
ORDER BY installed_rank DESC;
```

---

## Common Patterns

### Safe Column Addition
```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='users' AND column_name='avatar'
    ) THEN
        ALTER TABLE users ADD COLUMN avatar VARCHAR(500);
    END IF;
END $$;
```

### Add Index
```sql
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
```

### Modify Column
```sql
ALTER TABLE shops ALTER COLUMN name TYPE VARCHAR(500);
```

### Add Foreign Key
```sql
ALTER TABLE orders
ADD CONSTRAINT fk_order_shop
FOREIGN KEY (shop_id) REFERENCES shops(id);
```

---

## Summary

### Your Workflow:
```bash
1. create-migration.bat "Your change"
2. Edit SQL file (opens automatically)
3. git add + commit + push
4. ✅ DONE! Production updates automatically!
```

### No Manual Steps:
- ❌ No SSH to production
- ❌ No manual SQL execution
- ❌ No database scripts to run
- ✅ Everything is automatic!

---

## Quick Commands

```bash
# Create migration
create-migration.bat "Add user bio"

# Test locally (run backend)
cd backend && mvn spring-boot:run

# Check migration status locally
psql -U postgres -d shop_management_db -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"

# Commit
git add backend/src/main/resources/db/migration/*.sql
git commit -m "Migration: Add user bio"
git push

# That's it! Production updates automatically! ✅
```

---

## Remember

**Database migrations = Code**
- Version controlled in Git ✅
- Tested locally ✅
- Automatically deployed ✅
- No manual production work ✅

**The whole point of migrations is to AVOID manual SQL in production!** 🎯
