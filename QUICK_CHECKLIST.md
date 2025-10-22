# 📋 DATABASE CHANGE - QUICK CHECKLIST
**Print this and keep on your desk!**

---

## ✅ EVERY TIME YOU CHANGE A DATABASE TABLE:

### **1. DOCUMENT** (30 seconds)
```
What changed: ________________
Table: ________________
Column: ________________
Type: ________________
```

---

### **2. CREATE MIGRATION** (10 seconds)
```bash
create-migration.bat "Add [column] to [table]"
```
✅ File created and opened

---

### **3. WRITE SAFE SQL** (2 minutes)
```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'YOUR_TABLE'
        AND column_name = 'YOUR_COLUMN'
    ) THEN
        ALTER TABLE YOUR_TABLE
        ADD COLUMN YOUR_COLUMN YOUR_TYPE;
    END IF;
END $$;
```
✅ Replace YOUR_TABLE, YOUR_COLUMN, YOUR_TYPE
✅ Save file

---

### **4. TEST LOCALLY** (30 seconds)
```bash
mvn spring-boot:run
```
✅ Look for: "Successfully applied 1 migration"
✅ No errors

---

### **5. COMMIT & PUSH** (30 seconds)
```bash
git add backend/src/main/resources/db/migration/V*.sql
git commit -m "Migration: Add [column] to [table]"
git push
```
✅ Pushed to GitHub

---

### **6. DONE!** ✨
✅ CI/CD will deploy automatically
✅ Production updates on next deployment
✅ No manual SQL needed!

---

## ⚡ TOTAL TIME: ~5 MINUTES

---

## 🚨 REMEMBER:

❌ **NEVER:**
- Modify existing migration files
- Delete migration files
- Run manual SQL in production
- Skip local testing

✅ **ALWAYS:**
- Use IF NOT EXISTS
- Test locally first
- Commit and push
- Document changes

---

## 📞 NEED HELP?

See detailed guides:
- `DATABASE_CHANGE_CHECKLIST.md` (full checklist)
- `MIGRATIONS_SIMPLE_GUIDE.md` (examples)
- `HANDLING_EXISTING_PROD_CHANGES.md` (prod changes)

---

**KEEP THIS CHECKLIST VISIBLE!** 📌
