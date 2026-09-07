-- Clean up a test shop registration for owner phone 6374217724 so that
-- number can register a shop again (owner_phone is unique on shops).

DELETE FROM shop_documents
WHERE shop_id IN (SELECT id FROM shops WHERE owner_phone = '6374217724');

DELETE FROM shop_images
WHERE shop_id IN (SELECT id FROM shops WHERE owner_phone = '6374217724');

DELETE FROM shops WHERE owner_phone = '6374217724';

-- If this number was briefly upgraded to SHOP_OWNER during earlier testing
-- of the (now reverted) register-time account provisioning, revert it back
-- to a plain customer account so the full flow can be re-tested from scratch.
UPDATE users SET role = 'USER'
WHERE mobile_number = '6374217724' AND role = 'SHOP_OWNER';
