-- Shop-specific driver assignment table
-- Links delivery partners to their assigned shops (one driver can serve multiple shops)
-- Example: Ravi (user_id=5) assigned to Murugan Stores (shop_id=3) and Lakshmi Kadai (shop_id=7)

CREATE TABLE IF NOT EXISTS driver_assigned_shops (
    user_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, shop_id),
    CONSTRAINT fk_driver_assigned_shops_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for fast lookup: "find all drivers assigned to this shop"
CREATE INDEX IF NOT EXISTS idx_driver_assigned_shops_shop_id ON driver_assigned_shops(shop_id);

-- Example: Assign driver (user_id=5) to shop (shop_id=3)
-- INSERT INTO driver_assigned_shops (user_id, shop_id) VALUES (5, 3);

-- Example: Assign same driver to another shop in same village
-- INSERT INTO driver_assigned_shops (user_id, shop_id) VALUES (5, 7);

-- Example: View all drivers for a shop
-- SELECT u.id, u.first_name, u.email FROM users u
-- JOIN driver_assigned_shops das ON u.id = das.user_id
-- WHERE das.shop_id = 3;

-- Example: View all shops assigned to a driver
-- SELECT das.shop_id FROM driver_assigned_shops das WHERE das.user_id = 5;
