# 📁 MIGRATION FOLDER ORGANIZATION

**How to organize database migration files for better maintainability**

---

## 🎯 **Why Organize?**

As your project grows, you'll have many migration files:
```
After 1 year: 50+ migration files
After 2 years: 100+ migration files
After 3 years: 150+ migration files
```

**Problem:** All in one folder = Hard to find, messy, confusing

**Solution:** Organize into subfolders!

---

## ✅ **Recommended Structure: By Year**

```
backend/src/main/resources/db/migration/
  ├── 2025/
  │   ├── V23__Add_user_phone.sql
  │   ├── V24__Add_delivery_fee.sql
  │   ├── V25__Add_email.sql
  │   ├── V26__Create_notifications.sql
  │   └── V27__Add_index_orders.sql
  ├── 2026/
  │   ├── V28__Add_rating.sql
  │   ├── V29__Create_reviews_table.sql
  │   └── V30__Add_address.sql
  └── 2027/
      └── (future migrations)
```

**Benefits:**
- ✅ Easy to find migrations by year
- ✅ Clear timeline of database changes
- ✅ Clean, organized structure
- ✅ Easy to add new years

---

## 🔧 **Setup Steps**

### **Step 1: Configure Flyway** ✅ DONE

Already configured in `application.yml`:

```yaml
spring:
  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration,classpath:db/migration/2025,classpath:db/migration/2026
```

**Add new years as needed:**
```yaml
locations: classpath:db/migration,classpath:db/migration/2025,classpath:db/migration/2026,classpath:db/migration/2027
```

---

### **Step 2: Use Organized Migration Script**

**Two options available:**

#### **Option A: Organized (Recommended - by year)**
```bash
# Automatically creates in year folder
create-migration-organized.bat "Add delivery fee"

# Creates: backend/src/main/resources/db/migration/2025/V24__Add_delivery_fee.sql
```

#### **Option B: Simple (Original - single folder)**
```bash
# Creates in root migration folder
create-migration.bat "Add delivery fee"

# Creates: backend/src/main/resources/db/migration/V24__Add_delivery_fee.sql
```

**Choose one and stick with it!**

---

## 📊 **Comparison**

### **Before (Unorganized):**
```
db/migration/
  ├── V3__Create_Shop_Documents.sql
  ├── V4__Create_Product_Tables.sql
  ├── V22__Fix_Categories.sql
  ├── V23__Add_user_phone.sql
  ├── V24__Add_delivery_fee.sql
  ├── V25__Add_email.sql
  ├── V26__Create_notifications.sql
  ├── V27__Add_index.sql
  ├── V28__Add_rating.sql
  └── ...50 more files... (messy!)
```

### **After (Organized):**
```
db/migration/
  ├── 2024/
  │   ├── V3__Create_Shop_Documents.sql
  │   └── V4__Create_Product_Tables.sql
  ├── 2025/
  │   ├── V22__Fix_Categories.sql
  │   ├── V23__Add_user_phone.sql
  │   ├── V24__Add_delivery_fee.sql
  │   ├── V25__Add_email.sql
  │   ├── V26__Create_notifications.sql
  │   └── V27__Add_index.sql
  └── 2026/
      ├── V28__Add_rating.sql
      └── ...
```

**Much cleaner!**

---

## 🔄 **Migration Process with Folders**

### **Creating New Migration:**

```bash
# 1. Run organized script
create-migration-organized.bat "Add phone number"

# Output:
# ================================================
#   Migration Created Successfully!
# ================================================
#   File: V25__Add_phone_number.sql
#   Location: backend/src/main/resources/db/migration/2025
#   Year: 2025
#   Version: V25
# ================================================

# 2. Edit the file (automatically opens)

# 3. Preview & Validate
preview-migrations.bat
validate-migrations.bat

# 4. Test locally
mvn spring-boot:run

# 5. Commit
git add backend/src/main/resources/db/migration/2025/V25__*.sql
git commit -m "Migration: Add phone number"
git push
```

---

## 🎯 **How Flyway Scans Folders**

```
Spring Boot Starts
  ↓
Flyway Initialization
  ↓
Scans Configured Locations:
  - classpath:db/migration/
  - classpath:db/migration/2025/
  - classpath:db/migration/2026/
  ↓
Finds All Migrations:
  - V23 (in 2025 folder)
  - V24 (in 2025 folder)
  - V25 (in 2025 folder)
  - V28 (in 2026 folder)
  ↓
Checks flyway_schema_history:
  - V23: Applied ✓ (skip)
  - V24: Applied ✓ (skip)
  - V25: NEW! → Execute ✅
  - V28: NEW! → Execute ✅
  ↓
Migrations Applied
Database Updated ✅
```

**Flyway doesn't care about folders, it scans all configured locations!**

---

## 📋 **Adding New Year**

### **When 2026 arrives:**

**Step 1: Update application.yml**
```yaml
spring:
  flyway:
    locations: classpath:db/migration,classpath:db/migration/2025,classpath:db/migration/2026,classpath:db/migration/2027
    # Added 2027 ↑
```

**Step 2: Create migration normally**
```bash
create-migration-organized.bat "Add new column"
# Automatically creates in 2027 folder!
```

**That's it!** The script automatically detects the current year.

---

## 🔄 **Migrating Existing Files (Optional)**

If you want to move existing migrations to year folders:

```bash
# Create year folders
mkdir backend/src/main/resources/db/migration/2024
mkdir backend/src/main/resources/db/migration/2025

# Move old migrations (2024)
move backend/src/main/resources/db/migration/V3__*.sql backend/src/main/resources/db/migration/2024/
move backend/src/main/resources/db/migration/V4__*.sql backend/src/main/resources/db/migration/2024/

# Move recent migrations (2025)
move backend/src/main/resources/db/migration/V22__*.sql backend/src/main/resources/db/migration/2025/
move backend/src/main/resources/db/migration/V23__*.sql backend/src/main/resources/db/migration/2025/

# Update application.yml to include 2024 folder
```

**Important:** Test locally first! Ensure Flyway still finds all migrations.

---

## ⚠️ **Important Notes**

### **1. Version Numbers Still Sequential**
```
2025/V23__Add_phone.sql
2025/V24__Add_fee.sql
2026/V25__Add_email.sql  ← Continues from V24, not V1!
```

Version numbers are **global**, not per folder!

### **2. Flyway Scans All Folders**
```yaml
# Flyway scans ALL these locations:
locations:
  - classpath:db/migration
  - classpath:db/migration/2025
  - classpath:db/migration/2026
```

It combines all migrations from all folders.

### **3. Add New Folders to Config**
Every time you add a new year folder, update `application.yml`:

```yaml
# 2025: Add 2025 folder
locations: ...,classpath:db/migration/2025

# 2026: Add 2026 folder
locations: ...,classpath:db/migration/2025,classpath:db/migration/2026

# 2027: Add 2027 folder
locations: ...,classpath:db/migration/2025,classpath:db/migration/2026,classpath:db/migration/2027
```

---

## 🛠️ **Tools Update**

### **Updated Scripts:**
- ✅ `create-migration-organized.bat` - Creates in year folder
- ✅ `create-migration-organized.sh` - Linux/Mac version
- ✅ `preview-migrations.bat` - Works with folders
- ✅ `validate-migrations.bat` - Scans all folders

### **Original Scripts (Still work):**
- `create-migration.bat` - Creates in root folder
- You can use either approach!

---

## 📚 **Workflow Comparison**

### **With Organization (Recommended):**
```bash
# 1. Create migration (auto-organized)
create-migration-organized.bat "Add column"
# → Creates in: db/migration/2025/V25__Add_column.sql

# 2. Edit, preview, validate (same as before)
preview-migrations.bat
validate-migrations.bat

# 3. Push
git push

# 4. CI/CD deploys (works automatically!)
```

### **Without Organization (Original):**
```bash
# 1. Create migration (single folder)
create-migration.bat "Add column"
# → Creates in: db/migration/V25__Add_column.sql

# 2. Edit, preview, validate (same)
preview-migrations.bat
validate-migrations.bat

# 3. Push
git push

# 4. CI/CD deploys (works automatically!)
```

**Both work! Choose what you prefer.**

---

## ✅ **Summary**

### **Setup Complete:**
1. ✅ Flyway configured to scan year folders
2. ✅ New script `create-migration-organized.bat` available
3. ✅ Automatically creates in current year folder
4. ✅ CI/CD works with both approaches

### **Usage:**

**Option 1: Organized by year (recommended for large projects)**
```bash
create-migration-organized.bat "Description"
```

**Option 2: Simple single folder (easier for small projects)**
```bash
create-migration.bat "Description"
```

**Choose one approach and stick with it!**

---

## 📞 **Need Help?**

- **This guide:** Folder organization
- **Quick reference:** `DEPLOYMENT_QUICK_REFERENCE.md`
- **Master index:** `README_MIGRATIONS.md`

---

**Your migration files are now organized by year! 📁✨**
