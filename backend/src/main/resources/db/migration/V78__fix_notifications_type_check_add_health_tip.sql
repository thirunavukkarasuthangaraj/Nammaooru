-- Drop old notifications_type_check constraint that was missing HEALTH_TIP
-- and recreate it with all current NotificationType enum values.
--
-- Root cause: HEALTH_TIP was added to Java enum Notification.NotificationType later,
-- but the DB CHECK constraint (auto-generated earlier) was not updated.
-- Result: sending a health tip succeeded at push time but failed to persist the row.

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
    ADD CONSTRAINT notifications_type_check
    CHECK (type IN (
        'INFO',
        'SUCCESS',
        'WARNING',
        'ERROR',
        'ORDER',
        'ORDER_UPDATE',
        'PAYMENT',
        'SYSTEM',
        'PROMOTION',
        'REMINDER',
        'ANNOUNCEMENT',
        'HEALTH_TIP'
    ));
