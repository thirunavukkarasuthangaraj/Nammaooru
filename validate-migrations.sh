#!/bin/bash
# ============================================
# Migration Validation Script (Linux/Mac)
# Validates migration files before deployment
# ============================================

set -e

echo ""
echo "============================================"
echo "   DATABASE MIGRATION VALIDATION"
echo "============================================"
echo ""

MIGRATION_DIR="backend/src/main/resources/db/migration"
ERROR_COUNT=0
WARNING_COUNT=0

# Check if migration directory exists
if [ ! -d "$MIGRATION_DIR" ]; then
    echo "[ERROR] Migration directory not found: $MIGRATION_DIR"
    exit 1
fi

echo "[INFO] Checking migrations in: $MIGRATION_DIR"
echo ""

# Count migration files
FILE_COUNT=$(find "$MIGRATION_DIR" -name "V*.sql" | wc -l)

if [ $FILE_COUNT -eq 0 ]; then
    echo "[WARNING] No migration files found"
    ((WARNING_COUNT++))
else
    echo "[INFO] Found $FILE_COUNT migration files"
fi

echo ""
echo "============================================"
echo "   VALIDATION CHECKS"
echo "============================================"
echo ""

# Check 1: Migration file naming convention
echo "[CHECK 1] Validating file naming convention..."
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! [[ $filename =~ ^V[0-9]+__.*\.sql$ ]]; then
            echo "  [ERROR] Invalid naming: $filename"
            echo "          Expected: V{number}__{description}.sql"
            ((ERROR_COUNT++))
        fi
    fi
done
if [ $ERROR_COUNT -eq 0 ]; then
    echo "  [PASS] All files follow naming convention"
fi
echo ""

# Check 2: Check for duplicate version numbers
echo "[CHECK 2] Checking for duplicate version numbers..."
PREV_VERSION=0
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        VERSION_NUM=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
        if [ $VERSION_NUM -le $PREV_VERSION ]; then
            echo "  [ERROR] Duplicate or out-of-order version: $filename"
            ((ERROR_COUNT++))
        fi
        PREV_VERSION=$VERSION_NUM
    fi
done
if [ $ERROR_COUNT -eq 0 ]; then
    echo "  [PASS] No duplicate versions found"
fi
echo ""

# Check 3: Check for safe SQL patterns
echo "[CHECK 3] Checking for safe SQL patterns..."
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -iq "IF NOT EXISTS\|IF EXISTS\|CREATE TABLE IF NOT EXISTS" "$file"; then
            echo "  [WARNING] $filename may not have IF NOT EXISTS check"
            ((WARNING_COUNT++))
        fi
    fi
done
echo "  [INFO] Safe SQL pattern check complete"
echo ""

# Check 4: Check for dangerous operations
echo "[CHECK 4] Checking for dangerous operations..."
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if grep -iq "DROP TABLE\|TRUNCATE" "$file"; then
            echo "  [WARNING] $filename contains potentially dangerous operation"
            ((WARNING_COUNT++))
        fi
    fi
done
if [ $WARNING_COUNT -eq 0 ]; then
    echo "  [PASS] No dangerous operations detected"
fi
echo ""

# Check 5: Check for transaction blocks
echo "[CHECK 5] Verifying transaction safety..."
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if ! grep -iq "DO \$\$" "$file"; then
            echo "  [INFO] $filename: No DO block (may be simple DDL)"
        fi
    fi
done
echo "  [INFO] Transaction safety check complete"
echo ""

# Summary
echo "============================================"
echo "   VALIDATION SUMMARY"
echo "============================================"
echo "  Migration files: $FILE_COUNT"
echo "  Errors: $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"
echo "============================================"
echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    echo "[FAILED] Validation failed with $ERROR_COUNT error(s)"
    echo "Please fix the errors before deploying"
    exit 1
fi

if [ $WARNING_COUNT -gt 0 ]; then
    echo "[WARNING] Validation passed with $WARNING_COUNT warning(s)"
    echo "Review warnings before deploying"
    exit 0
fi

echo "[SUCCESS] All validations passed!"
exit 0
