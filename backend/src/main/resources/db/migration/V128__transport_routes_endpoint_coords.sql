-- Route From / To points get coordinates so the route line can be drawn
-- From -> stops -> To on the app and website maps.
ALTER TABLE transport_routes ADD COLUMN IF NOT EXISTS source_lat NUMERIC(10,7);
ALTER TABLE transport_routes ADD COLUMN IF NOT EXISTS source_lng NUMERIC(10,7);
ALTER TABLE transport_routes ADD COLUMN IF NOT EXISTS dest_lat NUMERIC(10,7);
ALTER TABLE transport_routes ADD COLUMN IF NOT EXISTS dest_lng NUMERIC(10,7);

-- Backfill the first live route (Tirupattur -> Alangayam) with town coordinates;
-- the owner can fine-tune them by dragging on the website map.
UPDATE transport_routes
   SET source_lat = 12.4950, source_lng = 78.5680,
       dest_lat   = 12.6194, dest_lng   = 78.7497
 WHERE LOWER(source) = 'tirupattur' AND LOWER(destination) = 'alangayam'
   AND source_lat IS NULL;
