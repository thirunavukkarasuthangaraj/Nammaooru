-- Tracks the one-time welcome bonus paid to a customer's UPI-linked mobile
-- number on registration. Deliberately standalone from the shop/delivery-
-- partner Wallet system (that models order-settlement earnings owed by the
-- platform, not a promo credit) - this is just a small payout queue: an
-- admin sends the amount by hand via any UPI app to the mobile number and
-- marks it paid here.
CREATE TABLE signup_bonuses (
    id BIGSERIAL PRIMARY KEY,
    mobile_number VARCHAR(20) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    payout_reference VARCHAR(100),
    processed_by VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at TIMESTAMP,
    CONSTRAINT uk_signup_bonuses_mobile_number UNIQUE (mobile_number)
);

CREATE INDEX idx_signup_bonuses_status ON signup_bonuses(status);
