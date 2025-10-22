#!/bin/bash
# ============================================
# Create Migration File (Organized by Year)
# Automatically creates in year folder
# ============================================

set -e

if [ -z "$1" ]; then
    echo "Usage: ./create-migration-organized.sh \"Migration description\""
    echo "Example: ./create-migration-organized.sh \"Add delivery fee column\""
    exit 1
fi

# Get current year
YEAR=$(date +%Y)

# Migration directory with year folder
MIGRATION_DIR="backend/src/main/resources/db/migration/$YEAR"

# Create year folder if it doesn't exist
if [ ! -d "$MIGRATION_DIR" ]; then
    echo "Creating directory: $MIGRATION_DIR"
    mkdir -p "$MIGRATION_DIR"
fi

# Find highest existing version number across ALL folders
MAX_VERSION=0
for file in backend/src/main/resources/db/migration/**/V*.sql; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        version=$(echo "$filename" | sed 's/V\([0-9]*\)__.*/\1/')
        if [ "$version" -gt "$MAX_VERSION" ]; then
            MAX_VERSION=$version
        fi
    fi
done

# Calculate next version
NEXT_VERSION=$((MAX_VERSION + 1))

# Clean description (replace spaces with underscores)
DESCRIPTION=$(echo "$1" | tr ' ' '_')

# Create filename
FILENAME="V${NEXT_VERSION}__${DESCRIPTION}.sql"
FILEPATH="$MIGRATION_DIR/$FILENAME"

# Create file with template
cat > "$FILEPATH" << EOF
-- Migration: $1
-- Version: V$NEXT_VERSION
-- Date: $(date)
-- Year: $YEAR

DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'YOUR_TABLE'
        AND column_name = 'YOUR_COLUMN'
    ) THEN
        ALTER TABLE YOUR_TABLE ADD COLUMN YOUR_COLUMN TYPE;
        RAISE NOTICE 'Added YOUR_COLUMN to YOUR_TABLE';
    ELSE
        RAISE NOTICE 'YOUR_COLUMN already exists in YOUR_TABLE, skipping';
    END IF;
END \$\$;
EOF

echo ""
echo "================================================"
echo "   Migration Created Successfully!"
echo "================================================"
echo "   File: $FILENAME"
echo "   Location: $MIGRATION_DIR"
echo "   Year: $YEAR"
echo "   Version: V$NEXT_VERSION"
echo "================================================"
echo ""
echo "Next steps:"
echo "   1. Edit: $FILEPATH"
echo "   2. Replace: YOUR_TABLE, YOUR_COLUMN, TYPE"
echo "   3. Test: mvn spring-boot:run"
echo "   4. Preview: ./preview-migrations.sh"
echo "   5. Validate: ./validate-migrations.sh"
echo "   6. Commit: git add $FILEPATH"
echo ""

# Open file in default editor (if available)
if command -v nano &> /dev/null; then
    nano "$FILEPATH"
elif command -v vi &> /dev/null; then
    vi "$FILEPATH"
else
    echo "Edit the file manually: $FILEPATH"
fi
