-- Update admin password to 'admin123'
-- BCrypt hash for 'admin123' with 10 rounds
UPDATE users 
SET password = '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy'
WHERE username = 'admin';

-- Verify the update
SELECT username, email, role, enabled FROM users WHERE username = 'admin';