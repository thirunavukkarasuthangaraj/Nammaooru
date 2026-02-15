-- Disable auto-approve for all post types - require admin review
UPDATE settings SET setting_value = 'false', default_value = 'false', updated_at = NOW()
WHERE setting_key = 'labours.post.auto_approve';

UPDATE settings SET setting_value = 'false', default_value = 'false', updated_at = NOW()
WHERE setting_key = 'travels.post.auto_approve';

UPDATE settings SET setting_value = 'false', default_value = 'false', updated_at = NOW()
WHERE setting_key = 'parcels.post.auto_approve';
