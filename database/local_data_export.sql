--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12
-- Dumped by pg_dump version 15.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: analytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.analytics DISABLE TRIGGER ALL;



ALTER TABLE public.analytics ENABLE TRIGGER ALL;

--
-- Data for Name: business_hours; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.business_hours DISABLE TRIGGER ALL;



ALTER TABLE public.business_hours ENABLE TRIGGER ALL;

--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.customers DISABLE TRIGGER ALL;

INSERT INTO public.customers VALUES (16, '456 Brigade Road', NULL, NULL, 'Bangalore', 'India', '2025-08-17 15:58:00.757436', 'system', NULL, 'jane.smith@customer.com', NULL, NULL, 'Jane', NULL, true, true, NULL, 'Smith', NULL, NULL, NULL, '+919876543211', NULL, NULL, '560002', NULL, NULL, NULL, NULL, NULL, 'Karnataka', 'ACTIVE', NULL, NULL, '2025-08-17 15:58:00.757436', 'system');
INSERT INTO public.customers VALUES (15, '123 MG Road', NULL, NULL, 'Bangalore', 'India', '2025-08-17 15:58:00.757436', 'system', NULL, 'thirunacse75@gmail.com', NULL, NULL, 'John', NULL, true, true, NULL, 'Doe', NULL, NULL, NULL, '+919876543210', NULL, NULL, '560001', NULL, NULL, NULL, NULL, NULL, 'Karnataka', 'ACTIVE', NULL, NULL, '2025-08-17 15:58:00.757436', 'system');


ALTER TABLE public.customers ENABLE TRIGGER ALL;

--
-- Data for Name: customer_addresses; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.customer_addresses DISABLE TRIGGER ALL;



ALTER TABLE public.customer_addresses ENABLE TRIGGER ALL;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.users DISABLE TRIGGER ALL;

INSERT INTO public.users VALUES (54, NULL, '2025-08-17 16:02:14.435036', NULL, NULL, NULL, 'shopowner@shopmanagement.com', NULL, NULL, 'Shop', true, NULL, NULL, 'Owner', NULL, NULL, NULL, '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', NULL, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', NULL, '2025-08-17 16:02:14.435036', NULL, 'shopowner');
INSERT INTO public.users VALUES (55, NULL, '2025-08-17 16:02:14.47403', NULL, NULL, NULL, 'user@shopmanagement.com', NULL, NULL, 'Regular', true, NULL, NULL, 'User', NULL, NULL, NULL, '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', NULL, NULL, NULL, 'USER', 'ACTIVE', NULL, '2025-08-17 16:02:14.47403', NULL, 'user');
INSERT INTO public.users VALUES (56, NULL, '2025-08-17 16:30:13.565668', 'system', NULL, NULL, 'john.doe@customer.com', true, 0, 'John', true, false, NULL, 'Doe', NULL, NULL, true, '$2a$10$NqqgFA82ohQl2XsW0Jf.fOsO804cwYkUUWNOILzZ4miDaqtI0cCO2', false, NULL, NULL, 'USER', 'ACTIVE', false, '2025-08-17 16:30:13.565668', 'system', 'customer1');
INSERT INTO public.users VALUES (131, NULL, '2025-08-18 01:18:11.665391', NULL, NULL, NULL, 'admin@shopmanagement.com', true, NULL, 'Admin', true, NULL, NULL, 'User', NULL, NULL, NULL, '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', NULL, NULL, NULL, 'ADMIN', 'ACTIVE', NULL, '2025-08-18 11:54:16.793969', NULL, 'admin');
INSERT INTO public.users VALUES (49, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'owner1@electronics.com', true, 0, 'Rajesh', true, false, NULL, 'Kumar', NULL, NULL, true, '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', false, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'shopowner1');
INSERT INTO public.users VALUES (50, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'raj.kumar@delivery.com', true, 0, 'Raj', true, false, NULL, 'Kumar', NULL, NULL, true, '\a\0\/C4.WQ5FHC5yNEVJ/6', false, NULL, NULL, 'DELIVERY_PARTNER', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'delivery1');
INSERT INTO public.users VALUES (51, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'user1@example.com', true, 0, 'Regular', true, false, NULL, 'User', NULL, NULL, true, '\a\0\/C4.WQ5FHC5yNEVJ/6', false, NULL, NULL, 'USER', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'user1');
INSERT INTO public.users VALUES (69, NULL, '2025-08-17 12:59:25.50435', NULL, NULL, NULL, 'thiruna2394@gmail.com', false, 0, NULL, true, true, NULL, NULL, NULL, NULL, false, '$2a$10$a2XNFPo.ZZa3dKAoIQJKSeOj2/qRxWFkciR81pEYC14vf.IEZVBJ6', true, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', false, '2025-08-17 12:59:25.50435', NULL, 'thirunakum100');
INSERT INTO public.users VALUES (90, NULL, '2025-08-17 13:36:31.656076', NULL, NULL, NULL, 'helec60392@jobzyy.com', false, 0, 'Ravi', true, false, NULL, 'Kumar', NULL, '9876543210', false, '$2a$10$YslF08ioyJ8TGyMjwNX7i.VWzqK/vh1M5Ohrq2QChRaJthJ/nL/Dm', false, NULL, NULL, 'DELIVERY_PARTNER', 'ACTIVE', false, '2025-08-17 13:36:31.656076', NULL, 'helec60392');
INSERT INTO public.users VALUES (92, NULL, '2025-08-17 19:09:34.414105', NULL, NULL, NULL, 'thoruncse75@gmail.com', true, NULL, 'Test', true, NULL, NULL, 'Admin', NULL, NULL, NULL, '\a\0\.qGNr7b5R2BaFwBxOwLwCBdBgBQAMEoGBWZe7hAWlP2vhNvW', NULL, NULL, NULL, 'ADMIN', 'ACTIVE', NULL, '2025-08-17 19:09:34.414105', NULL, 'testadmin');
INSERT INTO public.users VALUES (129, NULL, '2025-08-17 17:21:01.794114', NULL, NULL, NULL, 'owner@techstore.com', false, 0, NULL, true, true, NULL, NULL, NULL, NULL, false, '$2a$10$91OCFNZ4vrGcUKiZ57BLfOBoGHYS.JsaQoEdmikc4klf7eSiJUCV2', true, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', false, '2025-08-17 17:21:01.794114', NULL, 'rajeshkuma71');
INSERT INTO public.users VALUES (48, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'admin1@shopmanagement.com', true, 0, 'Admin', true, false, NULL, 'One', NULL, NULL, true, '\a\0\2IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', false, NULL, NULL, 'ADMIN', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'admin1');
INSERT INTO public.users VALUES (52, NULL, '2025-08-17 10:29:49.859779', NULL, NULL, NULL, 'test@test.com', false, 0, NULL, true, false, NULL, NULL, NULL, NULL, false, '\a\0\/zo88UkrvQXSi6OQ.fLV4LUJXsLUBvG', false, NULL, NULL, 'SUPER_ADMIN', 'ACTIVE', false, '2025-08-17 10:29:49.859779', NULL, 'testuser');
INSERT INTO public.users VALUES (47, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'superadmin@shopmanagement.com', true, 0, 'Super', true, false, NULL, 'Admin', NULL, NULL, true, '\a\0\/C4.WQ5FHC5yNEVJ/6', false, NULL, NULL, 'SUPER_ADMIN', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'superadmin');
INSERT INTO public.users VALUES (133, NULL, '2025-08-17 19:53:10.057504', NULL, NULL, NULL, 'test@work.com', false, 0, NULL, true, false, NULL, NULL, NULL, NULL, false, '$2a$10$.VYrpp5dug8maWYJrvOs2eSXpweQeH7QC0Y1uddPvZF5mOWImIxUW', false, NULL, NULL, 'SUPER_ADMIN', 'ACTIVE', false, '2025-08-17 19:53:10.057504', NULL, 'testwork');


ALTER TABLE public.users ENABLE TRIGGER ALL;

--
-- Data for Name: delivery_partners; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.delivery_partners DISABLE TRIGGER ALL;

INSERT INTO public.delivery_partners VALUES (1, 'Ravi Kumar', '123 Delivery Street', NULL, NULL, '1234567890123456', 'HDFC0001234', NULL, 'Chennai', 'India', '2025-08-17 13:36:31.71435', 'system', NULL, NULL, '1995-06-15', 'helec60392@jobzyy.com', 'Priya Kumar', '9876543211', 'Ravi Kumar', 'MALE', true, true, NULL, NULL, '2027-12-31', 'DL1420110012345', 10.00, 'DP37791701', '9876543210', '600001', NULL, 5.00, NULL, 'Tamil Nadu', 'ACTIVE', 1, 1, 40.00, '2025-08-17 13:57:16.207837', 'system', NULL, 'Honda Activa 6G', 'TN01AB1234', 'BIKE', 'VERIFIED', 90);


ALTER TABLE public.delivery_partners ENABLE TRIGGER ALL;

--
-- Data for Name: shops; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shops DISABLE TRIGGER ALL;

INSERT INTO public.shops VALUES (16, '123 Tech Street, Electronics Complex', 'TechMart Electronics Pvt Ltd', 'GENERAL', 'Bangalore', 5.00, 'India', '2025-08-17 12:58:40.48703', 'superadmin', 50.00, 25.00, 'Premium electronics and gadgets store', 1500.00, NULL, true, false, true, 12.971600, 77.594600, 500.00, 'TechMart Electronics', 'thiruna2394@gmail.com', 'Thiruna Kumar', '9876543210', NULL, '560001', 2, 0.00, 'SH8F3668AF', 'techmart-electronics-bangalore', 'Karnataka', 'APPROVED', 0, 0.00, '2025-08-17 13:03:35.299345', 'superadmin');
INSERT INTO public.shops VALUES (11, '123 Tech Street, Electronics Market', 'TechStore Electronics', 'GENERAL', 'Bangalore', 5.00, 'India', '2025-08-17 10:51:14.939967', 'superadmin', 30.00, 10.00, 'Electronic items and gadgets store', 500.00, NULL, true, false, true, 12.971600, 77.594600, 100.00, 'TechStore', 'owner@techstore.com', 'Rajesh Kumar', '9876543210', NULL, '560001', 2, 0.00, 'SH8B55D708', 'techstore-bangalore', 'Karnataka', 'APPROVED', 0, 0.00, '2025-08-17 17:21:07.297896', 'superadmin');


ALTER TABLE public.shops ENABLE TRIGGER ALL;

--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.orders DISABLE TRIGGER ALL;

INSERT INTO public.orders VALUES (21, NULL, NULL, '2025-08-17 10:54:43.924766', 'superadmin', '123 MG Road, Bangalore', 'Bangalore', 'John Doe', 50.00, '9876543210', '560001', 'Karnataka', 0.00, NULL, NULL, 'ORD1755428083921', 'CASH_ON_DELIVERY', 'PENDING', 'PENDING', 160000.00, 8000.00, 168050.00, '2025-08-17 10:54:43.924766', 'superadmin', 15, 11);
INSERT INTO public.orders VALUES (22, NULL, NULL, '2025-08-17 11:13:22.915093', 'customer1', '789 Test Lane', 'Bangalore', 'Test Customer', 50.00, '9876543210', '560003', 'Karnataka', 0.00, NULL, NULL, 'ORD1755429202915', 'CASH_ON_DELIVERY', 'PENDING', 'PENDING', 75000.00, 3750.00, 78800.00, '2025-08-17 11:13:22.915093', 'customer1', 15, 11);
INSERT INTO public.orders VALUES (23, NULL, NULL, '2025-08-17 11:14:28.90626', 'customer1', '123 Email Test Street', 'Bangalore', 'Email Test Customer', 50.00, '9876543210', '560003', 'Karnataka', 0.00, NULL, 'Test order for email integration', 'ORD1755429268905', 'CASH_ON_DELIVERY', 'PENDING', 'PENDING', 85000.00, 4250.00, 89300.00, '2025-08-17 11:14:28.90626', 'customer1', 15, 11);
INSERT INTO public.orders VALUES (24, NULL, NULL, '2025-08-17 11:19:17.264854', 'customer1', '456 Template Test Road', 'Bangalore', 'Template Tester', 50.00, '9876543210', '560004', 'Karnataka', 0.00, NULL, 'Testing email templates', 'ORD1755429557264', 'CASH_ON_DELIVERY', 'PENDING', 'PENDING', 75000.00, 3750.00, 78800.00, '2025-08-17 11:19:17.264854', 'customer1', 15, 11);
INSERT INTO public.orders VALUES (27, NULL, NULL, '2025-08-17 11:23:34.376051', 'customer1', '789 Final Test Avenue', 'Bangalore', 'Final Tester', 50.00, '9876543210', '560005', 'Karnataka', 0.00, NULL, 'Final email template test', 'ORD1755429814348', 'CASH_ON_DELIVERY', 'PENDING', 'PREPARING', 85000.00, 4250.00, 89300.00, '2025-08-17 11:27:04.873174', 'superadmin', 15, 11);
INSERT INTO public.orders VALUES (34, '2025-08-17 13:57:16.183363', NULL, '2025-08-17 13:04:52.965519', 'superadmin', '456 Customer Street, Near Tech Park', 'Bangalore', 'Thiru Kumar', 50.00, '9876543211', '560002', 'Karnataka', 0.00, '2025-08-17 13:35:25.562356', 'Test order for API workflow
[Shop Owner] Order accepted - will be ready in 30 minutes', 'ORD1755435892960', 'CASH_ON_DELIVERY', 'PENDING', 'DELIVERED', 25999.00, 1299.95, 27348.95, '2025-08-17 13:57:16.197359', 'superadmin', 15, 16);


ALTER TABLE public.orders ENABLE TRIGGER ALL;

--
-- Data for Name: order_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.order_assignments DISABLE TRIGGER ALL;

INSERT INTO public.order_assignments VALUES (1, '2025-08-17 13:56:11.89223', '2025-08-17 13:50:46.520299', 'MANUAL', '2025-08-17 13:50:46.532117', NULL, NULL, 50.00, 13.087800, 80.278500, 'Delivered successfully to customer. Package in good condition.', '2025-08-17 13:57:16.182471', 40.00, 13.082700, 80.270700, '2025-08-17 13:56:31.470492', NULL, 'DELIVERED', '2025-08-17 13:57:16.195285', NULL, 1, 34);


ALTER TABLE public.order_assignments ENABLE TRIGGER ALL;

--
-- Data for Name: delivery_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.delivery_notifications DISABLE TRIGGER ALL;



ALTER TABLE public.delivery_notifications ENABLE TRIGGER ALL;

--
-- Data for Name: delivery_partner_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.delivery_partner_documents DISABLE TRIGGER ALL;



ALTER TABLE public.delivery_partner_documents ENABLE TRIGGER ALL;

--
-- Data for Name: delivery_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.delivery_tracking DISABLE TRIGGER ALL;



ALTER TABLE public.delivery_tracking ENABLE TRIGGER ALL;

--
-- Data for Name: delivery_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.delivery_zones DISABLE TRIGGER ALL;

INSERT INTO public.delivery_zones VALUES (5, '{"type": "Polygon", "coordinates": [[[77.5800, 12.9600], [77.6000, 12.9600], [77.6000, 12.9800], [77.5800, 12.9800], [77.5800, 12.9600]]]}', '2025-08-18 01:19:15.027826', 30.00, true, 45, 200.00, '23:00:00', '09:00:00', '2025-08-18 01:19:15.027826', 'BLR_CENTRAL', 'Bangalore Central');
INSERT INTO public.delivery_zones VALUES (6, '{"type": "Polygon", "coordinates": [[[77.5600, 12.9800], [77.6200, 12.9800], [77.6200, 13.0200], [77.5600, 13.0200], [77.5600, 12.9800]]]}', '2025-08-18 01:19:15.027826', 40.00, true, 60, 250.00, '22:00:00', '08:00:00', '2025-08-18 01:19:15.027826', 'BLR_NORTH', 'Bangalore North');
INSERT INTO public.delivery_zones VALUES (7, '{"type": "Polygon", "coordinates": [[[77.5500, 12.8500], [77.6500, 12.8500], [77.6500, 12.9500], [77.5500, 12.9500], [77.5500, 12.8500]]]}', '2025-08-18 01:19:15.027826', 35.00, true, 50, 300.00, '21:00:00', '09:00:00', '2025-08-18 01:19:15.027826', 'BLR_SOUTH', 'Bangalore South');
INSERT INTO public.delivery_zones VALUES (8, '{"type": "Polygon", "coordinates": [[[77.6000, 12.9000], [77.7500, 12.9000], [77.7500, 13.0000], [77.6000, 13.0000], [77.6000, 12.9000]]]}', '2025-08-18 01:19:15.027826', 50.00, true, 75, 400.00, '20:00:00', '10:00:00', '2025-08-18 01:19:15.027826', 'BLR_EAST', 'Bangalore East');


ALTER TABLE public.delivery_zones ENABLE TRIGGER ALL;

--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.product_categories DISABLE TRIGGER ALL;

INSERT INTO public.product_categories VALUES (1, '2025-08-17 15:21:10.378334', 'admin', 'Electronic devices and accessories', NULL, true, 'Electronics', 'electronics', 1, '2025-08-17 15:21:10.378334', NULL, NULL);
INSERT INTO public.product_categories VALUES (2, '2025-08-17 15:21:10.378334', 'admin', 'Apparel and fashion items', NULL, true, 'Clothing', 'clothing', 2, '2025-08-17 15:21:10.378334', NULL, NULL);
INSERT INTO public.product_categories VALUES (3, '2025-08-17 15:21:10.378334', 'admin', 'Food items and drinks', NULL, true, 'Food & Beverages', 'food-beverages', 3, '2025-08-17 15:21:10.378334', NULL, NULL);
INSERT INTO public.product_categories VALUES (4, '2025-08-17 15:21:10.378334', 'admin', 'Home improvement and gardening items', NULL, true, 'Home & Garden', 'home-garden', 4, '2025-08-17 15:21:10.378334', NULL, NULL);
INSERT INTO public.product_categories VALUES (5, '2025-08-17 15:21:10.378334', 'admin', 'Books and educational materials', NULL, true, 'Books', 'books', 5, '2025-08-17 15:21:10.378334', NULL, NULL);


ALTER TABLE public.product_categories ENABLE TRIGGER ALL;

--
-- Data for Name: master_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.master_products DISABLE TRIGGER ALL;

INSERT INTO public.master_products VALUES (1, '1234567890123', 'pcs', 0.168, 'Samsung', '2025-08-17 15:21:10.381402', 'admin', 'Latest Samsung smartphone with advanced camera', true, true, 'Samsung Galaxy S24', 'SGS24-001', 'Display: 6.2 inches, RAM: 8GB, Storage: 256GB', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 1);
INSERT INTO public.master_products VALUES (2, '2345678901234', 'pcs', 0.500, 'Nike', '2025-08-17 15:21:10.381402', 'admin', 'Comfortable running shoes', true, true, 'Nike Air Max 270', 'NAM270-001', 'Size: Various, Color: Multiple options available', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 2);
INSERT INTO public.master_products VALUES (3, '3456789012345', 'box', 0.100, 'Twinings', '2025-08-17 15:21:10.381402', 'admin', 'Premium organic green tea leaves', false, true, 'Organic Green Tea', 'OGT-001', 'Weight: 100g, Organic certified, 20 tea bags', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 3);
INSERT INTO public.master_products VALUES (4, '4567890123456', 'pcs', 1.200, 'Dell', '2025-08-17 15:21:10.381402', 'admin', 'High-performance ultrabook for professionals', true, true, 'Dell Laptop XPS 13', 'DELL-XPS13-001', 'Intel i7, 16GB RAM, 512GB SSD, 13.3 inch display', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 1);
INSERT INTO public.master_products VALUES (5, '5678901234567', 'pcs', 0.600, 'Levi''s', '2025-08-17 15:21:10.381402', 'admin', 'Classic straight fit denim jeans', false, true, 'Levi''s Jeans 501', 'LEVI-501-001', 'Cotton denim, available in multiple sizes and washes', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 2);
INSERT INTO public.master_products VALUES (6, '6789012345678', 'kg', 1.000, 'Blue Tokai', '2025-08-17 15:21:10.381402', 'admin', 'Premium roasted coffee beans', true, true, 'Coffee Beans Arabica', 'COFFEE-ARB-001', 'Single origin, medium roast, 250g pack', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 3);
INSERT INTO public.master_products VALUES (7, '7890123456789', 'bag', 5.000, 'Cocopeat', '2025-08-17 15:21:10.381402', 'admin', 'Premium organic potting soil', false, true, 'Garden Soil Organic', 'SOIL-ORG-001', '10kg bag, enriched with compost', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 4);
INSERT INTO public.master_products VALUES (8, '8901234567890', 'pcs', 0.800, 'O''Reilly', '2025-08-17 15:21:10.381402', 'admin', 'Complete guide to Java programming', true, true, 'Programming Book Java', 'BOOK-JAVA-001', '800 pages, includes examples and exercises', 'ACTIVE', '2025-08-17 15:21:10.381402', 'admin', 5);


ALTER TABLE public.master_products ENABLE TRIGGER ALL;

--
-- Data for Name: master_product_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.master_product_images DISABLE TRIGGER ALL;



ALTER TABLE public.master_product_images ENABLE TRIGGER ALL;

--
-- Data for Name: mobile_otps; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.mobile_otps DISABLE TRIGGER ALL;



ALTER TABLE public.mobile_otps ENABLE TRIGGER ALL;

--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications DISABLE TRIGGER ALL;



ALTER TABLE public.notifications ENABLE TRIGGER ALL;

--
-- Data for Name: shop_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shop_products DISABLE TRIGGER ALL;

INSERT INTO public.shop_products VALUES (11, NULL, '2025-08-17 10:53:05.520058', 'superadmin', NULL, NULL, NULL, NULL, true, false, NULL, NULL, NULL, 75000.00, 'ACTIVE', 10, NULL, true, '2025-08-17 10:53:05.520058', 'superadmin', 1, 11);
INSERT INTO public.shop_products VALUES (12, NULL, '2025-08-17 10:53:24.123797', 'superadmin', NULL, NULL, NULL, NULL, true, false, NULL, NULL, NULL, 85000.00, 'ACTIVE', 5, NULL, true, '2025-08-17 10:53:24.123797', 'superadmin', 4, 11);
INSERT INTO public.shop_products VALUES (17, NULL, '2025-08-17 13:02:36.621149', 'superadmin', NULL, NULL, NULL, NULL, true, false, 100, 5, NULL, 25999.00, 'ACTIVE', 50, NULL, true, '2025-08-17 13:02:36.621149', 'superadmin', 1, 16);
INSERT INTO public.shop_products VALUES (18, NULL, '2025-08-17 13:03:35.289738', 'superadmin', NULL, NULL, NULL, NULL, true, false, NULL, NULL, NULL, 1999.00, 'ACTIVE', 100, NULL, true, '2025-08-17 13:03:35.289738', 'superadmin', 2, 16);


ALTER TABLE public.shop_products ENABLE TRIGGER ALL;

--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.order_items DISABLE TRIGGER ALL;

INSERT INTO public.order_items VALUES (11, '2025-08-17 10:54:43.934535', 'Latest Samsung smartphone with advanced camera', NULL, 'Samsung Galaxy S24', 'SGS24-001', 1, NULL, 75000.00, 75000.00, '2025-08-17 10:54:43.934535', 21, 11);
INSERT INTO public.order_items VALUES (12, '2025-08-17 10:54:43.937544', 'High-performance ultrabook for professionals', NULL, 'Dell Laptop XPS 13', 'DELL-XPS13-001', 1, NULL, 85000.00, 85000.00, '2025-08-17 10:54:43.937544', 21, 12);
INSERT INTO public.order_items VALUES (13, '2025-08-17 11:13:22.919311', 'Latest Samsung smartphone with advanced camera', NULL, 'Samsung Galaxy S24', 'SGS24-001', 1, NULL, 75000.00, 75000.00, '2025-08-17 11:13:22.919311', 22, 11);
INSERT INTO public.order_items VALUES (14, '2025-08-17 11:14:28.907833', 'High-performance ultrabook for professionals', NULL, 'Dell Laptop XPS 13', 'DELL-XPS13-001', 1, NULL, 85000.00, 85000.00, '2025-08-17 11:14:28.907833', 23, 12);
INSERT INTO public.order_items VALUES (15, '2025-08-17 11:19:17.266881', 'Latest Samsung smartphone with advanced camera', NULL, 'Samsung Galaxy S24', 'SGS24-001', 1, NULL, 75000.00, 75000.00, '2025-08-17 11:19:17.266881', 24, 11);
INSERT INTO public.order_items VALUES (17, '2025-08-17 11:23:34.404769', 'High-performance ultrabook for professionals', NULL, 'Dell Laptop XPS 13', 'DELL-XPS13-001', 1, NULL, 85000.00, 85000.00, '2025-08-17 11:23:34.404769', 27, 12);
INSERT INTO public.order_items VALUES (21, '2025-08-17 13:04:52.970915', 'Latest Samsung smartphone with advanced camera', NULL, 'Samsung Galaxy S24', 'SGS24-001', 1, 'Handle with care', 25999.00, 25999.00, '2025-08-17 13:04:52.970915', 34, 17);


ALTER TABLE public.order_items ENABLE TRIGGER ALL;

--
-- Data for Name: partner_availability; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.partner_availability DISABLE TRIGGER ALL;



ALTER TABLE public.partner_availability ENABLE TRIGGER ALL;

--
-- Data for Name: partner_earnings; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.partner_earnings DISABLE TRIGGER ALL;

INSERT INTO public.partner_earnings VALUES (1, 40.00, 0.00, '2025-08-17 13:50:46.549115', NULL, '2025-08-17', 0.00, NULL, NULL, NULL, 'PROCESSED', 0.00, 1.00, NULL, 40.00, '2025-08-17 13:57:16.193261', 1, 1);


ALTER TABLE public.partner_earnings ENABLE TRIGGER ALL;

--
-- Data for Name: partner_zone_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.partner_zone_assignments DISABLE TRIGGER ALL;



ALTER TABLE public.partner_zone_assignments ENABLE TRIGGER ALL;

--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.password_reset_tokens DISABLE TRIGGER ALL;



ALTER TABLE public.password_reset_tokens ENABLE TRIGGER ALL;

--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.permissions DISABLE TRIGGER ALL;



ALTER TABLE public.permissions ENABLE TRIGGER ALL;

--
-- Data for Name: promotions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.promotions DISABLE TRIGGER ALL;



ALTER TABLE public.promotions ENABLE TRIGGER ALL;

--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.settings DISABLE TRIGGER ALL;



ALTER TABLE public.settings ENABLE TRIGGER ALL;

--
-- Data for Name: shop_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shop_documents DISABLE TRIGGER ALL;



ALTER TABLE public.shop_documents ENABLE TRIGGER ALL;

--
-- Data for Name: shop_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shop_images DISABLE TRIGGER ALL;



ALTER TABLE public.shop_images ENABLE TRIGGER ALL;

--
-- Data for Name: shop_product_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.shop_product_images DISABLE TRIGGER ALL;



ALTER TABLE public.shop_product_images ENABLE TRIGGER ALL;

--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

ALTER TABLE public.user_permissions DISABLE TRIGGER ALL;



ALTER TABLE public.user_permissions ENABLE TRIGGER ALL;

--
-- Name: analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.analytics_id_seq', 1, false);


--
-- Name: business_hours_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.business_hours_id_seq', 1, false);


--
-- Name: customer_addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_addresses_id_seq', 1, false);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customers_id_seq', 46, true);


--
-- Name: delivery_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_notifications_id_seq', 1, false);


--
-- Name: delivery_partner_documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_partner_documents_id_seq', 1, false);


--
-- Name: delivery_partners_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_partners_id_seq', 1, true);


--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_tracking_id_seq', 1, false);


--
-- Name: delivery_zones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delivery_zones_id_seq', 8, true);


--
-- Name: master_product_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.master_product_images_id_seq', 1, false);


--
-- Name: master_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.master_products_id_seq', 304, true);


--
-- Name: mobile_otps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mobile_otps_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 38, true);


--
-- Name: order_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_assignments_id_seq', 1, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_id_seq', 45, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 82, true);


--
-- Name: partner_availability_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_availability_id_seq', 1, false);


--
-- Name: partner_earnings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_earnings_id_seq', 1, true);


--
-- Name: partner_zone_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_zone_assignments_id_seq', 1, false);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 1, false);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permissions_id_seq', 1, false);


--
-- Name: product_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_categories_id_seq', 190, true);


--
-- Name: promotions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.promotions_id_seq', 1, false);


--
-- Name: settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.settings_id_seq', 1, false);


--
-- Name: shop_documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shop_documents_id_seq', 1, false);


--
-- Name: shop_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shop_images_id_seq', 1, false);


--
-- Name: shop_product_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shop_product_images_id_seq', 1, false);


--
-- Name: shop_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shop_products_id_seq', 42, true);


--
-- Name: shops_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shops_id_seq', 40, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 151, true);


--
-- PostgreSQL database dump complete
--

