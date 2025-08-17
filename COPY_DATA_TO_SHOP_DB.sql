-- =====================================================
-- COPY ALL DATA FROM postgres DB TO shop_management_db
-- Run this in pgAdmin connected to shop_management_db
-- =====================================================

-- First, let's check what data exists in postgres database
-- You may need to switch between databases in pgAdmin

-- Step 1: Connect to postgres database and export data
-- Step 2: Connect to shop_management_db and import data

-- =====================================================
-- RUN THIS IN shop_management_db DATABASE
-- =====================================================

-- Clear existing data (BE CAREFUL!)
TRUNCATE TABLE delivery_tracking CASCADE;
TRUNCATE TABLE order_assignments CASCADE;
TRUNCATE TABLE delivery_partners CASCADE;
TRUNCATE TABLE delivery_zones CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE customers CASCADE;
TRUNCATE TABLE users CASCADE;

-- Insert Users from postgres database
-- Note: You'll need to copy this data from postgres.users table
INSERT INTO users (id, username, email, password, first_name, last_name, role, status, is_active, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at, created_by, updated_by)
SELECT id, username, email, password, first_name, last_name, role, status, 
       COALESCE(is_active, true) as is_active,  -- Fix NULL values
       COALESCE(email_verified, false) as email_verified,
       COALESCE(mobile_verified, false) as mobile_verified,
       COALESCE(two_factor_enabled, false) as two_factor_enabled,
       COALESCE(failed_login_attempts, 0) as failed_login_attempts,
       COALESCE(password_change_required, false) as password_change_required,
       COALESCE(is_temporary_password, false) as is_temporary_password,
       created_at, updated_at, created_by, updated_by
FROM dblink('dbname=postgres host=localhost user=postgres password=password',
            'SELECT * FROM users')
AS t(id bigint, username varchar, email varchar, password varchar, first_name varchar, last_name varchar, 
     role varchar, status varchar, is_active boolean, email_verified boolean, mobile_verified boolean,
     two_factor_enabled boolean, failed_login_attempts integer, password_change_required boolean,
     is_temporary_password boolean, created_at timestamp, updated_at timestamp, 
     created_by varchar, updated_by varchar);

-- Insert Customers
INSERT INTO customers (id, first_name, last_name, email, mobile_number, address_line1, address_line2, city, state, postal_code, country, date_of_birth, gender, latitude, longitude, status, is_active, is_verified, created_at, updated_at, created_by, updated_by)
SELECT * FROM dblink('dbname=postgres host=localhost user=postgres password=password',
                     'SELECT * FROM customers')
AS t(id bigint, first_name varchar, last_name varchar, email varchar, mobile_number varchar,
     address_line1 varchar, address_line2 varchar, city varchar, state varchar, postal_code varchar,
     country varchar, date_of_birth date, gender varchar, latitude numeric, longitude numeric,
     status varchar, is_active boolean, is_verified boolean, created_at timestamp, updated_at timestamp,
     created_by varchar, updated_by varchar);

-- Insert Delivery Zones
INSERT INTO delivery_zones (id, zone_code, zone_name, boundaries, delivery_fee, min_order_amount, max_delivery_time, is_active, service_start_time, service_end_time, created_at, updated_at)
SELECT * FROM dblink('dbname=postgres host=localhost user=postgres password=password',
                     'SELECT * FROM delivery_zones')
AS t(id bigint, zone_code varchar, zone_name varchar, boundaries jsonb, delivery_fee numeric,
     min_order_amount numeric, max_delivery_time integer, is_active boolean,
     service_start_time time, service_end_time time, created_at timestamp, updated_at timestamp);

-- Insert Delivery Partners  
INSERT INTO delivery_partners (id, partner_id, user_id, full_name, phone_number, email, date_of_birth, gender, address_line1, address_line2, city, state, postal_code, country, vehicle_type, vehicle_number, vehicle_model, vehicle_color, license_number, license_expiry_date, bank_account_number, bank_ifsc_code, bank_name, account_holder_name, max_delivery_radius, status, verification_status, is_online, is_available, rating, total_deliveries, successful_deliveries, total_earnings, current_latitude, current_longitude, last_location_update, last_seen, created_at, updated_at, created_by, updated_by)
SELECT * FROM dblink('dbname=postgres host=localhost user=postgres password=password',
                     'SELECT * FROM delivery_partners')
AS t(id bigint, partner_id varchar, user_id bigint, full_name varchar, phone_number varchar, email varchar,
     date_of_birth date, gender varchar, address_line1 varchar, address_line2 varchar, city varchar,
     state varchar, postal_code varchar, country varchar, vehicle_type varchar, vehicle_number varchar,
     vehicle_model varchar, vehicle_color varchar, license_number varchar, license_expiry_date date,
     bank_account_number varchar, bank_ifsc_code varchar, bank_name varchar, account_holder_name varchar,
     max_delivery_radius numeric, status varchar, verification_status varchar, is_online boolean,
     is_available boolean, rating numeric, total_deliveries integer, successful_deliveries integer,
     total_earnings numeric, current_latitude numeric, current_longitude numeric,
     last_location_update timestamp, last_seen timestamp, created_at timestamp, updated_at timestamp,
     created_by varchar, updated_by varchar);

-- Reset sequences to continue from the highest ID
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SELECT setval('customers_id_seq', (SELECT MAX(id) FROM customers));
SELECT setval('delivery_zones_id_seq', (SELECT MAX(id) FROM delivery_zones));
SELECT setval('delivery_partners_id_seq', (SELECT MAX(id) FROM delivery_partners));

-- Verify the data transfer
SELECT 'Data Transfer Summary:' as info;
SELECT 'Users: ' || COUNT(*) as count FROM users;
SELECT 'Customers: ' || COUNT(*) as count FROM customers;
SELECT 'Delivery Zones: ' || COUNT(*) as count FROM delivery_zones;
SELECT 'Delivery Partners: ' || COUNT(*) as count FROM delivery_partners;

-- Fix any NULL is_active fields
UPDATE users SET is_active = true WHERE is_active IS NULL;

-- Show test accounts
SELECT 'Test Accounts Ready:' as info;
SELECT username, role, is_active, status FROM users ORDER BY role, username;