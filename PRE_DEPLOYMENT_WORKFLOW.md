# 🚀 PRE-DEPLOYMENT WORKFLOW - COMPLETE GUIDE

**How to deploy database changes safely using validation and preview tools**

---

## 📊 WORKFLOW OVERVIEW

```
1. Make Database Change
   ↓
2. Create Migration File
   ↓
3. PREVIEW migrations ← NEW! Shows what will deploy
   ↓
4. VALIDATE migrations ← NEW! Checks for errors
   ↓
5. Test Locally
   ↓
6. Commit & Push
   ↓
7. CI/CD Auto-Deploy ← NEW! Validates before deploying
   ↓
8. ✅ Done!
```

---

## 🛠️ NEW TOOLS AVAILABLE

### 1. **preview-migrations** (View before deploy)
Shows all migration files and their contents

**Windows:**
```bash
preview-migrations.bat
```

**Linux/Mac:**
```bash
./preview-migrations.sh
```

**Output:**
```
============================================
   MIGRATION FILES PREVIEW
============================================

[INFO] Found 2 migration file(s)

============================================
   MIGRATION FILES LIST
============================================

[1] V23__Add_user_phone.sql
[2] V24__Add_delivery_fee.sql

============================================
   FILE CONTENTS PREVIEW
============================================

╔════════════════════════════════════════
║ FILE: V23__Add_user_phone.sql
╚════════════════════════════════════════

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'phone'
    ) THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR(20);
    END IF;
END $$;
```

**When to use:** Before committing, to review what changes will be deployed

---

### 2. **validate-migrations** (Check for errors)
Validates migration files for common issues

**Windows:**
```bash
validate-migrations.bat
```

**Linux/Mac:**
```bash
./validate-migrations.sh
```

**What it checks:**
- ✅ Correct naming convention (V{number}__{description}.sql)
- ✅ No duplicate version numbers
- ✅ Safe SQL patterns (IF NOT EXISTS)
- ✅ No dangerous operations (DROP TABLE, TRUNCATE)
- ✅ Transaction safety

**Output:**
```
============================================
   VALIDATION SUMMARY
============================================
  Migration files: 2
  Errors: 0
  Warnings: 0
============================================

[SUCCESS] All validations passed!
```

**When to use:** Before pushing code, to catch errors

---

### 3. **CI/CD with validation** (Automatic checks)
New GitHub Actions workflow that validates before deploying

**File:** `.github/workflows/deploy-with-validation.yml`

**What it does:**
1. ✅ Previews migration files
2. ✅ Validates migration files
3. ✅ Builds backend (ensures it compiles)
4. ✅ Only deploys if all checks pass

**How to enable:**
```bash
# Option 1: Rename current workflow
mv .github/workflows/deploy.yml .github/workflows/deploy-old.yml

# Option 2: Use the new one
# It will activate automatically on next push to main
```

---

## 📋 COMPLETE STEP-BY-STEP WORKFLOW

### Step 1: Make Database Change
```sql
-- Example: Add column in local database
ALTER TABLE orders ADD COLUMN delivery_notes TEXT;
```

---

### Step 2: Create Migration File
```bash
create-migration.bat "Add delivery notes to orders"
```

**Creates:** `V24__Add_delivery_notes_to_orders.sql`

Write safe SQL in the file:
```sql
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

---

### Step 3: PREVIEW Migrations ⭐ NEW!
```bash
preview-migrations.bat
```

**Review the output:**
- Check file names are correct
- Review SQL to ensure it's what you intended
- Verify IF NOT EXISTS checks are present

✅ **Looks good?** Continue
❌ **Something wrong?** Edit migration file and preview again

---

### Step 4: VALIDATE Migrations ⭐ NEW!
```bash
validate-migrations.bat
```

**Check the output:**
- Errors: 0 ✅
- Warnings: 0 or acceptable ✅

✅ **Validation passed?** Continue
❌ **Validation failed?** Fix errors and validate again

---

### Step 5: Test Locally
```bash
cd backend
mvn spring-boot:run
```

**Check logs:**
```
Flyway: Migrating schema to version "24 - Add delivery notes to orders"
Flyway: Successfully applied 1 migration
```

✅ **Migration applied?** Continue
❌ **Failed?** Fix and test again

---

### Step 6: Commit & Push
```bash
git add backend/src/main/resources/db/migration/V24__*.sql
git commit -m "Migration: Add delivery notes to orders"
git push
```

---

### Step 7: CI/CD Auto-Deploy ⭐ NEW!

**GitHub Actions will automatically:**

1. **Checkout code**
2. **Preview migrations** (shows in logs)
3. **Validate migrations** (checks for errors)
4. **Build backend** (ensures it compiles)
5. **Deploy to production** (only if all checks pass)

**Monitor progress:**
- Go to: https://github.com/your-repo/actions
- Click on your commit
- Watch the workflow run

**Check logs for:**
```
✅ PRE-DEPLOYMENT VALIDATION PASSED
✅ Migration files validated
✅ Backend builds successfully
Proceeding with deployment...
```

---

### Step 8: Verify Deployment

**Check backend logs:**
```bash
# On production server
ssh root@your-server
docker logs nammaooru-backend | grep Flyway
```

**Expected:**
```
Flyway: Migrating schema to version "24 - Add delivery notes"
Flyway: Successfully applied 1 migration
```

**Verify in database:**
```bash
docker exec -it nammaooru-postgres psql -U postgres -d shop_management_db

SELECT version, description, installed_on, success
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 5;
```

✅ **Done!** Production database updated

---

## ⚡ QUICK COMMAND REFERENCE

### Before Commit:
```bash
# 1. Preview what will deploy
preview-migrations.bat

# 2. Validate for errors
validate-migrations.bat

# 3. Test locally
cd backend && mvn spring-boot:run

# 4. All-in-one check
preview-migrations.bat && validate-migrations.bat && echo "✅ Ready to commit!"
```

### After Push:
```bash
# Watch GitHub Actions
# Go to: https://github.com/your-repo/actions

# Check production logs
ssh root@your-server
docker logs nammaooru-backend --tail 50 | grep -i "flyway\|migration"
```

---

## 🚨 ERROR HANDLING

### Validation Failed (Local)

**Error message:**
```
[ERROR] Invalid naming: migration.sql
        Expected: V{number}__{description}.sql
```

**Fix:**
```bash
# Rename file correctly
mv migration.sql V24__Add_column.sql
```

---

### CI/CD Validation Failed

**Error in GitHub Actions:**
```
Error: Validation failed with 1 error(s)
```

**Fix:**
1. Check GitHub Actions logs for specific error
2. Fix the migration file locally
3. Commit and push again
4. CI/CD will re-validate

---

### Migration Failed in Production

**Error in backend logs:**
```
Flyway: Migration failed - column already exists
```

**This means:**
- Your IF NOT EXISTS check is missing or incorrect

**Fix:**
```sql
-- Bad (will fail if column exists):
ALTER TABLE orders ADD COLUMN notes TEXT;

-- Good (safe to run multiple times):
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'orders' AND column_name = 'notes'
    ) THEN
        ALTER TABLE orders ADD COLUMN notes TEXT;
    END IF;
END $$;
```

Create new migration (V25) with corrected SQL

---

## 📊 COMPARISON: OLD vs NEW WORKFLOW

### OLD Workflow (Before):
```
1. Make change
2. Create migration
3. Test locally (maybe)
4. Push
5. Hope it works 🤞
6. Check production manually
```

**Problems:**
- ❌ No validation before deploy
- ❌ Can't preview what will deploy
- ❌ Errors discovered in production
- ❌ Manual verification needed

---

### NEW Workflow (Now):
```
1. Make change
2. Create migration
3. PREVIEW migrations ← See what will deploy
4. VALIDATE migrations ← Catch errors early
5. Test locally
6. Push
7. CI/CD validates ← Automatic checks
8. Deploy (only if valid) ← Safe deployment
9. Auto-verify ← Flyway logs checked
```

**Benefits:**
- ✅ Errors caught before production
- ✅ See exactly what will deploy
- ✅ Automatic validation in CI/CD
- ✅ Deployment blocked if validation fails
- ✅ Automatic verification logs
- ✅ Much safer!

---

## 🎯 BEST PRACTICES

### 1. Always Preview Before Commit
```bash
# See what you're about to deploy
preview-migrations.bat
```

### 2. Always Validate Before Push
```bash
# Catch errors early
validate-migrations.bat
```

### 3. Use Combined Command
```bash
# One command to check everything
preview-migrations.bat && validate-migrations.bat && echo "✅ Safe to commit!"
```

### 4. Monitor CI/CD Logs
- Watch GitHub Actions during deployment
- Check for validation steps
- Review Flyway logs

### 5. Verify After Deployment
- Check backend logs for Flyway success
- Query flyway_schema_history table
- Test the feature

---

## 📁 FILES CREATED

**Scripts:**
- ✅ `preview-migrations.bat` (Windows)
- ✅ `preview-migrations.sh` (Linux/Mac)
- ✅ `validate-migrations.bat` (Windows)
- ✅ `validate-migrations.sh` (Linux/Mac)

**Workflow:**
- ✅ `.github/workflows/deploy-with-validation.yml`

**Documentation:**
- ✅ `CICD_PRE_DEPLOYMENT_CHECKLIST.md`
- ✅ `PRE_DEPLOYMENT_WORKFLOW.md` (this file)

---

## 🚀 ACTIVATING THE NEW WORKFLOW

### Option 1: Replace Current Workflow
```bash
# Backup old workflow
mv .github/workflows/deploy.yml .github/workflows/deploy-backup.yml

# Activate new workflow
mv .github/workflows/deploy-with-validation.yml .github/workflows/deploy.yml

# Commit
git add .github/workflows/
git commit -m "Enable pre-deployment validation in CI/CD"
git push
```

### Option 2: Run Both Workflows
Keep both files, and both workflows will run on push.
The validation workflow will catch errors.

---

## ✅ SUMMARY

**You now have:**
1. ✅ **preview-migrations** - See what will deploy
2. ✅ **validate-migrations** - Check for errors
3. ✅ **CI/CD validation** - Automatic checks before deploy

**Your workflow:**
```bash
# 1. Create migration
create-migration.bat "Add column"

# 2. Write safe SQL
# (edit migration file)

# 3. Preview & Validate
preview-migrations.bat
validate-migrations.bat

# 4. Test locally
mvn spring-boot:run

# 5. Commit & Push
git add .
git commit -m "Migration: Add column"
git push

# 6. CI/CD validates and deploys automatically
# 7. Check logs to verify success
```

**Result:** Safe, validated, automatic deployments! 🎉

---

## 🆘 NEED HELP?

See also:
- **Quick Checklist:** `QUICK_CHECKLIST.md`
- **Detailed Checklist:** `DATABASE_CHANGE_CHECKLIST.md`
- **CI/CD Flow:** `CICD_MIGRATION_FLOW.md`
- **Migration Guide:** `DATABASE_MIGRATION_GUIDE.md`
