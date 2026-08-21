-- Incoming WhatsApp messages (customer orders sent to the business number).
-- Filled by the Meta Cloud API webhook; shown in the admin "WhatsApp Orders"
-- inbox where staff convert them into POS bills.

CREATE TABLE IF NOT EXISTS whatsapp_incoming_messages (
    id BIGSERIAL PRIMARY KEY,
    wa_message_id VARCHAR(128) NOT NULL UNIQUE,
    from_number VARCHAR(20) NOT NULL,
    profile_name VARCHAR(120),
    message_type VARCHAR(30) NOT NULL,
    body TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'NEW',
    auto_replied BOOLEAN NOT NULL DEFAULT FALSE,
    received_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_incoming_status
    ON whatsapp_incoming_messages(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_incoming_from
    ON whatsapp_incoming_messages(from_number);
