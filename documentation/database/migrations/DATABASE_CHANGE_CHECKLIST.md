# ✅ DATABASE CHANGE CHECKLIST

**Use this checklist EVERY TIME you modify a database table!**

---

## 📋 THE CHECKLIST

### ☑️ Step 1: Make the Change (Production/Local)
- [ ] Added new column to database
- [ ] Modified existing column
- [ ] Created new table
- [ ] Added index
- [ ] Added foreign key
- [ ] Updated data

**Document what you changed:**
- Table name: `___________`
- Column name: `___________`
- Change type: `___________`
- Column type: `___________`

---

### ☑️ Step 2: Create Migration File

Run command:
```bash
create-migration.bat "Your change description"
```

Example:
```bash
create-migration.bat "Add phone column to users table"
```

**Result:** Creates migration file automatically
- [ ] Migration file created
- [ ] File opened in editor

---

### ☑️ Step 3: Write Safe SQL

Use this template in your migration file:

```sql
-- Migration: [Your change description]
-- Version: V[auto-generated]
-- Date: [auto-filled]

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'YOUR_TABLE'
        AND column_name = 'YOUR_COLUMN'
    ) THEN
        ALTER TABLE YOUR_TABLE ADD COLUMN YOUR_COLUMN TYPE;
        RAISE NOTICE 'Added YOUR_COLUMN to YOUR_TABLE';
    ELSE
        RAISE NOTICE 'YOUR_COLUMN already exists, skipping';
    END IF;
END $$;
```

Checklist:
- [ ] Replaced YOUR_TABLE with actual table name
- [ ] Replaced YOUR_COLUMN with actual column name
- [ ] Replaced TYPE with actual data type
- [ ] Added IF NOT EXISTS check
- [ ] Saved the file

---

### ☑️ Step 4: Test Locally

```bash
cd backend
mvn spring-boot:run
```

Check logs for:
- [ ] "Migrating schema to version X"
- [ ] "Successfully applied 1 migration"
- [ ] No errors in console

Verify in database:
```sql
-- Check migration applied
SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 1;

-- Check column exists
\d your_table
```

- [ ] Migration shows in flyway_schema_history
- [ ] Column exists in table
- [ ] Application started successfully

---

### ☑️ Step 5: Commit and Push

```bash
git add backend/src/main/resources/db/migration/V*.sql
git commit -m "Migration: [Your change description]"
git push
```

- [ ] Migration file added to git
- [ ] Committed with clear message
- [ ] Pushed to GitHub

---

### ☑️ Step 6: Wait for Deployment

**Automatic CI/CD will:**
- [ ] Build backend with migration
- [ ] Deploy to production
- [ ] Auto-apply migration on startup

**Verify after deployment:**
- [ ] Check backend logs for successful migration
- [ ] Test the feature that uses the new column

---

## 🚀 QUICK REFERENCE

### Common Change Types:

#### ✅ Add Column
```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='phone') THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR(20);
    END IF;
END $$;
```

#### ✅ Add Multiple Columns
```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='first_name') THEN
        ALTER TABLE users ADD COLUMN first_name VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='users' AND column_name='last_name') THEN
        ALTER TABLE users ADD COLUMN last_name VARCHAR(100);
    END IF;
END $$;
```

#### ✅ Create Table
```sql
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### ✅ Add Index
```sql
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

#### ✅ Add Foreign Key
```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_name='fk_orders_user') THEN
        ALTER TABLE orders ADD CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id) REFERENCES users(id);
    END IF;
END $$;
```

#### ✅ Modify Column Type
```sql
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name='products' AND column_name='price'
               AND data_type='integer') THEN
        ALTER TABLE products ALTER COLUMN price TYPE DECIMAL(10,2);
    END IF;
END $$;
```

---

## ⚠️ IMPORTANT REMINDERS

### ✅ DO:
- [ ] Always use IF NOT EXISTS checks
- [ ] Test locally before pushing
- [ ] Document why you made the change
- [ ] Keep migration files small and focused
- [ ] Use clear, descriptive names

### ❌ DON'T:
- [ ] Never modify existing migration files
- [ ] Never delete migration files
- [ ] Never run manual SQL in production
- [ ] Don't skip testing locally
- [ ] Don't mix unrelated changes

---

## 📊 TRACKING YOUR CHANGES

### Before Creating Migration:

Fill this out:
```
Date: __________
What Changed: __________
Table: __________
Column(s): __________
Type: __________
Reason: __________
Production Already Has It: [ ] Yes [ ] No
```

### After Migration Applied:

```
Migration Version: V__
Applied Locally: [ ] Yes - Date: ____
Pushed to Git: [ ] Yes - Commit: ____
Applied in Production: [ ] Yes - Date: ____
Verified Working: [ ] Yes
```

---

## 🔍 TROUBLESHOOTING

### Migration Failed Locally?
```sql
-- Check what failed
SELECT * FROM flyway_schema_history WHERE success = false;

-- Check actual error
-- Look at backend console logs
```

**Fix:**
1. Don't modify failed migration file
2. Create new migration (V24) to fix the issue
3. Test again

### Migration Skipped in Production?
**This is NORMAL if:**
- Column already exists (you added it manually)
- IF NOT EXISTS check found it
- Migration marked as success ✅

### Column Missing After Migration?
**Check:**
```sql
-- Is migration applied?
SELECT * FROM flyway_schema_history WHERE version = '23';

-- Is column there?
SELECT column_name FROM information_schema.columns
WHERE table_name = 'your_table';
```

---

## 📝 EXAMPLE WORKFLOW

### Scenario: Add `delivery_notes` column to `orders` table

**Step 1: Document**
```
Table: orders
Column: delivery_notes
Type: TEXT
Reason: Store special delivery instructions
Already in Prod: No
```

**Step 2: Create Migration**
```bash
create-migration.bat "Add delivery notes to orders"
```

**Step 3: Write SQL**
```sql
-- V24__Add_delivery_notes_to_orders.sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders'
        AND column_name = 'delivery_notes'
    ) THEN
        ALTER TABLE orders ADD COLUMN delivery_notes TEXT;
        RAISE NOTICE 'Added delivery_notes column';
    END IF;
END $$;
```

**Step 4: Test**
```bash
mvn spring-boot:run
# Check logs: "Successfully applied 1 migration" ✅
```

**Step 5: Commit**
```bash
git add backend/src/main/resources/db/migration/V24__Add_delivery_notes_to_orders.sql
git commit -m "Migration: Add delivery notes to orders table"
git push
```

**Step 6: Done!**
```
✅ Local: Has delivery_notes column
✅ Production: Will get it on next deployment
✅ All synced automatically!
```

---

## 🎯 SUMMARY

**Every database change:**
1. ✅ Document what changed
2. ✅ Run `create-migration.bat "description"`
3. ✅ Write safe SQL with IF NOT EXISTS
4. ✅ Test locally (`mvn spring-boot:run`)
5. ✅ Commit and push
6. ✅ CI/CD deploys automatically

**That's it! Follow this checklist every time!** 🚀

---

## 📚 QUICK LINKS

- **Full Guide:** `DATABASE_MIGRATION_GUIDE.md`
- **Simple Guide:** `MIGRATIONS_SIMPLE_GUIDE.md`
- **Handling Prod Changes:** `HANDLING_EXISTING_PROD_CHANGES.md`
- **Examples:** `EXAMPLE_SAFE_MIGRATION.sql`

---

## ✨ PRO TIPS

1. **Create migration immediately after changing database**
   - Don't wait! Do it while it's fresh in your mind

2. **Always test locally first**
   - Catch errors before they reach production

3. **Use descriptive names**
   - Good: `V23__Add_user_phone_verification`
   - Bad: `V23__fix_users`

4. **One logical change per migration**
   - Don't mix "add phone" with "create notifications table"

5. **Keep a change log**
   - Document major database changes in a CHANGELOG.md

---

**Print this checklist and keep it handy!** 📌
