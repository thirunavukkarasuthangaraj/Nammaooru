-- BCrypt hash for 'password123' generated using Spring Security
-- This hash is compatible with Spring Boot BCryptPasswordEncoder
UPDATE users 
SET password = '$2a$10$eImiTXuWVxfM37uY4JANjOQxr1TnDQs8vZXrPjSKPqYFvZfG5KQJm'
WHERE role IN ('SUPER_ADMIN', 'ADMIN', 'SHOP_OWNER', 'CUSTOMER', 'DELIVERY_PARTNER', 'USER');

-- Verify the update
SELECT username, email, role, LEFT(password, 20) as pwd_start 
FROM users 
WHERE role IN ('SUPER_ADMIN', 'ADMIN', 'SHOP_OWNER', 'CUSTOMER', 'USER')
ORDER BY role, username;