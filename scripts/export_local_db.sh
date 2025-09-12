#!/bin/bash

echo "🚀 Exporting Local PostgreSQL Database..."

# Configuration
PGHOST="localhost"
PGPORT="5432"
PGUSER="postgres"
PGDATABASE="shop_management_db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create exports directory
mkdir -p database/exports

echo "📦 Creating complete database backup..."
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    --clean --if-exists --verbose \
    > "database/exports/complete_backup_$TIMESTAMP.sql"

echo "📊 Creating data-only backup..."
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    --data-only --inserts --disable-triggers \
    > "database/exports/data_only_$TIMESTAMP.sql"

echo "🗂️ Creating schema-only backup..."
pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    --schema-only \
    > "database/exports/schema_only_$TIMESTAMP.sql"

echo "📋 Exporting individual tables as CSV..."

# Core business tables
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY users TO STDOUT WITH CSV HEADER;" \
    > "database/exports/users_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY customers TO STDOUT WITH CSV HEADER;" \
    > "database/exports/customers_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY orders TO STDOUT WITH CSV HEADER;" \
    > "database/exports/orders_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY order_items TO STDOUT WITH CSV HEADER;" \
    > "database/exports/order_items_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY shops TO STDOUT WITH CSV HEADER;" \
    > "database/exports/shops_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY product_categories TO STDOUT WITH CSV HEADER;" \
    > "database/exports/product_categories_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY master_products TO STDOUT WITH CSV HEADER;" \
    > "database/exports/master_products_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY shop_products TO STDOUT WITH CSV HEADER;" \
    > "database/exports/shop_products_$TIMESTAMP.csv"

# Additional important tables
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY delivery_partners TO STDOUT WITH CSV HEADER;" \
    > "database/exports/delivery_partners_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY order_assignments TO STDOUT WITH CSV HEADER;" \
    > "database/exports/order_assignments_$TIMESTAMP.csv"

psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    -c "COPY delivery_tracking TO STDOUT WITH CSV HEADER;" \
    > "database/exports/delivery_tracking_$TIMESTAMP.csv"

echo "📈 Creating database statistics report..."
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows
FROM pg_stat_user_tables 
ORDER BY live_rows DESC;
" > "database/exports/db_stats_$TIMESTAMP.txt"

echo "✅ Export completed successfully!"
echo "📁 Files saved in: database/exports/"
echo "🕐 Timestamp: $TIMESTAMP"

echo ""
echo "📋 Summary of exports created:"
echo "  - complete_backup_$TIMESTAMP.sql (Full database with schema + data)"
echo "  - data_only_$TIMESTAMP.sql (Data only with INSERT statements)"
echo "  - schema_only_$TIMESTAMP.sql (Table structures only)"
echo "  - *.csv files (Individual table data)"
echo "  - db_stats_$TIMESTAMP.txt (Database statistics)"