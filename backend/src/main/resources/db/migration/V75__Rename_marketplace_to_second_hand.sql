-- Rename Marketplace to Second Hand in feature_configs
-- This updates the display name shown in the mobile app menu grid
UPDATE feature_configs
SET display_name       = 'Second Hand',
    display_name_tamil = 'பழைய பொருட்கள்'
WHERE feature_name = 'MARKETPLACE';
