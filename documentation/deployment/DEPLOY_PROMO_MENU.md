# Deploy Promo Code Menu to Production

## Quick Deploy Script

Copy and paste these commands on your production server:

```bash
#!/bin/bash

echo "🚀 Deploying Promo Code Menu..."

# 1. Create database table (if not exists)
echo "Step 1/5: Creating promotion_usage table..."
sudo -u postgres psql -d shop_management_db << 'EOF'
CREATE TABLE IF NOT EXISTS promotion_usage (
    id BIGSERIAL PRIMARY KEY,
    promotion_id BIGINT NOT NULL,
    customer_id BIGINT,
    order_id BIGINT,
    device_uuid VARCHAR(100),
    customer_phone VARCHAR(20),
    discount_applied DECIMAL(10,2) NOT NULL,
    order_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_promotion_usage_promotion FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE,
    CONSTRAINT fk_promotion_usage_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    CONSTRAINT fk_promotion_usage_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT uk_promotion_customer_order UNIQUE (promotion_id, customer_id, order_id),
    CONSTRAINT uk_promotion_device_order UNIQUE (promotion_id, device_uuid, order_id)
);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_promotion ON promotion_usage(promotion_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_customer ON promotion_usage(customer_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_order ON promotion_usage(order_id);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_device ON promotion_usage(device_uuid);
CREATE INDEX IF NOT EXISTS idx_promotion_usage_phone ON promotion_usage(customer_phone);
EOF

# 2. Pull latest code
echo "Step 2/5: Pulling latest code..."
cd /opt/shop-management
git pull origin main

# 3. Build Angular
echo "Step 3/5: Building Angular frontend..."
cd frontend
npm install
npm run build:prod

# 4. Restart containers
echo "Step 4/5: Restarting containers..."
cd /opt/shop-management
docker-compose restart frontend backend

# 5. Verify
echo "Step 5/5: Verifying deployment..."
sleep 10
docker logs nammaooru-backend --tail 5

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "Promo Code menu is now available in:"
echo "  - Super Admin dashboard"
echo "  - Admin dashboard"
echo ""
echo "Menu location: Marketing & Promotions > Promo Codes"
```

## Manual Steps (If you prefer step-by-step)

### 1. Create Database Table
```bash
sudo -u postgres psql -d shop_management_db -c "CREATE TABLE IF NOT EXISTS promotion_usage (id BIGSERIAL PRIMARY KEY, promotion_id BIGINT NOT NULL, customer_id BIGINT, order_id BIGINT, device_uuid VARCHAR(100), customer_phone VARCHAR(20), discount_applied DECIMAL(10,2) NOT NULL, order_amount DECIMAL(10,2) NOT NULL, used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, CONSTRAINT fk_promotion_usage_promotion FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE, CONSTRAINT fk_promotion_usage_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL, CONSTRAINT fk_promotion_usage_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE, CONSTRAINT uk_promotion_customer_order UNIQUE (promotion_id, customer_id, order_id), CONSTRAINT uk_promotion_device_order UNIQUE (promotion_id, device_uuid, order_id)); CREATE INDEX IF NOT EXISTS idx_promotion_usage_promotion ON promotion_usage(promotion_id); CREATE INDEX IF NOT EXISTS idx_promotion_usage_customer ON promotion_usage(customer_id); CREATE INDEX IF NOT EXISTS idx_promotion_usage_order ON promotion_usage(order_id); CREATE INDEX IF NOT EXISTS idx_promotion_usage_device ON promotion_usage(device_uuid); CREATE INDEX IF NOT EXISTS idx_promotion_usage_phone ON promotion_usage(customer_phone);"
```

### 2. Pull Latest Code
```bash
cd /opt/shop-management
git pull origin main
```

### 3. Rebuild Angular
```bash
cd /opt/shop-management/frontend
npm install
npm run build:prod
```

### 4. Restart Containers
```bash
cd /opt/shop-management
docker-compose restart frontend backend
```

### 5. Check Backend Status
```bash
docker logs nammaooru-backend --tail 20
```

## What This Does

1. **Database**: Creates the `promotion_usage` table needed for tracking promo code usage
2. **Code Update**: Pulls the latest code that includes the promo code menu
3. **Frontend Build**: Rebuilds Angular with the new menu
4. **Restart**: Restarts both frontend and backend containers
5. **Verification**: Checks backend logs to ensure it started successfully

## After Deployment

1. Login to admin panel: `https://admin.nammaooru.com`
2. Look for "Marketing & Promotions" category in sidebar
3. Click "Promo Codes" to access the management page
4. Create, edit, delete, and manage promo codes through the UI

## Troubleshooting

If menu doesn't show up:
```bash
# Clear browser cache and hard reload (Ctrl+Shift+R)
# Or check if frontend container is running
docker ps | grep frontend

# Check frontend logs
docker logs nammaooru-frontend --tail 20
```
