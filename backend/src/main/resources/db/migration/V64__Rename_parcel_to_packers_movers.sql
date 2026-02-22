-- Rename "Parcel Service" to "Packers & Movers" in feature_configs (dashboard display)
UPDATE feature_configs
SET display_name = 'Packers & Movers',
    display_name_tamil = 'பேக்கர்ஸ் & மூவர்ஸ்',
    updated_at = NOW()
WHERE feature_name = 'PARCEL_SERVICE';
