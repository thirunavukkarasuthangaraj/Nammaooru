-- Data Migration Script: Local to Docker PostgreSQL
-- This script will clean existing data and import from local database

-- Disable triggers and constraints for clean import
SET session_replication_role = replica;

-- Clear existing data in dependency order
TRUNCATE TABLE 
  delivery_tracking,
  order_assignments,
  order_items,
  orders,
  shop_product_images,
  shop_products,
  shop_images,
  shop_documents,
  shops,
  master_product_images,
  master_products,
  product_categories,
  delivery_partner_documents,
  partner_earnings,
  partner_availability,
  partner_zone_assignments,
  delivery_partners,
  delivery_zones,
  delivery_notifications,
  customer_addresses,
  customers,
  mobile_otps,
  notifications,
  password_reset_tokens,
  promotions,
  settings,
  user_permissions,
  users,
  permissions,
  analytics,
  business_hours
RESTART IDENTITY CASCADE;

-- Re-enable triggers and constraints
SET session_replication_role = DEFAULT;