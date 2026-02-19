-- Fix existing users with NULL health_tip_notifications_enabled (V59 only set DEFAULT for new rows)
UPDATE users SET health_tip_notifications_enabled = true WHERE health_tip_notifications_enabled IS NULL;
