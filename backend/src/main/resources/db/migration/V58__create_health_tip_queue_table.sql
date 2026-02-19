-- Create health_tip_queue table for daily Tamil health tip notifications
CREATE TABLE IF NOT EXISTS health_tip_queue (
    id BIGSERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    scheduled_date DATE,
    sent_at TIMESTAMP,
    approved_by VARCHAR(100),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_health_tip_queue_status ON health_tip_queue(status);
CREATE INDEX idx_health_tip_queue_scheduled_date ON health_tip_queue(scheduled_date);
