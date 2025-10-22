#!/bin/bash
# ============================================
# Preview Migration Files Before Deployment
# Shows what will be deployed to production
# ============================================

echo ""
echo "============================================"
echo "   MIGRATION FILES PREVIEW"
echo "============================================"
echo ""

MIGRATION_DIR="backend/src/main/resources/db/migration"

if [ ! -d "$MIGRATION_DIR" ]; then
    echo "[ERROR] Migration directory not found: $MIGRATION_DIR"
    exit 1
fi

# Count files
FILE_COUNT=$(find "$MIGRATION_DIR" -name "V*.sql" | wc -l)

echo "[INFO] Found $FILE_COUNT migration file(s) in:"
echo "       $MIGRATION_DIR"
echo ""

if [ $FILE_COUNT -eq 0 ]; then
    echo "[INFO] No migration files to deploy"
    echo ""
    exit 0
fi

echo "============================================"
echo "   MIGRATION FILES LIST"
echo "============================================"
echo ""

INDEX=1
for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "[$INDEX] $filename"
        ((INDEX++))
    fi
done

echo ""
echo "============================================"
echo "   FILE CONTENTS PREVIEW"
echo "============================================"
echo ""

for file in "$MIGRATION_DIR"/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo ""
        echo "╔════════════════════════════════════════════════════════════════"
        echo "║ FILE: $filename"
        echo "╚════════════════════════════════════════════════════════════════"
        echo ""
        cat "$file"
        echo ""
        echo "────────────────────────────────────────────────────────────────"
        echo ""
    fi
done

echo ""
echo "============================================"
echo "   DEPLOYMENT PREVIEW COMPLETE"
echo "============================================"
echo ""
echo "These $FILE_COUNT migration file(s) will be deployed"
echo ""
echo "Next steps:"
echo "  1. Review the files above"
echo "  2. Verify they are correct"
echo "  3. Run: ./validate-migrations.sh"
echo "  4. If OK, deploy: git push"
echo ""
