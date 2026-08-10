-- Categories auto-created during product bulk import were stamped with the
-- placeholder "BULK_IMPORT" instead of the importing user. That made them
-- (a) visible to every shop owner (treated as global) and
-- (b) uneditable by their real owner (ownership check failed).
-- All bulk imports so far were done by the Murugesan Supermarket owner.
UPDATE product_categories
SET created_by = 'murugesan_79998',
    updated_by = 'murugesan_79998'
WHERE created_by = 'BULK_IMPORT';
