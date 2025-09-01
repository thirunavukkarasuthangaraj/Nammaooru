-- Create superadmin user with password 'password'
INSERT INTO users (username, password, email, role, is_active, created_at, updated_at)
VALUES (
    'superadmin',
    '$2a$10$8K1p/a0dL1LXMIgoEDFrwOfMQbLgtnOoKIWuAy0nq4RM8cAA1mHL.',  -- BCrypt hash of 'password'
    'admin@nammaooru.com',
    'SUPER_ADMIN',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (username) 
DO UPDATE SET 
    password = '$2a$10$8K1p/a0dL1LXMIgoEDFrwOfMQbLgtnOoKIWuAy0nq4RM8cAA1mHL.',
    role = 'SUPER_ADMIN',
    is_active = true;

-- Verify the user was created
SELECT username, email, role, is_active FROM users WHERE username = 'superadmin';