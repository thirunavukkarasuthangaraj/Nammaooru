-- Fix test user passwords with proper BCrypt hash for 'password'
UPDATE users 
SET password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
WHERE username IN ('customer1', 'shopowner1', 'delivery1', 'admin', 'superadmin');