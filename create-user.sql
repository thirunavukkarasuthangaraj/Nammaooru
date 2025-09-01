-- Run this in your PostgreSQL client (pgAdmin, psql, etc.)

INSERT INTO users (username, password, email, role, is_active, created_at, updated_at) 
VALUES (
    'superadmin', 
    '$2a$10$8K1p/a0dL1LXMIgoEDFrwOfMQbLgtnOoKIWuAy0nq4RM8cAA1mHL.',  -- password: "password"
    'admin@test.com', 
    'SUPER_ADMIN', 
    true, 
    NOW(), 
    NOW()
) 
ON CONFLICT (username) DO NOTHING;

-- Verify the user was created
SELECT username, email, role, is_active FROM users WHERE username = 'superadmin';