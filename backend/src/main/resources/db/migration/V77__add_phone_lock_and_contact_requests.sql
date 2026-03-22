-- Add phone_locked flag to womens_corner_posts
ALTER TABLE womens_corner_posts ADD COLUMN IF NOT EXISTS phone_locked BOOLEAN NOT NULL DEFAULT FALSE;

-- Contact requests table (buyer requests permission to see phone number)
CREATE TABLE IF NOT EXISTS contact_requests (
    id BIGSERIAL PRIMARY KEY,
    requester_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requester_name VARCHAR(200),
    requester_phone VARCHAR(20),
    post_type VARCHAR(50) NOT NULL,
    post_id BIGINT NOT NULL,
    post_title VARCHAR(500),
    post_owner_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, APPROVED, DENIED
    message VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMP,
    UNIQUE(requester_user_id, post_type, post_id)
);

CREATE INDEX idx_contact_requests_owner ON contact_requests(post_owner_user_id, status);
CREATE INDEX idx_contact_requests_requester ON contact_requests(requester_user_id);
CREATE INDEX idx_contact_requests_post ON contact_requests(post_type, post_id);
