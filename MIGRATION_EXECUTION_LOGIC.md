# 🔒 Migration Execution Logic - Will It Run Again?

## ❓ YOUR QUESTION:
**"If I deploy the same build again, will migration scripts execute again?"**

## ✅ SHORT ANSWER:
**NO! Migrations run ONLY ONCE, even if you deploy 100 times!**

---

## 🔍 HOW FLYWAY TRACKS MIGRATIONS

### The Magic Table: `flyway_schema_history`

Every time a migration runs, Flyway records it in a special tracking table.

**Check your database right now:**
```sql
SELECT * FROM flyway_schema_history ORDER BY installed_rank;
```

**Example output:**
```
installed_rank | version | description                  | script                               | installed_on        | success
---------------+---------+-----------------------------+--------------------------------------+--------------------+---------
1              | 3       | Create Shop Documents       | V3__Create_Shop_Documents_Table.sql | 2025-09-28 10:00:00| true
2              | 4       | Create Product Tables       | V4__Create_Product_Tables.sql       | 2025-09-28 10:00:01| true
3              | 22      | Fix Product Categories      | V22__Fix_Product_Categories.sql     | 2025-10-22 14:30:01| true
```

---

## 🎯 EXECUTION LOGIC

### Scenario 1: First Deployment (New Migration)

**Your Build Contains:**
- V3, V4, V22, **V23 (NEW)**

**Database `flyway_schema_history` Has:**
- V3 ✅ (applied)
- V4 ✅ (applied)
- V22 ✅ (applied)

**Flyway Does:**
```
1. Scan JAR: Find V3, V4, V22, V23
2. Check history: V3, V4, V22 already applied
3. Compare: V23 is NEW!
4. Execute: Run V23__*.sql
5. Record: Add V23 to flyway_schema_history
6. Result: ✅ V23 applied, others skipped
```

---

### Scenario 2: Re-Deploy Same Build (No New Migrations)

**Your Build Contains:**
- V3, V4, V22, V23

**Database `flyway_schema_history` Has:**
- V3 ✅ (applied)
- V4 ✅ (applied)
- V22 ✅ (applied)
- V23 ✅ (applied)

**Flyway Does:**
```
1. Scan JAR: Find V3, V4, V22, V23
2. Check history: ALL already applied!
3. Compare: Nothing new
4. Execute: NOTHING! Skip all
5. Record: No changes
6. Result: ✅ All skipped, app starts immediately
```

**Log Output:**
```
Flyway: Schema is up to date. No migration necessary.
Successfully validated 4 migrations (execution time 00:00.023s)
```

---

### Scenario 3: Deploy 10 Times in a Row

**What Happens:**
```
Deploy #1: V23 runs (new) ✅
Deploy #2: Nothing runs (V23 already applied)
Deploy #3: Nothing runs (V23 already applied)
Deploy #4: Nothing runs (V23 already applied)
...
Deploy #10: Nothing runs (V23 already applied)
```

**Result:** Migration runs ONLY ONCE on first deployment!

---

## 🛡️ SAFETY MECHANISMS

### 1. Version Number Lock
```
V23__Add_user_phone.sql

Once V23 is applied:
- Flyway marks version "23" as completed
- Will NEVER run version "23" again
- Even if you modify the file (checksum check)
```

### 2. Checksum Verification
```
First run:
- Flyway calculates checksum: abc123def456
- Stores in flyway_schema_history

Next deployment:
- Flyway calculates checksum again: abc123def456
- Compares with stored checksum
- If SAME: Skip (already applied)
- If DIFFERENT: ERROR! (file was modified)
```

### 3. Installed Flag
```sql
SELECT version, success FROM flyway_schema_history;

version | success
--------+---------
23      | true      ← Migration succeeded, never runs again
24      | false     ← Migration failed, will retry
```

---

## 📊 REAL WORLD EXAMPLE

### Timeline:

**Day 1 - First Deployment:**
```
9:00 AM - Deploy build v1.0.0 (has V23)
9:01 AM - Backend starts
9:01 AM - Flyway: "Running V23__Add_user_phone.sql"
9:01 AM - Flyway: "V23 SUCCESS ✅"
9:01 AM - App starts
```

**Day 2 - Redeploy Same Build:**
```
2:00 PM - Deploy build v1.0.0 again (same V23)
2:01 PM - Backend starts
2:01 PM - Flyway: "Checking migrations..."
2:01 PM - Flyway: "V23 already applied, skipping"
2:01 PM - Flyway: "Schema up to date ✅"
2:01 PM - App starts (no migration ran)
```

**Day 3 - Deploy with New Migration:**
```
10:00 AM - Deploy build v1.0.1 (has V23, V24)
10:01 AM - Backend starts
10:01 AM - Flyway: "Checking migrations..."
10:01 AM - Flyway: "V23 already applied, skipping"
10:01 AM - Flyway: "V24 is NEW, running..."
10:01 AM - Flyway: "V24 SUCCESS ✅"
10:01 AM - App starts
```

---

## 🔄 WHAT ABOUT ROLLBACKS?

### Can you run a migration again?

**Short answer:** Not automatically. You need a new migration.

**Example - Undo V23:**

**Wrong way (won't work):**
```
❌ Delete V23 from flyway_schema_history
❌ Modify V23__*.sql file
❌ Redeploy

Result: Flyway detects checksum changed and ERRORS!
```

**Right way (create new migration):**
```
✅ Create V24__Rollback_user_phone.sql
✅ Write SQL to undo V23:
   ALTER TABLE users DROP COLUMN phone;
✅ Deploy

Result: V24 runs, undoes V23 ✅
```

---

## 🎓 UNDERSTANDING THE FLOW

```
┌─────────────────────────────────────────────────────┐
│  Backend Starts (Any deployment, any time)          │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Flyway: Scan db/migration/ folder                  │
│  Found: V3, V4, V22, V23                            │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Flyway: Query flyway_schema_history table          │
│  SELECT version FROM flyway_schema_history          │
│  Result: [3, 4, 22]  (no 23 yet)                    │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Flyway: Compare Found vs Applied                   │
│  Found: [3, 4, 22, 23]                              │
│  Applied: [3, 4, 22]                                │
│  Missing: [23] ← Need to run!                       │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Flyway: Execute V23__*.sql                         │
│  ALTER TABLE users ADD COLUMN phone...             │
│  Success! ✅                                         │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Flyway: Record in flyway_schema_history            │
│  INSERT INTO flyway_schema_history                  │
│  (version, description, success)                    │
│  VALUES (23, 'Add user phone', true)                │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│  Next Deployment (same build)                       │
│  Flyway: Query history                              │
│  Result: [3, 4, 22, 23] ← All there!                │
│  Action: Skip all, nothing to run ✅                │
└─────────────────────────────────────────────────────┘
```

---

## 🧪 TEST IT YOURSELF

### Experiment:

**Step 1:** Check current migrations
```sql
SELECT version, description, installed_on
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 5;
```

**Step 2:** Restart your backend (no code changes)
```bash
# Stop backend
# Start backend again
java -jar backend.jar
```

**Step 3:** Check logs
```
Look for: "Schema is up to date. No migration necessary."
```

**Step 4:** Check history again
```sql
SELECT version, description, installed_on
FROM flyway_schema_history
ORDER BY installed_rank DESC
LIMIT 5;
```

**Result:** Same migrations, same timestamps! Nothing re-ran! ✅

---

## 📋 COMMON SCENARIOS

### Scenario: Deploy 5 times in one day

**First deployment (9 AM):**
- V24 runs ✅
- Takes 2 seconds

**Deployments 2-5 (10 AM, 11 AM, 2 PM, 4 PM):**
- Nothing runs
- Each takes < 0.1 seconds (just checks history)

**Total V24 executions:** 1 (only first time)

---

### Scenario: Rollback and deploy again

**Deployment 1:**
- Deploy v1.0.1 (has V24)
- V24 runs ✅

**Rollback:**
- Revert to v1.0.0 (no V24 in JAR)
- Backend starts
- Flyway sees V24 in history but not in JAR
- Ignores it (doesn't undo it!)
- Database still has changes from V24 ⚠️

**Re-deploy v1.0.1:**
- V24 in JAR again
- V24 in history
- Flyway: "V24 already applied"
- Skips V24 ✅

**Lesson:** Rollbacks don't undo migrations automatically!

---

### Scenario: Modified migration file

**Original V24:**
```sql
-- V24__Add_user_phone.sql
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
```

**Deployed, applied, checksum recorded: abc123**

**Later, you modify V24:**
```sql
-- V24__Add_user_phone.sql (MODIFIED)
ALTER TABLE users ADD COLUMN phone VARCHAR(50);  -- Changed length!
```

**Next deployment:**
```
Flyway: Calculate checksum of V24
Result: def456 (different from abc123)
ERROR: Migration checksum mismatch!
Detected: V24 was modified after being applied
Action: Deployment FAILS ❌
```

**Fix:** Never modify applied migrations! Create V25 instead.

---

## ✅ SUMMARY

### Question: Will migration run again if I deploy same build?

**Answer:** NO!

### Why not?

1. ✅ Flyway tracks in `flyway_schema_history` table
2. ✅ Each version runs only once
3. ✅ Checksum prevents modifications
4. ✅ `success = true` means never run again

### What runs on re-deployment?

```
Deploy 1:  V23 runs ← NEW
Deploy 2:  Nothing  ← Already applied
Deploy 3:  Nothing  ← Already applied
Deploy 10: Nothing  ← Already applied
Deploy 50: Nothing  ← Already applied
```

### When does a migration run?

**ONLY when:**
- ✅ It's a NEW version not in history
- ✅ Previous attempt failed (`success = false`)
- ✅ Using special Flyway repair commands (rare)

### Can you force re-run?

**Not recommended!** But possible:
```sql
-- Delete from history (dangerous!)
DELETE FROM flyway_schema_history WHERE version = '23';

-- Next deployment will run V23 again
-- But may cause errors if changes already exist!
```

**Better approach:** Create new migration (V24) with additional changes

---

## 🎯 KEY TAKEAWAY

**Migrations are IDEMPOTENT by VERSION:**
- Same version = Runs once only
- Tracked in database
- Safe to deploy same build multiple times
- No duplicate executions
- No need to worry! ✅

**Deploy your build 1 time or 100 times - migrations run only when needed!** 🚀
