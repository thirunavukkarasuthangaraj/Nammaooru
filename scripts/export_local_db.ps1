# PowerShell script to export PostgreSQL database
Write-Host "🚀 Exporting Local PostgreSQL Database..." -ForegroundColor Green

# Configuration
$PGPATH = "C:\Program Files\PostgreSQL\15\bin"
$PGHOST = "localhost"
$PGPORT = "5432"
$PGUSER = "postgres"
$PGDATABASE = "shop_management_db"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

# Create exports directory
$ExportDir = "database\exports"
if (!(Test-Path $ExportDir)) {
    New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
}

Write-Host "📦 Creating complete database backup..." -ForegroundColor Yellow
& "$PGPATH\pg_dump.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE --clean --if-exists > "$ExportDir\complete_backup_$TIMESTAMP.sql"

Write-Host "📊 Creating data-only backup..." -ForegroundColor Yellow
& "$PGPATH\pg_dump.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE --data-only --inserts --disable-triggers > "$ExportDir\data_only_$TIMESTAMP.sql"

Write-Host "🗂️ Creating schema-only backup..." -ForegroundColor Yellow
& "$PGPATH\pg_dump.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE --schema-only > "$ExportDir\schema_only_$TIMESTAMP.sql"

Write-Host "📋 Exporting individual tables as CSV..." -ForegroundColor Yellow

# Define tables to export
$Tables = @(
    "users",
    "customers", 
    "orders",
    "order_items",
    "shops",
    "product_categories",
    "master_products",
    "shop_products",
    "delivery_partners",
    "order_assignments",
    "delivery_tracking"
)

foreach ($Table in $Tables) {
    Write-Host "  → Exporting $Table..." -ForegroundColor Cyan
    & "$PGPATH\psql.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -c "COPY $Table TO STDOUT WITH CSV HEADER;" > "$ExportDir\${Table}_$TIMESTAMP.csv"
}

Write-Host "📈 Creating database statistics report..." -ForegroundColor Yellow
$StatsQuery = @"
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
"@

& "$PGPATH\psql.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -c $StatsQuery > "$ExportDir\db_stats_$TIMESTAMP.txt"

# Create table counts report
Write-Host "📊 Creating table counts report..." -ForegroundColor Yellow
$CountQuery = @"
SELECT 
    'users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 
    'customers' as table_name, COUNT(*) as count FROM customers
UNION ALL SELECT 
    'orders' as table_name, COUNT(*) as count FROM orders
UNION ALL SELECT 
    'shops' as table_name, COUNT(*) as count FROM shops
UNION ALL SELECT 
    'master_products' as table_name, COUNT(*) as count FROM master_products
UNION ALL SELECT 
    'product_categories' as table_name, COUNT(*) as count FROM product_categories
ORDER BY count DESC;
"@

& "$PGPATH\psql.exe" -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -c $CountQuery > "$ExportDir\table_counts_$TIMESTAMP.txt"

Write-Host "✅ Export completed successfully!" -ForegroundColor Green
Write-Host "📁 Files saved in: $ExportDir" -ForegroundColor Green  
Write-Host "🕐 Timestamp: $TIMESTAMP" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Summary of exports created:" -ForegroundColor White
Write-Host "  - complete_backup_$TIMESTAMP.sql (Full database with schema + data)" -ForegroundColor Gray
Write-Host "  - data_only_$TIMESTAMP.sql (Data only with INSERT statements)" -ForegroundColor Gray
Write-Host "  - schema_only_$TIMESTAMP.sql (Table structures only)" -ForegroundColor Gray
Write-Host "  - *.csv files (Individual table data)" -ForegroundColor Gray
Write-Host "  - db_stats_$TIMESTAMP.txt (Database statistics)" -ForegroundColor Gray
Write-Host "  - table_counts_$TIMESTAMP.txt (Record counts per table)" -ForegroundColor Gray

# Show file sizes
Write-Host ""
Write-Host "📁 Export file sizes:" -ForegroundColor White
Get-ChildItem $ExportDir -Filter "*$TIMESTAMP*" | ForEach-Object {
    $SizeKB = [math]::Round($_.Length / 1KB, 2)
    Write-Host "  $($_.Name): ${SizeKB} KB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🚀 Ready for Docker import!" -ForegroundColor Green
Write-Host "To import to Docker: docker exec -i shop-postgres psql -U postgres -d shop_management_db < $ExportDir\complete_backup_$TIMESTAMP.sql" -ForegroundColor Yellow