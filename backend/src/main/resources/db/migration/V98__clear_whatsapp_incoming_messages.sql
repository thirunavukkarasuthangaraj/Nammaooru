-- Full reset of WhatsApp inbox data (test/dummy entries accumulated during
-- development). Removes ALL rows — real and test — and restarts the id
-- sequence so new messages start fresh from 1.
-- No other table has a foreign key into whatsapp_incoming_messages, so this
-- is safe with no cascading effects.

TRUNCATE TABLE whatsapp_incoming_messages RESTART IDENTITY;
