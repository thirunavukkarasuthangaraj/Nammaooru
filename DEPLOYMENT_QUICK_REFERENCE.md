# 📋 DATABASE MIGRATION - QUICK REFERENCE

**One-page guide for deploying database changes**

---

## ⚡ QUICK WORKFLOW (5 MINUTES)

```bash
# 1. Create migration file (10 seconds)
create-migration.bat "Add column name"

# 2. Edit migration file - add safe SQL (2 minutes)
#    Use IF NOT EXISTS pattern (see templates below)

# 3. Preview what will deploy (5 seconds)
preview-migrations.bat

# 4. Validate for errors (5 seconds)
validate-migrations.bat

# 5. Test locally (30 seconds)
cd backend
mvn spring-boot:run
# Check logs: "Successfully applied 1 migration" ✅

# 6. Commit and push (30 seconds)
git add backend/src/main/resources/db/migration/*.sql
git commit -m "Migration: Add column name"
git push

# 7. Done! CI/CD will:
#    - Validate migrations
#    - Build backend
#    - Deploy to production
#    - Apply migrations automatically
```

---

## 📝 SQL TEMPLATES (Copy-Paste)

### Add Column
```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'TABLE_NAME'
        AND column_name = 'COLUMN_NAME'
    ) THEN
        ALTER TABLE TABLE_NAME ADD COLUMN COLUMN_NAME TYPE;
        RAISE NOTICE 'Added COLUMN_NAME to TABLE_NAME';
    END IF;
END $$;
```

### Create Table
```sql
CREATE TABLE IF NOT EXISTS table_name (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Add Index
```sql
CREATE INDEX IF NOT EXISTS idx_table_column
ON table_name(column_name);
```

### Add Foreign Key
```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_table_column'
    ) THEN
        ALTER TABLE table_name
        ADD CONSTRAINT fk_table_column
        FOREIGN KEY (column_id) REFERENCES other_table(id);
    END IF;
END $$;
```

---

## ✅ CHECKLIST

**Before Commit:**
- [ ] Created migration file with correct naming
- [ ] Used IF NOT EXISTS check
- [ ] Previewed migrations: `preview-migrations.bat`
- [ ] Validated migrations: `validate-migrations.bat`
- [ ] Tested locally: `mvn spring-boot:run`
- [ ] Migration shows "success" in logs

**Before Push:**
- [ ] All validations passed (0 errors)
- [ ] Backend builds successfully
- [ ] Local database has changes

**After Push:**
- [ ] Check GitHub Actions: https://github.com/your-repo/actions
- [ ] Watch for "✅ PRE-DEPLOYMENT VALIDATION PASSED"
- [ ] Monitor deployment progress
- [ ] Check backend logs for Flyway success

---

## 🛠️ COMMANDS REFERENCE

### Local Development
```bash
# Create migration
create-migration.bat "Description"

# Preview migrations
preview-migrations.bat

# Validate migrations
validate-migrations.bat

# Test backend
cd backend
mvn spring-boot:run

# Build backend
mvn clean package -DskipTests
```

### Production Verification
```bash
# SSH to server
ssh root@your-server

# Check backend logs
docker logs nammaooru-backend --tail 50 | grep -i flyway

# Check migration history
docker exec -it nammaooru-postgres psql -U postgres -d shop_management_db

SELECT version, description, installed_on, success
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 5;
```

---

## 🚨 COMMON ISSUES

### ❌ Validation Failed
**Error:** "Invalid naming"
**Fix:** Rename file to `V{number}__{description}.sql`

### ❌ Migration Failed in Production
**Error:** "Column already exists"
**Fix:** Add IF NOT EXISTS check to migration

### ❌ Backend Won't Start
**Error:** "Migration checksum mismatch"
**Fix:** Never modify applied migrations! Create new migration instead

---

## 📊 WHAT CI/CD DOES AUTOMATICALLY

```
On git push:
  1. ✅ Preview migrations (shows in logs)
  2. ✅ Validate migrations (checks for errors)
  3. ✅ Build backend (ensures it compiles)
  4. ✅ Deploy to server
  5. ✅ Restart containers
  6. ✅ Flyway auto-applies migrations
  7. ✅ Verify migrations applied
  8. ✅ Show migration history
```

**Total time:** 5-10 minutes (automatic!)

---

## ⚙️ HOW ALTER COMMANDS WORK

**YES!** ALTER TABLE works perfectly in Flyway migrations:

```sql
-- This works automatically:
DO $$
BEGIN
    IF NOT EXISTS (...) THEN
        ALTER TABLE orders ADD COLUMN delivery_fee DECIMAL(10,2);
        -- ✅ Will run in production automatically
    END IF;
END $$;
```

**When Spring Boot starts:**
1. Flyway scans migration files
2. Finds new migration
3. **Executes ALTER TABLE command**
4. Column added to database
5. Records in flyway_schema_history
6. Never runs again

**All automatic!** No manual SQL needed.

---

## 🎯 KEY POINTS

✅ **DO:**
- Use IF NOT EXISTS
- Preview before commit
- Validate before push
- Test locally first
- Let CI/CD deploy automatically

❌ **DON'T:**
- Modify applied migrations
- Delete migration files
- Run manual SQL in production
- Skip validation
- Commit without testing

---

## 📁 MIGRATION FILE STRUCTURE

```
backend/
  src/
    main/
      resources/
        db/
          migration/
            V3__Create_Shop_Documents_Table.sql
            V4__Create_Product_Tables.sql
            V22__Fix_Product_Categories.sql
            V23__Add_user_phone.sql ← Your new migration
```

**Naming:** `V{number}__{description}.sql`
- V = Version prefix (required)
- {number} = Sequential number (23, 24, 25...)
- __ = Double underscore (required)
- {description} = What it does (use underscores)
- .sql = File extension

---

## 🔄 MIGRATION LIFECYCLE

```
Local:
  1. Create migration file
  2. Test with mvn spring-boot:run
  3. Migration applied to local DB
  4. Recorded in flyway_schema_history
     ↓
Git:
  5. Commit migration file
  6. Push to GitHub
     ↓
CI/CD:
  7. Validate migration
  8. Build backend (migration inside JAR)
  9. Deploy to server
     ↓
Production:
  10. Container starts
  11. Spring Boot starts
  12. Flyway auto-runs
  13. Checks flyway_schema_history
  14. Finds new migration
  15. Executes ALTER TABLE
  16. Records success ✅
  17. App starts normally
```

**All automatic from step 7 onwards!**

---

## 🆘 EMERGENCY CONTACTS

**If deployment fails:**
1. Check GitHub Actions logs
2. Check backend container logs
3. Check database migration history
4. Create new migration to fix (never delete/modify)

**Files to check:**
- Migration file: `backend/src/main/resources/db/migration/V*.sql`
- Workflow: `.github/workflows/deploy-with-validation.yml`
- Backend logs: `docker logs nammaooru-backend`

---

## 📞 HELP DOCUMENTS

**Quick:**
- This file (one-page reference)
- `QUICK_CHECKLIST.md` (printable checklist)

**Detailed:**
- `PRE_DEPLOYMENT_WORKFLOW.md` (complete workflow guide)
- `DATABASE_MIGRATION_GUIDE.md` (comprehensive guide)
- `CICD_MIGRATION_FLOW.md` (how CI/CD works)

**Examples:**
- `EXAMPLE_SAFE_MIGRATION.sql` (SQL templates)
- `MIGRATIONS_SIMPLE_GUIDE.md` (3-step guide)

---

## ✨ SUMMARY

**Every database change:**
```bash
create-migration.bat "Description"
# Edit file with safe SQL
preview-migrations.bat
validate-migrations.bat
mvn spring-boot:run  # test
git add . && git commit -m "Migration: Description" && git push
# Done! CI/CD handles rest automatically
```

**Time:** 5 minutes of your work
**Result:** Safe, validated, automatic deployment
**Benefit:** Zero manual production work! 🎉

---

**PRINT THIS PAGE AND KEEP IT HANDY!** 📌
