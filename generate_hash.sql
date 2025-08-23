-- Update superadmin with BCrypt hash for password: nammaooru@2025
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, created_at, updated_at) 
VALUES ('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRr.Vl.I.u4qEy8Rf6OOr/kYC1TqQOUl6Hj7TC', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (username) DO UPDATE SET 
password = '$2a$10$N9qo8uLOickgx2ZMRr.Vl.I.u4qEy8Rf6OOr/kYC1TqQOUl6Hj7TC', 
role = 'SUPER_ADMIN', 
status = 'ACTIVE', 
is_active = true,
email = 'superadmin@shopmanagement.com';

-- Verify the user was created/updated
SELECT username, email, role, status, is_active FROM users WHERE username = 'superadmin';