-- Correction to V107: the category should be "Daily Motivation", not "Daily Tips".
UPDATE womens_corner_categories
SET name = 'Daily Motivation', tamil_name = 'தினசரி உத்வேகம்'
WHERE name = 'Daily Tips';
