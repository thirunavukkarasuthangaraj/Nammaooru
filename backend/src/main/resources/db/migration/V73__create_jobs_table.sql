-- V73: Create jobs table for employer job postings
-- Employers/shop owners post job openings; workers/job seekers apply by calling/WhatsApp

CREATE TABLE IF NOT EXISTS jobs (
    id                BIGSERIAL PRIMARY KEY,
    user_id           BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Job details
    job_title         VARCHAR(200) NOT NULL,
    company_name      VARCHAR(200) NOT NULL,
    category          VARCHAR(50)  NOT NULL DEFAULT 'OTHER',
    job_type          VARCHAR(30)  NOT NULL DEFAULT 'FULL_TIME', -- FULL_TIME, PART_TIME, CONTRACT, DAILY_WAGE, INTERNSHIP
    salary            VARCHAR(100),
    salary_type       VARCHAR(20)  DEFAULT 'MONTHLY',           -- MONTHLY, WEEKLY, DAILY, HOURLY, NEGOTIABLE
    vacancies         INT          DEFAULT 1,
    description       TEXT,
    requirements      TEXT,

    -- Contact & location
    phone             VARCHAR(20)  NOT NULL,
    location          VARCHAR(300),
    latitude          DECIMAL(10, 7),
    longitude         DECIMAL(10, 7),

    -- Images (comma-separated paths)
    image_urls        TEXT,

    -- Moderation & lifecycle
    status            VARCHAR(20)  NOT NULL DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED, EXPIRED
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    is_featured       BOOLEAN      NOT NULL DEFAULT FALSE,
    is_banner         BOOLEAN      NOT NULL DEFAULT FALSE,
    report_count      INT          NOT NULL DEFAULT 0,

    -- Expiry
    expires_at        TIMESTAMP,

    -- Timestamps
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jobs_user_id      ON jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status       ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_category     ON jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_location     ON jobs(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_jobs_created_at   ON jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_active       ON jobs(is_active, status);

-- Settings for jobs module (using the 'settings' table pattern from V65)
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'jobs.free_post_limit', '3', 'Number of free job postings allowed per user before payment', 'POST_LIMITS', 'INTEGER', 'GLOBAL', true, false, false, '3', 100, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'jobs.free_post_limit');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'jobs.max_images', '3', 'Maximum images per job posting', 'POST_LIMITS', 'INTEGER', 'GLOBAL', true, false, false, '3', 101, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'jobs.max_images');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'jobs.expiry_days', '30', 'Days before a job post expires automatically', 'POST_LIMITS', 'INTEGER', 'GLOBAL', true, false, false, '30', 102, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'jobs.expiry_days');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'jobs.moderation_enabled', 'true', 'Require admin approval before job posts go live', 'MODERATION', 'BOOLEAN', 'GLOBAL', true, false, false, 'true', 103, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'jobs.moderation_enabled');

COMMENT ON TABLE jobs IS 'Job postings by employers/shop owners seeking workers';
COMMENT ON COLUMN jobs.category IS 'SHOP_WORKER, SALES_PERSON, DELIVERY_BOY, SECURITY, CASHIER, RECEPTIONIST, ACCOUNTANT, DRIVER, COOK, HELPER, TEACHER, NURSE, TAILOR, CLEANER, WATCHMAN, FARM_WORKER, COMPUTER_OPERATOR, MANAGER, OTHER';
COMMENT ON COLUMN jobs.job_type IS 'FULL_TIME, PART_TIME, CONTRACT, DAILY_WAGE, INTERNSHIP';
COMMENT ON COLUMN jobs.salary_type IS 'MONTHLY, WEEKLY, DAILY, HOURLY, NEGOTIABLE';
