-- A SHOP_OWNER account can end up with is_active=false or a non-ACTIVE
-- status (e.g. left over from before it was upgraded from an unverified
-- customer row, or from earlier testing of the registration flow). Spring
-- Security's isEnabled() check requires BOTH is_active=true and
-- status='ACTIVE', so such an account gets "User is disabled" on login even
-- with the correct password, and resetting the password does not fix it.
-- Shop owners should always be able to log in once they have an account.
UPDATE users
SET is_active = true, status = 'ACTIVE'
WHERE role = 'SHOP_OWNER' AND (is_active = false OR status <> 'ACTIVE');
