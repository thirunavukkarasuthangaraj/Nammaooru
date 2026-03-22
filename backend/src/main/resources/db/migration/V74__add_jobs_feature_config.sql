-- V74: Add JOBS to feature_configs (Home Screen Grid)
-- Employers can post job openings; workers can browse and connect

INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order)
SELECT 'JOBS', 'Jobs', 'வேலை வாய்ப்பு', 'work_rounded', '#2E7D32', '/customer/jobs', 12.4966000, 78.5729000, 50, true, 12
WHERE NOT EXISTS (SELECT 1 FROM feature_configs WHERE feature_name = 'JOBS');

-- Also add post_limit and max_images columns if not already present on feature_configs
-- (These columns are added by later migrations — skip if they don't exist yet)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'feature_configs' AND column_name = 'post_limit'
    ) THEN
        UPDATE feature_configs
        SET post_limit = 3
        WHERE feature_name = 'JOBS' AND post_limit IS NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'feature_configs' AND column_name = 'max_images'
    ) THEN
        UPDATE feature_configs
        SET max_images = 3
        WHERE feature_name = 'JOBS' AND max_images IS NULL;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'feature_configs' AND column_name = 'show_in_app'
    ) THEN
        UPDATE feature_configs
        SET show_in_app = true
        WHERE feature_name = 'JOBS';
    END IF;
END $$;
