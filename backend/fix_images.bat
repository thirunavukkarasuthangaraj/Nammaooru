@echo off
set PGPASSWORD=shop_password
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -h localhost -p 5432 -U shop_user -d shop_management -c "UPDATE master_product_images SET image_url = REPLACE(image_url, ':8082/', ':8080/') WHERE image_url LIKE '%%:8082/%%'; SELECT COUNT(*) as updated_rows FROM master_product_images WHERE image_url LIKE '%%:8080/%%';"
pause