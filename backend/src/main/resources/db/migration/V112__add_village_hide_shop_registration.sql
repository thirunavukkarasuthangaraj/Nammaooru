-- Per-village, per-category control for the customer app's "Register Your
-- Shop" CTA. Comma-separated FeatureConfig.feature_name keys (e.g.
-- "GROCERY,FOOD") for which the CTA should be hidden when the customer's
-- selected location matches this village - null/empty means never hidden.
-- A simple delimited column (not a join table) since this only needs to be
-- editable from one admin form, matching how product tags are already
-- stored elsewhere in this codebase.
ALTER TABLE villages
    ADD COLUMN hidden_registration_categories VARCHAR(500);
