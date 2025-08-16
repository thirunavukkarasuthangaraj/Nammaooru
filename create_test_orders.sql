-- Create test orders data
-- First, let's create some customers if they don't exist

INSERT INTO customers (name, email, phone, created_at, updated_at, created_by, updated_by)
SELECT * FROM (
    VALUES 
    ('Rahul Kumar', 'rahul.kumar@example.com', '9876543210', NOW(), NOW(), 'system', 'system'),
    ('Priya Sharma', 'priya.sharma@example.com', '9876543211', NOW(), NOW(), 'system', 'system'),
    ('Amit Singh', 'amit.singh@example.com', '9876543212', NOW(), NOW(), 'system', 'system'),
    ('Neha Gupta', 'neha.gupta@example.com', '9876543213', NOW(), NOW(), 'system', 'system'),
    ('Vikram Patel', 'vikram.patel@example.com', '9876543214', NOW(), NOW(), 'system', 'system')
) AS t(name, email, phone, created_at, updated_at, created_by, updated_by)
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = t.email);

-- Create customer addresses
INSERT INTO customer_addresses (customer_id, contact_name, phone, address_line1, address_line2, city, state, postal_code, is_default, created_at, updated_at, created_by, updated_by)
SELECT c.id, c.name, c.phone, addr_data.address_line1, addr_data.address_line2, addr_data.city, addr_data.state, addr_data.postal_code, addr_data.is_default, NOW(), NOW(), 'system', 'system'
FROM customers c
CROSS JOIN (
    VALUES 
    ('123 MG Road', 'Near Metro Station', 'Bangalore', 'Karnataka', '560001', true),
    ('456 Park Street', 'Opposite Mall', 'Mumbai', 'Maharashtra', '400001', true),
    ('789 CP', 'Central Delhi', 'New Delhi', 'Delhi', '110001', true),
    ('321 Civil Lines', 'Near Railway Station', 'Pune', 'Maharashtra', '411001', true),
    ('654 Sector 15', 'Gurgaon', 'Gurgaon', 'Haryana', '122001', true)
) AS addr_data(address_line1, address_line2, city, state, postal_code, is_default)
WHERE NOT EXISTS (SELECT 1 FROM customer_addresses WHERE customer_id = c.id);

-- Create test orders
WITH customer_data AS (
    SELECT id, email FROM customers WHERE email IN (
        'rahul.kumar@example.com', 
        'priya.sharma@example.com', 
        'amit.singh@example.com', 
        'neha.gupta@example.com', 
        'vikram.patel@example.com'
    )
),
shop_data AS (
    SELECT id, name FROM shops WHERE status = 'APPROVED' LIMIT 3
),
shop_product_data AS (
    SELECT sp.id, sp.shop_id, sp.price, p.name, p.description 
    FROM shop_products sp 
    JOIN products p ON sp.product_id = p.id 
    WHERE sp.shop_id IN (SELECT id FROM shop_data)
    LIMIT 10
)
INSERT INTO orders (
    order_number, status, payment_status, payment_method, 
    customer_id, customer_name, customer_email, customer_phone,
    shop_id, shop_name, shop_address,
    subtotal, tax_amount, delivery_fee, discount_amount, total_amount,
    delivery_address, delivery_city, delivery_state, delivery_postal_code,
    delivery_phone, delivery_contact_name, full_delivery_address,
    estimated_delivery_time, notes,
    created_at, updated_at, created_by, updated_by
)
SELECT 
    'ORD-' || LPAD((ROW_NUMBER() OVER())::text, 6, '0') as order_number,
    (ARRAY['PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'DELIVERED'])[1 + (random() * 5)::int] as status,
    (ARRAY['PENDING', 'PAID', 'FAILED'])[1 + (random() * 2)::int] as payment_status,
    (ARRAY['CASH_ON_DELIVERY', 'ONLINE_PAYMENT', 'UPI', 'CARD'])[1 + (random() * 3)::int] as payment_method,
    c.id as customer_id,
    cu.name as customer_name,
    c.email as customer_email,
    cu.phone as customer_phone,
    s.id as shop_id,
    s.name as shop_name,
    'Shop Address for ' || s.name as shop_address,
    (200 + random() * 800)::numeric(10,2) as subtotal,
    ((200 + random() * 800) * 0.18)::numeric(10,2) as tax_amount,
    (random() * 50)::numeric(10,2) as delivery_fee,
    (random() * 100)::numeric(10,2) as discount_amount,
    (200 + random() * 800 + (200 + random() * 800) * 0.18 + random() * 50 - random() * 100)::numeric(10,2) as total_amount,
    ca.address_line1 as delivery_address,
    ca.city as delivery_city,
    ca.state as delivery_state,
    ca.postal_code as delivery_postal_code,
    ca.phone as delivery_phone,
    ca.contact_name as delivery_contact_name,
    ca.address_line1 || ', ' || ca.city || ', ' || ca.state || ' - ' || ca.postal_code as full_delivery_address,
    NOW() + (random() * 24 || ' hours')::interval as estimated_delivery_time,
    'Test order - ' || (random() * 1000)::int as notes,
    NOW() - (random() * 30 || ' days')::interval as created_at,
    NOW() - (random() * 30 || ' days')::interval as updated_at,
    'system' as created_by,
    'system' as updated_by
FROM customer_data c
JOIN customers cu ON c.id = cu.id
JOIN customer_addresses ca ON c.id = ca.customer_id AND ca.is_default = true
CROSS JOIN shop_data s
LIMIT 15;

-- Create order items for the orders
WITH recent_orders AS (
    SELECT id, shop_id, total_amount FROM orders WHERE created_at > NOW() - interval '1 hour'
),
shop_products_with_details AS (
    SELECT sp.id, sp.shop_id, sp.price, p.name, p.description, p.sku, p.image_url
    FROM shop_products sp 
    JOIN products p ON sp.product_id = p.id 
    WHERE sp.shop_id IN (SELECT shop_id FROM recent_orders)
)
INSERT INTO order_items (
    order_id, shop_product_id, product_name, product_description, product_sku, product_image_url,
    quantity, unit_price, total_price, special_instructions,
    created_at, updated_at, created_by, updated_by
)
SELECT 
    o.id as order_id,
    spd.id as shop_product_id,
    spd.name as product_name,
    spd.description as product_description,
    spd.sku as product_sku,
    spd.image_url as product_image_url,
    (1 + random() * 3)::int as quantity,
    spd.price as unit_price,
    (spd.price * (1 + random() * 3)::int)::numeric(10,2) as total_price,
    CASE 
        WHEN random() > 0.7 THEN 'Please handle with care'
        WHEN random() > 0.8 THEN 'Extra spicy'
        WHEN random() > 0.9 THEN 'No onions please'
        ELSE NULL
    END as special_instructions,
    o.created_at,
    o.updated_at,
    'system' as created_by,
    'system' as updated_by
FROM recent_orders o
JOIN shop_products_with_details spd ON o.shop_id = spd.shop_id
WHERE random() > 0.3  -- Only add items to 70% of orders randomly
LIMIT 50;

-- Update orders with correct item counts
UPDATE orders 
SET item_count = (
    SELECT COUNT(*) 
    FROM order_items 
    WHERE order_items.order_id = orders.id
)
WHERE id IN (SELECT id FROM orders WHERE created_at > NOW() - interval '1 hour');

COMMIT;