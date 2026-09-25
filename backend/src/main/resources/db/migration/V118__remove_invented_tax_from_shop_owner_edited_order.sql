-- Order 1275 was created with zero tax (prices are tax-inclusive), but the
-- shop-owner add-item flow recomputed a 5% tax and inflated the total by 150.
-- Restore the correct total; the code path no longer applies tax.
UPDATE orders
SET tax_amount   = 0,
    total_amount = subtotal + COALESCE(delivery_fee, 0) - COALESCE(discount_amount, 0),
    updated_at   = NOW()
WHERE id = 1275
  AND order_number = 'ORD1790261953142'
  AND tax_amount > 0
  AND payment_status = 'PENDING';
