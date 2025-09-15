-- Insert test orders for shop_id = 2
-- First, let's check if there's a customer to use
INSERT INTO orders (
    order_number,
    customer_id,
    shop_id,
    status,
    payment_status,
    payment_method,
    subtotal,
    tax_amount,
    delivery_fee,
    total_amount,
    delivery_address,
    delivery_city,
    delivery_contact_name,
    delivery_phone,
    created_at,
    updated_at
) VALUES
-- Pending Order
('ORD001', 1, 2, 'PENDING', 'PENDING', 'CASH_ON_DELIVERY', 150.0, 15.0, 20.0, 185.0, '123 Main Street, Near City Mall', 'Chennai', 'Thiru User', '8144002155', NOW(), NOW()),

-- Confirmed Order
('ORD002', 1, 2, 'CONFIRMED', 'PENDING', 'CASH_ON_DELIVERY', 200.0, 20.0, 25.0, 245.0, '456 Park Avenue', 'Chennai', 'Raj Kumar', '9876543210', NOW() - INTERVAL '30 minutes', NOW()),

-- Preparing Order
('ORD003', 1, 2, 'PREPARING', 'PAID', 'ONLINE', 180.0, 18.0, 20.0, 218.0, '789 Beach Road', 'Chennai', 'Priya Sharma', '9123456789', NOW() - INTERVAL '45 minutes', NOW()),

-- Ready for Pickup
('ORD004', 1, 2, 'READY_FOR_PICKUP', 'PAID', 'ONLINE', 300.0, 30.0, 30.0, 360.0, '321 Temple Street', 'Chennai', 'John Doe', '9988776655', NOW() - INTERVAL '1 hour', NOW()),

-- Delivered Order (for today's revenue)
('ORD005', 1, 2, 'DELIVERED', 'PAID', 'CASH_ON_DELIVERY', 250.0, 25.0, 20.0, 295.0, '654 Market Road', 'Chennai', 'Mary Smith', '9876501234', NOW() - INTERVAL '2 hours', NOW());

-- Insert order items for each order
INSERT INTO order_items (
    order_id,
    shop_product_id,
    product_name,
    product_sku,
    product_description,
    product_image_url,
    quantity,
    unit_price,
    total_price,
    special_instructions,
    created_at,
    updated_at
) VALUES
-- Items for Order 1 (PENDING)
((SELECT id FROM orders WHERE order_number = 'ORD001'), 1, 'Coffee', 'COFFEE001', 'Fresh brewed coffee', '/images/coffee.jpg', 1, 10.0, 10.0, 'Extra sugar', NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD001'), 2, 'ABC Snack', 'ABC001', 'Crunchy snack', '/images/abc.jpg', 1, 100.0, 100.0, '', NOW(), NOW()),

-- Items for Order 2 (CONFIRMED)
((SELECT id FROM orders WHERE order_number = 'ORD002'), 1, 'Chicken Biryani', 'BIRYANI001', 'Spicy chicken biryani', '/images/biryani.jpg', 1, 250.0, 250.0, 'Extra spicy', NOW(), NOW()),

-- Items for Order 3 (PREPARING)
((SELECT id FROM orders WHERE order_number = 'ORD003'), 1, 'Masala Dosa', 'DOSA001', 'South Indian dosa', '/images/dosa.jpg', 2, 80.0, 160.0, 'Crispy', NOW(), NOW()),

-- Items for Order 4 (READY_FOR_PICKUP)
((SELECT id FROM orders WHERE order_number = 'ORD004'), 1, 'Paneer Butter Masala', 'PANEER001', 'Rich paneer curry', '/images/paneer.jpg', 1, 180.0, 180.0, 'Medium spice', NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD004'), 2, 'Naan', 'NAAN001', 'Butter naan', '/images/naan.jpg', 2, 40.0, 80.0, 'Extra butter', NOW(), NOW()),

-- Items for Order 5 (DELIVERED)
((SELECT id FROM orders WHERE order_number = 'ORD005'), 1, 'Chicken Curry', 'CHICKEN001', 'Traditional chicken curry', '/images/chicken.jpg', 1, 200.0, 200.0, 'Home style', NOW(), NOW());