-- Payout destination captured per wallet, ready for whichever automated payout path
-- (Razorpay Route linked account, or RazorpayX Payouts fund account) gets set up later.
-- Nothing here calls Razorpay yet — this only stores where the money should eventually go.

ALTER TABLE wallets ADD COLUMN payout_method VARCHAR(20); -- BANK_ACCOUNT | UPI
ALTER TABLE wallets ADD COLUMN bank_account_holder_name VARCHAR(200);
ALTER TABLE wallets ADD COLUMN bank_account_number VARCHAR(50);
ALTER TABLE wallets ADD COLUMN bank_ifsc VARCHAR(20);
ALTER TABLE wallets ADD COLUMN upi_id VARCHAR(100);

-- Filled in once a Razorpay Route linked account / RazorpayX fund account is actually
-- created for this wallet's owner — null until then, meaning "not yet automated."
ALTER TABLE wallets ADD COLUMN razorpay_fund_account_id VARCHAR(100);
ALTER TABLE wallets ADD COLUMN payout_details_verified BOOLEAN NOT NULL DEFAULT FALSE;
