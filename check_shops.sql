-- Run this on your production PostgreSQL database
-- Check all active approved shops and their coordinates

SELECT id, business_name, latitude, longitude, city, is_active, status,
       delivery_radius
FROM shops
WHERE is_active = true AND status = 'APPROVED';

-- Check distance from Chennai (your current location: 13.073, 80.198)
-- to each shop using Haversine formula
SELECT id, business_name, latitude, longitude, city,
       (6371 * acos(cos(radians(13.0730)) * cos(radians(latitude)) * cos(radians(longitude) - radians(80.1977)) + sin(radians(13.0730)) * sin(radians(latitude)))) AS distance_km
FROM shops
WHERE is_active = true AND status = 'APPROVED'
ORDER BY distance_km ASC;
