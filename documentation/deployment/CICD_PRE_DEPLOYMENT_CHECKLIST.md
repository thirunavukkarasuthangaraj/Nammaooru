# 📋 CI/CD PRE-DEPLOYMENT CHECKLIST

**Run these checks BEFORE every deployment to production!**

---

## 🔍 AUTOMATED VALIDATION

### Step 1: Run Migration Validator

**Windows:**
```bash
validate-migrations.bat
```

**Linux/Mac:**
```bash
chmod +x validate-migrations.sh
./validate-migrations.sh
```

**Expected Output:**
```
============================================
   VALIDATION SUMMARY
============================================
  Migration files: 5
  Errors: 0
  Warnings: 0
============================================

[SUCCESS] All validations passed!
```

✅ **PASS** = Safe to deploy
❌ **FAIL** = Fix errors before deploying

---

## ✅ MANUAL CHECKLIST

### Database Migrations

- [ ] **New migration files created?**
  - Location: `backend/src/main/resources/db/migration/`
  - Naming: `V{number}__{description}.sql`

- [ ] **Migration files follow naming convention?**
  - ✅ Good: `V24__Add_delivery_fee_to_orders.sql`
  - ❌ Bad: `migration.sql`, `update_db.sql`

- [ ] **Safe SQL patterns used?**
  - [ ] Uses `IF NOT EXISTS` for ALTER TABLE
  - [ ] Uses `CREATE TABLE IF NOT EXISTS`
  - [ ] No destructive operations without confirmation
  - [ ] Uses `DO $$` blocks for conditional logic

- [ ] **Tested locally?**
  - [ ] Ran `mvn spring-boot:run` successfully
  - [ ] Checked logs: "Successfully applied 1 migration"
  - [ ] Verified changes in local database

- [ ] **Migration handles existing prod data?**
  - [ ] Won't fail if column already exists
  - [ ] Won't delete existing data
  - [ ] Safe to run multiple times

---

### Code Quality

- [ ] **Backend builds successfully?**
  ```bash
  cd backend
  mvn clean package -DskipTests
  ```

- [ ] **No compilation errors?**

- [ ] **Tests pass? (if applicable)**
  ```bash
  mvn test
  ```

- [ ] **Code committed and pushed?**
  ```bash
  git status  # Should show "nothing to commit, working tree clean"
  ```

---

### Configuration

- [ ] **Environment variables correct?**
  - Database connection strings
  - API keys
  - Secret keys

- [ ] **application.properties updated?**
  - Check for any new properties needed

- [ ] **Docker configuration valid?**
  - docker-compose.yml up to date
  - Dockerfile has no errors

---

### GitHub Actions

- [ ] **Workflow file valid?**
  - `.github/workflows/deploy.yml` exists
  - No syntax errors

- [ ] **Secrets configured?**
  - `HETZNER_HOST`
  - `HETZNER_USER`
  - `HETZNER_SSH_KEY`
  - Database credentials

- [ ] **Previous deployment successful?**
  - Check last GitHub Actions run
  - No failed deployments blocking

---

### Production Readiness

- [ ] **Production database accessible?**
  - Can connect to prod database
  - Database is running

- [ ] **Backup taken? (for major changes)**
  ```bash
  # On production server
  docker exec nammaooru-postgres pg_dump -U postgres shop_management_db > backup_$(date +%Y%m%d_%H%M%S).sql
  ```

- [ ] **Downtime acceptable? (if any expected)**
  - Notify users if needed
  - Plan deployment during low traffic

- [ ] **Rollback plan ready?**
  - Know how to revert if deployment fails
  - Have previous working version tagged

---

## 🚀 DEPLOYMENT STEPS

### Pre-Deployment

1. **Run Validation:**
   ```bash
   validate-migrations.bat  # or .sh
   ```

2. **Check Checklist Above** ✅

3. **Review Changes:**
   ```bash
   git log -3  # Review last 3 commits
   git diff origin/main..HEAD  # See what's deploying
   ```

### Deployment

4. **Push to Main Branch:**
   ```bash
   git push origin main
   ```

5. **Monitor GitHub Actions:**
   - Go to: https://github.com/your-repo/actions
   - Watch deployment progress
   - Check for errors

6. **Monitor Backend Logs:**
   ```bash
   # On production server
   docker logs -f nammaooru-backend
   ```

### Post-Deployment

7. **Verify Migration Applied:**
   ```bash
   # Check backend logs for:
   # "Migrating schema to version X"
   # "Successfully applied 1 migration"
   ```

8. **Check Database:**
   ```bash
   docker exec -it nammaooru-postgres psql -U postgres -d shop_management_db

   # Verify migration in history
   SELECT version, description, installed_on, success
   FROM flyway_schema_history
   ORDER BY installed_rank DESC
   LIMIT 5;

   # Verify changes exist
   \d your_table  # Check table structure
   ```

9. **Test Application:**
   - Test affected features
   - Check API endpoints
   - Verify no errors

10. **Monitor for Issues:**
    - Watch logs for errors
    - Check error rates
    - Monitor performance

---

## 🔴 EMERGENCY ROLLBACK

If deployment fails:

### Option 1: Revert Git Commit
```bash
git revert HEAD
git push origin main
# Wait for CI/CD to deploy previous version
```

### Option 2: Manual Rollback (if needed)
```bash
# SSH to production
ssh root@your-server

# Rollback to previous Docker image
docker-compose down
docker-compose up -d --force-recreate

# If migration needs to be undone:
# Create new migration to reverse changes
# DO NOT delete migration files!
```

---

## 📊 VALIDATION CHECKS EXPLAINED

### Check 1: File Naming Convention
- **What:** Ensures files follow `V{number}__{description}.sql`
- **Why:** Flyway requires this format to determine order

### Check 2: No Duplicate Versions
- **What:** Ensures no two files have same version number
- **Why:** Prevents migration conflicts

### Check 3: Safe SQL Patterns
- **What:** Looks for `IF NOT EXISTS` checks
- **Why:** Makes migrations idempotent (safe to run multiple times)

### Check 4: Dangerous Operations
- **What:** Flags `DROP TABLE`, `TRUNCATE`
- **Why:** Prevents accidental data loss

### Check 5: Transaction Safety
- **What:** Checks for `DO $$` blocks
- **Why:** Ensures atomic operations

---

## ⚡ QUICK PRE-DEPLOY COMMAND

**Run everything in one go:**

```bash
# Validate migrations, build, and check status
validate-migrations.bat && cd backend && mvn clean package -DskipTests && cd .. && git status
```

**Expected result:**
```
[SUCCESS] All validations passed!
[INFO] BUILD SUCCESS
nothing to commit, working tree clean
```

✅ **Safe to deploy!**

---

## 🔗 INTEGRATION WITH CI/CD

You can add this validation to your GitHub Actions workflow:

```yaml
# .github/workflows/deploy.yml

jobs:
  validate-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Validate migrations
        run: |
          chmod +x validate-migrations.sh
          ./validate-migrations.sh

      - name: Build backend
        run: |
          cd backend
          mvn clean package -DskipTests

      # ... rest of deployment steps
```

This ensures migrations are validated BEFORE deployment starts!

---

## 📝 COMMON ISSUES

### ❌ "Migration validation failed"
**Fix:** Check error messages, fix migration files, re-validate

### ❌ "Duplicate version number"
**Fix:** Rename migration file with next available version

### ❌ "Migration checksum mismatch"
**Fix:** Never modify applied migrations! Create new migration instead

### ❌ "Migration failed in production"
**Fix:** Create new migration to fix the issue (forward-only migrations)

---

## ✅ BEST PRACTICES

1. **Always validate before pushing**
2. **Test locally first**
3. **Use IF NOT EXISTS checks**
4. **Keep migrations small and focused**
5. **Never modify applied migrations**
6. **Document major changes**
7. **Take backups before major migrations**
8. **Deploy during low-traffic periods**
9. **Monitor logs after deployment**
10. **Have rollback plan ready**

---

## 📌 REMEMBER

✅ **DO:**
- Run `validate-migrations.bat` before every deployment
- Test locally with `mvn spring-boot:run`
- Use safe SQL patterns
- Monitor deployment logs
- Keep migration files in version control

❌ **DON'T:**
- Skip validation checks
- Deploy without testing locally
- Modify applied migrations
- Delete migration files
- Deploy during peak hours (for major changes)

---

**🎯 GOLDEN RULE:** If validation passes and local testing works, deployment is safe!

---

## 🆘 NEED HELP?

- **Migration Guide:** `DATABASE_MIGRATION_GUIDE.md`
- **Simple Guide:** `MIGRATIONS_SIMPLE_GUIDE.md`
- **Quick Checklist:** `QUICK_CHECKLIST.md`
- **CI/CD Flow:** `CICD_MIGRATION_FLOW.md`
