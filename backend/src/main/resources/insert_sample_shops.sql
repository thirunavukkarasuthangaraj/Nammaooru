-- Insert sample shops data with various cities and statuses
-- This script adds sample shops for testing

-- Insert shops with different statuses and cities
INSERT INTO shops (
    shop_id, name, description, owner_name, owner_email, owner_phone,
    business_name, business_type, address_line1, city, state, postal_code,
    country, min_order_amount, delivery_radius, delivery_fee, free_delivery_above,
    commission_rate, is_active, is_open, status, rating, latitude, longitude,
    created_at, updated_at
) VALUES 
-- Chennai shops
('SHOP001', 'Fresh Mart Chennai', 'Premium grocery store with fresh vegetables and fruits', 
 'Raj Kumar', 'raj@freshmart.com', '9876543210', 
 'Fresh Mart Enterprises', 'GROCERY', 'Anna Nagar, Main Road', 
 'Chennai', 'Tamil Nadu', '600040', 'India', 
 100.00, 5, 30.00, 500.00, 15.00, true, true, 'APPROVED', 4.5, 
 13.0827, 80.2707, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP002', 'HealthCare Pharmacy', 'Your trusted neighborhood pharmacy', 
 'Dr. Priya', 'priya@healthcare.com', '9876543211', 
 'HealthCare Medical Store', 'PHARMACY', 'T. Nagar, Usman Road', 
 'Chennai', 'Tamil Nadu', '600017', 'India', 
 50.00, 3, 20.00, 300.00, 10.00, true, true, 'APPROVED', 4.2, 
 13.0418, 80.2341, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Bangalore shops
('SHOP003', 'Green Grocers', 'Organic vegetables and fruits', 
 'Suresh Babu', 'suresh@greengrocer.com', '9876543212', 
 'Green Grocers Pvt Ltd', 'GROCERY', 'Koramangala, 4th Block', 
 'Bangalore', 'Karnataka', '560034', 'India', 
 150.00, 7, 40.00, 600.00, 12.00, true, true, 'PENDING', 0.0, 
 12.9352, 77.6245, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP004', 'Spice Garden Restaurant', 'Authentic South Indian cuisine', 
 'Chef Arun', 'arun@spicegarden.com', '9876543213', 
 'Spice Garden Foods', 'RESTAURANT', 'Indiranagar, 100 Feet Road', 
 'Bangalore', 'Karnataka', '560038', 'India', 
 200.00, 5, 50.00, 800.00, 18.00, true, true, 'APPROVED', 4.8, 
 12.9716, 77.6411, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Mumbai shops
('SHOP005', 'City Mart', 'One-stop shop for all your needs', 
 'Amit Sharma', 'amit@citymart.com', '9876543214', 
 'City Mart Retail', 'GENERAL', 'Andheri West, Link Road', 
 'Mumbai', 'Maharashtra', '400053', 'India', 
 200.00, 10, 60.00, 1000.00, 15.00, true, true, 'APPROVED', 4.3, 
 19.1196, 72.8463, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP006', 'MediPlus Pharmacy', '24/7 Pharmacy services', 
 'Dr. Neha Patel', 'neha@mediplus.com', '9876543215', 
 'MediPlus Healthcare', 'PHARMACY', 'Bandra West, Hill Road', 
 'Mumbai', 'Maharashtra', '400050', 'India', 
 100.00, 8, 40.00, 500.00, 10.00, true, true, 'REJECTED', 3.5, 
 19.0596, 72.8295, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Delhi shops
('SHOP007', 'Royal Foods', 'Premium restaurant with multi-cuisine', 
 'Chef Vikram', 'vikram@royalfoods.com', '9876543216', 
 'Royal Foods Pvt Ltd', 'RESTAURANT', 'Connaught Place, Block A', 
 'New Delhi', 'Delhi', '110001', 'India', 
 300.00, 12, 80.00, 1500.00, 20.00, true, false, 'APPROVED', 4.7, 
 28.6315, 77.2167, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP008', 'Daily Needs Store', 'Your neighborhood convenience store', 
 'Rahul Verma', 'rahul@dailyneeds.com', '9876543217', 
 'Daily Needs Retail', 'GROCERY', 'Karol Bagh, Ajmal Khan Road', 
 'New Delhi', 'Delhi', '110005', 'India', 
 100.00, 4, 30.00, 400.00, 12.00, true, true, 'PENDING', 0.0, 
 28.6515, 77.1902, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Hyderabad shops
('SHOP009', 'Tech City Mart', 'Modern supermarket with online ordering', 
 'Srinivas Rao', 'srinivas@techcity.com', '9876543218', 
 'Tech City Retail Solutions', 'GROCERY', 'HITEC City, Madhapur', 
 'Hyderabad', 'Telangana', '500081', 'India', 
 150.00, 10, 50.00, 750.00, 15.00, true, true, 'APPROVED', 4.6, 
 17.4485, 78.3805, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP010', 'Biryani House', 'Authentic Hyderabadi Biryani', 
 'Mohammed Ali', 'ali@biryanihouse.com', '9876543219', 
 'Biryani House Restaurant', 'RESTAURANT', 'Banjara Hills, Road No. 10', 
 'Hyderabad', 'Telangana', '500034', 'India', 
 250.00, 8, 60.00, 1000.00, 18.00, true, true, 'APPROVED', 4.9, 
 17.4156, 78.4347, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Pune shops
('SHOP011', 'Pune Fresh Mart', 'Fresh produce and groceries', 
 'Sachin Kulkarni', 'sachin@punefresh.com', '9876543220', 
 'Pune Fresh Enterprises', 'GROCERY', 'Kothrud, Karve Road', 
 'Pune', 'Maharashtra', '411038', 'India', 
 120.00, 6, 35.00, 500.00, 14.00, true, true, 'PENDING', 0.0, 
 18.5074, 73.8077, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP012', 'Wellness Pharmacy', 'Complete healthcare solutions', 
 'Dr. Anjali Desai', 'anjali@wellness.com', '9876543221', 
 'Wellness Healthcare', 'PHARMACY', 'Viman Nagar, Airport Road', 
 'Pune', 'Maharashtra', '411014', 'India', 
 80.00, 5, 25.00, 400.00, 10.00, true, true, 'APPROVED', 4.4, 
 18.5679, 73.9143, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Kolkata shops
('SHOP013', 'Bengal Sweets', 'Traditional Bengali sweets and snacks', 
 'Subhash Ghosh', 'subhash@bengalsweets.com', '9876543222', 
 'Bengal Sweets & Snacks', 'RESTAURANT', 'Park Street, Shakespeare Sarani', 
 'Kolkata', 'West Bengal', '700017', 'India', 
 100.00, 5, 40.00, 500.00, 15.00, true, true, 'APPROVED', 4.5, 
 22.5448, 88.3522, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

('SHOP014', 'Metro Grocers', 'Wholesale and retail groceries', 
 'Anil Roy', 'anil@metrogrocers.com', '9876543223', 
 'Metro Grocers Ltd', 'GROCERY', 'Salt Lake, Sector V', 
 'Kolkata', 'West Bengal', '700091', 'India', 
 200.00, 8, 50.00, 800.00, 12.00, true, true, 'SUSPENDED', 3.8, 
 22.5761, 88.4337, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Ahmedabad shops
('SHOP015', 'Gujarat Mart', 'Traditional Gujarati groceries', 
 'Jayesh Patel', 'jayesh@gujaratmart.com', '9876543224', 
 'Gujarat Mart Stores', 'GROCERY', 'C.G. Road, Navrangpura', 
 'Ahmedabad', 'Gujarat', '380009', 'India', 
 100.00, 7, 30.00, 500.00, 14.00, true, true, 'APPROVED', 4.3, 
 23.0373, 72.5612, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Jaipur shops
('SHOP016', 'Pink City Store', 'Rajasthani handicrafts and general store', 
 'Ramesh Sharma', 'ramesh@pinkcity.com', '9876543225', 
 'Pink City Enterprises', 'GENERAL', 'M.I. Road, Panch Batti', 
 'Jaipur', 'Rajasthan', '302001', 'India', 
 150.00, 5, 40.00, 600.00, 15.00, true, true, 'PENDING', 0.0, 
 26.9124, 75.7873, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Coimbatore shops
('SHOP017', 'Kovai Super Market', 'South Indian groceries specialist', 
 'Murugan K', 'murugan@kovaimarket.com', '9876543226', 
 'Kovai Retail Solutions', 'GROCERY', 'RS Puram, DB Road', 
 'Coimbatore', 'Tamil Nadu', '641002', 'India', 
 80.00, 4, 25.00, 400.00, 12.00, true, true, 'APPROVED', 4.2, 
 11.0168, 76.9558, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Chandigarh shops
('SHOP018', 'City Beautiful Mart', 'Premium lifestyle and grocery store', 
 'Harpreet Singh', 'harpreet@citybeautiful.com', '9876543227', 
 'City Beautiful Retail', 'GENERAL', 'Sector 17, Plaza', 
 'Chandigarh', 'Chandigarh', '160017', 'India', 
 200.00, 10, 50.00, 1000.00, 16.00, true, true, 'APPROVED', 4.6, 
 30.7333, 76.7794, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Lucknow shops
('SHOP019', 'Nawabi Foods', 'Authentic Awadhi cuisine', 
 'Chef Irfan Khan', 'irfan@nawabifoods.com', '9876543228', 
 'Nawabi Restaurant Chain', 'RESTAURANT', 'Hazratganj, Mahatma Gandhi Road', 
 'Lucknow', 'Uttar Pradesh', '226001', 'India', 
 180.00, 6, 45.00, 700.00, 17.00, true, true, 'REJECTED', 3.2, 
 26.8467, 80.9462, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Kochi shops
('SHOP020', 'Backwater Fresh', 'Fresh seafood and groceries', 
 'George Thomas', 'george@backwaterfresh.com', '9876543229', 
 'Backwater Trading Co', 'GROCERY', 'Marine Drive, Ernakulam', 
 'Kochi', 'Kerala', '682031', 'India', 
 100.00, 5, 35.00, 500.00, 13.00, true, true, 'APPROVED', 4.4, 
 9.9312, 76.2673, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Update sequence if needed
SELECT setval('shops_id_seq', (SELECT MAX(id) FROM shops));