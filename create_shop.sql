-- Create shop with ID 1 for testing
INSERT INTO shops (
    id, 
    name, 
    business_name, 
    description,
    owner_name, 
    owner_email, 
    owner_phone,
    address_line1,
    city,
    state,
    postal_code,
    country,
    business_type,
    status,
    is_active,
    created_at,
    updated_at
) VALUES (
    1,
    'Test Shop',
    'Test Business',
    'A test shop for development',
    'Shop Owner',
    'shopowner@test.com',
    '1234567890',
    '123 Test Street',
    'Test City',
    'Test State',
    '12345',
    'India',
    'RETAIL',
    'ACTIVE',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Reset sequence if needed
SELECT setval('shops_id_seq', 1, true);