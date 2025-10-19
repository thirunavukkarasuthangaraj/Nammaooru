-- Create payment_settlements table
CREATE TABLE IF NOT EXISTS payment_settlements (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL,
    settlement_date TIMESTAMP NOT NULL,
    cash_collected DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    commission_earned DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_orders INTEGER NOT NULL DEFAULT 0,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    notes TEXT,
    settled_by VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_settlement_partner FOREIGN KEY (partner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for payment_settlements
CREATE INDEX idx_payment_settlements_partner_id ON payment_settlements(partner_id);
CREATE INDEX idx_payment_settlements_settlement_date ON payment_settlements(settlement_date);
CREATE INDEX idx_payment_settlements_status ON payment_settlements(status);
CREATE INDEX idx_payment_settlements_payment_method ON payment_settlements(payment_method);

-- Add settlement fields to order_assignments table
ALTER TABLE order_assignments
ADD COLUMN IF NOT EXISTS settlement_id BIGINT,
ADD COLUMN IF NOT EXISTS is_settled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS settled_at TIMESTAMP;

-- Create foreign key constraint for settlement_id
ALTER TABLE order_assignments
ADD CONSTRAINT fk_order_assignment_settlement
FOREIGN KEY (settlement_id) REFERENCES payment_settlements(id) ON DELETE SET NULL;

-- Create index for settlement lookups
CREATE INDEX idx_order_assignments_settlement_id ON order_assignments(settlement_id);
CREATE INDEX idx_order_assignments_is_settled ON order_assignments(is_settled);

-- Update existing records to mark as unsettled
UPDATE order_assignments SET is_settled = FALSE WHERE is_settled IS NULL;

-- Add comments for documentation
COMMENT ON TABLE payment_settlements IS 'Records of payment settlements between delivery partners and the company';
COMMENT ON COLUMN payment_settlements.cash_collected IS 'Total cash collected from COD orders only';
COMMENT ON COLUMN payment_settlements.commission_earned IS 'Total commission earned on all delivered orders (COD + Online)';
COMMENT ON COLUMN payment_settlements.net_amount IS 'Net amount to settle (cash_collected - commission_earned)';
COMMENT ON COLUMN payment_settlements.total_orders IS 'Number of orders included in this settlement';

COMMENT ON COLUMN order_assignments.is_settled IS 'Indicates if this order assignment has been included in a payment settlement';
COMMENT ON COLUMN order_assignments.settled_at IS 'Timestamp when this order assignment was settled';
COMMENT ON COLUMN order_assignments.settlement_id IS 'Reference to the payment settlement record';
