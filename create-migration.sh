#!/bin/bash
# Automated Database Migration Creator
# Usage: ./create-migration.sh "Add user status column"

if [ -z "$1" ]; then
    echo "Error: Please provide a migration description"
    echo "Usage: ./create-migration.sh \"Your migration description\""
    echo "Example: ./create-migration.sh \"Add user status column\""
    exit 1
fi

# Get migration description
DESCRIPTION="$1"

# Replace spaces with underscores
DESCRIPTION_UNDERSCORED="${DESCRIPTION// /_}"

# Find the highest version number
MAX_VERSION=0
for file in backend/src/main/resources/db/migration/V*.sql; do
    if [ -f "$file" ]; then
        FILENAME=$(basename "$file")
        VERSION="${FILENAME#V}"
        VERSION="${VERSION%%__*}"
        if [ "$VERSION" -gt "$MAX_VERSION" ]; then
            MAX_VERSION=$VERSION
        fi
    fi
done

# Calculate next version
NEXT_VERSION=$((MAX_VERSION + 1))

# Create filename
FILENAME="V${NEXT_VERSION}__${DESCRIPTION_UNDERSCORED}.sql"
FILEPATH="backend/src/main/resources/db/migration/${FILENAME}"

# Create the migration file with template
cat > "$FILEPATH" <<EOF
-- Migration: ${DESCRIPTION}
-- Version: V${NEXT_VERSION}
-- Created: $(date)
--
-- TODO: Add your SQL statements below

-- Example:
-- ALTER TABLE users ADD COLUMN status VARCHAR(50);

EOF

echo ""
echo "============================================"
echo "✅ Migration file created successfully!"
echo "============================================"
echo ""
echo "File: ${FILENAME}"
echo "Location: ${FILEPATH}"
echo ""
echo "Next steps:"
echo "1. Edit the file and add your SQL"
echo "2. Run backend to test locally"
echo "3. git add ${FILEPATH}"
echo "4. git commit -m \"Migration: ${DESCRIPTION}\""
echo "5. git push (CI/CD will auto-apply to production)"
echo ""

# Open the file in default editor
if command -v code &> /dev/null; then
    code "$FILEPATH"
elif command -v nano &> /dev/null; then
    nano "$FILEPATH"
else
    vi "$FILEPATH"
fi
