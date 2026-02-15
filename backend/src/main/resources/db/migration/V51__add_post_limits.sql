-- Add global post limit per user to feature_configs
ALTER TABLE feature_configs ADD COLUMN max_posts_per_user INTEGER DEFAULT 0;

-- Create user-specific post limits table
CREATE TABLE user_post_limits (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    feature_name VARCHAR(50) NOT NULL,
    max_posts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT uk_user_feature UNIQUE (user_id, feature_name),
    CONSTRAINT fk_user_post_limits_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_user_post_limits_user_id ON user_post_limits(user_id);
CREATE INDEX idx_user_post_limits_feature ON user_post_limits(feature_name);
