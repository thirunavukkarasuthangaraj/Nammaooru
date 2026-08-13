-- An FCM token identifies one physical device, so at most one user may hold an
-- ACTIVE mapping for it. Historical registrations created one active row per
-- user that ever logged in on the device. Keep only the newest active row per
-- token (the most recent login) and deactivate the rest. Idempotent.

UPDATE user_fcm_tokens t
SET is_active = false,
    updated_at = NOW()
WHERE t.is_active = true
  AND EXISTS (
      SELECT 1
      FROM user_fcm_tokens n
      WHERE n.fcm_token = t.fcm_token
        AND n.is_active = true
        AND n.id <> t.id
        AND (
            COALESCE(n.updated_at, n.created_at) > COALESCE(t.updated_at, t.created_at)
            OR (COALESCE(n.updated_at, n.created_at) = COALESCE(t.updated_at, t.created_at) AND n.id > t.id)
        )
  );
