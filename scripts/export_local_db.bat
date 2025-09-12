@echo off
echo 🚀 Exporting Local PostgreSQL Database...

REM Set PostgreSQL paths and connection details
set PGPATH="C:\Program Files\PostgreSQL\15\bin"
set PGHOST=localhost
set PGPORT=5432
set PGUSER=postgres
set PGDATABASE=shop_management_db

REM Create exports directory if it doesn't exist
if not exist "database\exports" mkdir "database\exports"

REM Get current timestamp for filenames
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do (
    for /f "tokens=1-3 delims=: " %%l in ("%time%") do (
        set TIMESTAMP=%%k%%j%%i_%%l%%m
    )
)

echo 📦 Creating complete database backup...
%PGPATH%\pg_dump.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% --clean --if-exists --verbose > "database\exports\complete_backup_%TIMESTAMP%.sql"

echo 📊 Creating data-only backup...
%PGPATH%\pg_dump.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% --data-only --inserts --disable-triggers > "database\exports\data_only_%TIMESTAMP%.sql"

echo 🗂️ Creating schema-only backup...
%PGPATH%\pg_dump.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% --schema-only > "database\exports\schema_only_%TIMESTAMP%.sql"

echo 📋 Exporting individual tables as CSV...

REM Core business tables
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY users TO STDOUT WITH CSV HEADER;" > "database\exports\users_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY customers TO STDOUT WITH CSV HEADER;" > "database\exports\customers_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY orders TO STDOUT WITH CSV HEADER;" > "database\exports\orders_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY order_items TO STDOUT WITH CSV HEADER;" > "database\exports\order_items_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY shops TO STDOUT WITH CSV HEADER;" > "database\exports\shops_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY product_categories TO STDOUT WITH CSV HEADER;" > "database\exports\product_categories_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY master_products TO STDOUT WITH CSV HEADER;" > "database\exports\master_products_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY shop_products TO STDOUT WITH CSV HEADER;" > "database\exports\shop_products_%TIMESTAMP%.csv"

REM Additional important tables
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY delivery_partners TO STDOUT WITH CSV HEADER;" > "database\exports\delivery_partners_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY order_assignments TO STDOUT WITH CSV HEADER;" > "database\exports\order_assignments_%TIMESTAMP%.csv"
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "COPY delivery_tracking TO STDOUT WITH CSV HEADER;" > "database\exports\delivery_tracking_%TIMESTAMP%.csv"

echo 📈 Creating database statistics report...
%PGPATH%\psql.exe -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "
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
" > "database\exports\db_stats_%TIMESTAMP%.txt"

echo ✅ Export completed successfully!
echo 📁 Files saved in: database\exports\
echo 🕐 Timestamp: %TIMESTAMP%

echo.
echo 📋 Summary of exports created:
echo   - complete_backup_%TIMESTAMP%.sql (Full database with schema + data)
echo   - data_only_%TIMESTAMP%.sql (Data only with INSERT statements)
echo   - schema_only_%TIMESTAMP%.sql (Table structures only)
echo   - *.csv files (Individual table data)
echo   - db_stats_%TIMESTAMP%.txt (Database statistics)

pause