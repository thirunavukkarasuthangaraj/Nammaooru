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
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (55, NULL, '2025-08-17 16:02:14.47403', NULL, NULL, NULL, 'user@shopmanagement.com', NULL, NULL, 'Regular', true, NULL, NULL, 'User', NULL, NULL, NULL, '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', NULL, NULL, NULL, 'USER', 'ACTIVE', NULL, '2025-08-17 16:02:14.47403', NULL, 'user');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (56, NULL, '2025-08-17 16:30:13.565668', 'system', NULL, NULL, 'john.doe@customer.com', true, 0, 'John', true, false, NULL, 'Doe', NULL, NULL, true, '$2a$10$NqqgFA82ohQl2XsW0Jf.fOsO804cwYkUUWNOILzZ4miDaqtI0cCO2', false, NULL, NULL, 'USER', 'ACTIVE', false, '2025-08-17 16:30:13.565668', 'system', 'customer1');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (50, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'raj.kumar@delivery.com', true, 0, 'Raj', true, false, NULL, 'Kumar', NULL, NULL, true, '\a\0\/C4.WQ5FHC5yNEVJ/6', false, NULL, NULL, 'DELIVERY_PARTNER', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'delivery1');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (131, NULL, '2025-08-18 01:18:11.665391', NULL, NULL, NULL, 'admin@shopmanagement.com', true, NULL, 'Admin', true, NULL, NULL, 'User', NULL, NULL, NULL, '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', NULL, NULL, NULL, 'ADMIN', 'ACTIVE', NULL, '2025-08-20 20:24:29.013238', NULL, 'admin');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (90, NULL, '2025-08-17 13:36:31.656076', NULL, NULL, NULL, 'helec60392@jobzyy.com', false, 0, 'Ravi', true, false, NULL, 'Kumar', NULL, '9876543210', false, '$2a$10$YslF08ioyJ8TGyMjwNX7i.VWzqK/vh1M5Ohrq2QChRaJthJ/nL/Dm', false, NULL, NULL, 'DELIVERY_PARTNER', 'ACTIVE', false, '2025-08-17 13:36:31.656076', NULL, 'helec60392');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (129, NULL, '2025-08-17 17:21:01.794114', NULL, NULL, NULL, 'owner@techstore.com', false, 0, NULL, true, true, NULL, NULL, NULL, NULL, false, '$2a$10$91OCFNZ4vrGcUKiZ57BLfOBoGHYS.JsaQoEdmikc4klf7eSiJUCV2', true, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', false, '2025-08-17 17:21:01.794114', NULL, 'rajeshkuma71');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (69, NULL, '2025-08-17 12:59:25.50435', NULL, NULL, NULL, 'shop@gmail.com', false, 0, NULL, true, true, NULL, NULL, NULL, NULL, false, '$2a$10$a2XNFPo.ZZa3dKAoIQJKSeOj2/qRxWFkciR81pEYC14vf.IEZVBJ6', true, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', false, '2025-08-17 12:59:25.50435', NULL, 'thirunakum100');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (47, NULL, '2025-08-17 15:58:00.755381', 'system', NULL, NULL, 'thirun2394@gmail.com', true, 0, 'Super', true, false, NULL, 'Admin', NULL, NULL, true, '$2a$10$MWkHBomnLnniJtZ1zh/ta.C3jG1jNDIwOn6I8EF.wvkUG4Htt7/K6', false, NULL, NULL, 'SUPER_ADMIN', 'ACTIVE', false, '2025-08-17 15:58:00.755381', 'system', 'superadmin');
INSERT INTO public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) VALUES (54, NULL, '2025-08-17 16:02:14.435036', NULL, NULL, NULL, 'thirun2394+shop@gmail.com', NULL, NULL, 'Shop', true, NULL, NULL, 'Owner', NULL, NULL, NULL, '$2a$10$MWkHBomnLnniJtZ1zh/ta.C3jG1jNDIwOn6I8EF.wvkUG4Htt7/K6', NULL, NULL, NULL, 'SHOP_OWNER', 'ACTIVE', NULL, '2025-08-20 20:50:06.171057', NULL, 'shopowner');


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 160, true);


--
-- PostgreSQL database dump complete
--

