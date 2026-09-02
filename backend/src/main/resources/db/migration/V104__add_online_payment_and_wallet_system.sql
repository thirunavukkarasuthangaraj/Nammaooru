-- Online order payments (Razorpay) + wallet ledger for shop owners and delivery partners.
-- COD orders keep using the existing payment_settlements flow untouched (driver holds
-- cash and settles commission owed TO the platform). This is the reverse direction:
-- for online-paid orders the platform holds the money via Razorpay and owes it OUT to
-- the shop (and to the driver, unless the shop self-delivers).

CREATE TABLE order_payments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id),
    razorpay_order_id VARCHAR(100) NOT NULL UNIQUE,
    razorpay_payment_id VARCHAR(100),
    razorpay_signature VARCHAR(200),
    order_amount NUMERIC(10,2) NOT NULL,
    gateway_fee_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    total_charged_amount NUMERIC(10,2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    razorpay_refund_id VARCHAR(100),
    refund_amount NUMERIC(10,2),
    refund_fee_amount NUMERIC(10,2),
    failure_reason VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_order_payments_razorpay_order_id ON order_payments(razorpay_order_id);
CREATE INDEX idx_order_payments_status ON order_payments(status);

CREATE TABLE wallets (
    id BIGSERIAL PRIMARY KEY,
    owner_type VARCHAR(20) NOT NULL, -- SHOP | DELIVERY_PARTNER
    owner_id BIGINT NOT NULL,        -- shop_id or delivery-partner user_id depending on owner_type
    balance NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_earned NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_withdrawn NUMERIC(12,2) NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_wallets_owner UNIQUE (owner_type, owner_id)
);

CREATE TABLE wallet_transactions (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL REFERENCES wallets(id),
    type VARCHAR(10) NOT NULL, -- CREDIT | DEBIT
    reason VARCHAR(30) NOT NULL, -- ORDER_SETTLEMENT | WITHDRAWAL | ADJUSTMENT
    amount NUMERIC(12,2) NOT NULL,
    balance_after NUMERIC(12,2) NOT NULL,
    order_id BIGINT REFERENCES orders(id),
    withdrawal_id BIGINT,
    notes VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_order_id ON wallet_transactions(order_id);

-- One credit per (wallet, order) — an order can only ever settle into a given wallet once,
-- even if the settlement endpoint is retried.
CREATE UNIQUE INDEX uk_wallet_txn_order_settlement ON wallet_transactions(wallet_id, order_id)
    WHERE reason = 'ORDER_SETTLEMENT';

CREATE TABLE wallet_withdrawals (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL REFERENCES wallets(id),
    amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING | PAID | REJECTED
    payout_reference VARCHAR(200),
    notes VARCHAR(500),
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    processed_by VARCHAR(100)
);

CREATE INDEX idx_wallet_withdrawals_wallet_id ON wallet_withdrawals(wallet_id);
CREATE INDEX idx_wallet_withdrawals_status ON wallet_withdrawals(status);

ALTER TABLE wallet_transactions
    ADD CONSTRAINT fk_wallet_txn_withdrawal FOREIGN KEY (withdrawal_id) REFERENCES wallet_withdrawals(id);
