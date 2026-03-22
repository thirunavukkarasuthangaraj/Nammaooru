CREATE TABLE IF NOT EXISTS contact_views (
    id BIGSERIAL PRIMARY KEY,
    viewer_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    viewer_name VARCHAR(200),
    viewer_phone VARCHAR(20),
    post_type VARCHAR(50) NOT NULL,
    post_id BIGINT NOT NULL,
    post_title VARCHAR(500),
    seller_phone VARCHAR(20),
    viewed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contact_views_post ON contact_views(post_type, post_id);
CREATE INDEX idx_contact_views_viewer ON contact_views(viewer_user_id);
CREATE INDEX idx_contact_views_viewed_at ON contact_views(viewed_at DESC);
