-- WhatsApp orders can be routed to a specific shop: admin (or any staff)
-- assigns the incoming message to the shop that will fulfil it.
-- shop_name is denormalized so the inbox list needs no join.

ALTER TABLE whatsapp_incoming_messages ADD COLUMN IF NOT EXISTS shop_id BIGINT;
ALTER TABLE whatsapp_incoming_messages ADD COLUMN IF NOT EXISTS shop_name VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_whatsapp_incoming_shop
    ON whatsapp_incoming_messages(shop_id);
