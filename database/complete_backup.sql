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

ALTER TABLE IF EXISTS ONLY public.customer_addresses DROP CONSTRAINT IF EXISTS fkrvr6wl9gll7u98cda18smugp4;
ALTER TABLE IF EXISTS ONLY public.shop_products DROP CONSTRAINT IF EXISTS fkr4w3pq6v1oqxkfhyhgr4ngn68;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS fkq4qlrabt4s0etm9tfkoqfuib1;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS fkpxtb8awmi0dk6smoh2vp1litg;
ALTER TABLE IF EXISTS ONLY public.delivery_notifications DROP CONSTRAINT IF EXISTS fkpwjynkwc6ikmd23ywci3v0842;
ALTER TABLE IF EXISTS ONLY public.partner_earnings DROP CONSTRAINT IF EXISTS fkos7pnggl450adufc45npil5lc;
ALTER TABLE IF EXISTS ONLY public.order_assignments DROP CONSTRAINT IF EXISTS fknk4qg6khhmtb1kut6jphhpi8i;
ALTER TABLE IF EXISTS ONLY public.product_categories DROP CONSTRAINT IF EXISTS fknhstaep8s818kydkq4teq8v4e;
ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS fkmmjb9o26o9rw4ihdtirha3ex7;
ALTER TABLE IF EXISTS ONLY public.delivery_notifications DROP CONSTRAINT IF EXISTS fkm7korrnvea8dheirstr3isnwt;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS fkkowxl8b2bngrxd1gafh13005u;
ALTER TABLE IF EXISTS ONLY public.shop_documents DROP CONSTRAINT IF EXISTS fkk8vq7f7n71qyuurdtktbjhs15;
ALTER TABLE IF EXISTS ONLY public.partner_zone_assignments DROP CONSTRAINT IF EXISTS fkj60otyd801xr8iuje7w8vlxdm;
ALTER TABLE IF EXISTS ONLY public.delivery_tracking DROP CONSTRAINT IF EXISTS fkiohrk3dcvm8yv2fg7n5n9k8op;
ALTER TABLE IF EXISTS ONLY public.shop_images DROP CONSTRAINT IF EXISTS fkhklkimv3eu30fw1v56wp65kjx;
ALTER TABLE IF EXISTS ONLY public.order_assignments DROP CONSTRAINT IF EXISTS fkhhu5nv7c14yxx28s4fotonkkk;
ALTER TABLE IF EXISTS ONLY public.delivery_notifications DROP CONSTRAINT IF EXISTS fkfox4c5s5tdsbrcan3r48d0aso;
ALTER TABLE IF EXISTS ONLY public.partner_earnings DROP CONSTRAINT IF EXISTS fke227lnikm12hr64gt014dtkmf;
ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS fkbioxgbv59vetrxe0ejfubep1w;
ALTER TABLE IF EXISTS ONLY public.shop_product_images DROP CONSTRAINT IF EXISTS fkbci6qq1h2uxhuyi04ymt4e0x;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS fk6rwo25nsq7y9mm5vumhdc0l14;
ALTER TABLE IF EXISTS ONLY public.delivery_partner_documents DROP CONSTRAINT IF EXISTS fk69je6xvgg7ppwg2w1u3r8f5gd;
ALTER TABLE IF EXISTS ONLY public.master_products DROP CONSTRAINT IF EXISTS fk62mmtbcgjxtdhsm5w0r20sa6y;
ALTER TABLE IF EXISTS ONLY public.master_product_images DROP CONSTRAINT IF EXISTS fk5vuvgiy2j8qsefraeyuyiugmt;
ALTER TABLE IF EXISTS ONLY public.delivery_partner_documents DROP CONSTRAINT IF EXISTS fk5sy8o681csuqchuswoxjqndfu;
ALTER TABLE IF EXISTS ONLY public.partner_zone_assignments DROP CONSTRAINT IF EXISTS fk50fi21ce02cuvtttbil4kq5hi;
ALTER TABLE IF EXISTS ONLY public.order_assignments DROP CONSTRAINT IF EXISTS fk4t2ugkwpkt2wtb1rhheese2wy;
ALTER TABLE IF EXISTS ONLY public.partner_availability DROP CONSTRAINT IF EXISTS fk42usw5lk35uby2tk449x7mnmy;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS fk21gttsw5evi5bbsvleui69d7r;
ALTER TABLE IF EXISTS ONLY public.shop_products DROP CONSTRAINT IF EXISTS fk16al3qn4hmw6o1ng4cmm5hstr;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS user_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.shop_products DROP CONSTRAINT IF EXISTS ukpdptnfm1m4psscn4692ttseag;
ALTER TABLE IF EXISTS ONLY public.shops DROP CONSTRAINT IF EXISTS uk_tjd5rnobjcgkwuyd6e46iwloq;
ALTER TABLE IF EXISTS ONLY public.settings DROP CONSTRAINT IF EXISTS uk_swd05dvj4ukvw5q135bpbbfae;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_rv2gnx8yoe0qh1meq1q915v57;
ALTER TABLE IF EXISTS ONLY public.customers DROP CONSTRAINT IF EXISTS uk_rfbvkrffamfql7cjmen8v976v;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS uk_r43af9ap4edm43mmtq01oddj6;
ALTER TABLE IF EXISTS ONLY public.permissions DROP CONSTRAINT IF EXISTS uk_pnvtwliis6p05pn6i3ndjrqt2;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS uk_nthkiu7pgmnqnu86i2jyoe2v7;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_jk6qr1r0gd9ih7jknmkk8k6up;
ALTER TABLE IF EXISTS ONLY public.promotions DROP CONSTRAINT IF EXISTS uk_jdho73ymbyu46p2hh562dk4kk;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_jdebkmarjpm1ff5524i002a3w;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_glmaox582sjhei4vhpgf276f1;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_fs4vedfwfxn8knki0ayxx2whn;
ALTER TABLE IF EXISTS ONLY public.delivery_zones DROP CONSTRAINT IF EXISTS uk_a8t0mt2lteswps27jw2iy1a2f;
ALTER TABLE IF EXISTS ONLY public.partner_earnings DROP CONSTRAINT IF EXISTS uk_7d6l5noljbn8ov36otv5l1qhl;
ALTER TABLE IF EXISTS ONLY public.password_reset_tokens DROP CONSTRAINT IF EXISTS uk_71lqwbwtklmljk3qlsugr1mig;
ALTER TABLE IF EXISTS ONLY public.product_categories DROP CONSTRAINT IF EXISTS uk_6h198ar0xronfoxlvnq7lsfc0;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS uk_6g7q05u4yobrlorexltrna8lo;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS uk_6dotkott2kjsp8vw4d0m25fb7;
ALTER TABLE IF EXISTS ONLY public.customers DROP CONSTRAINT IF EXISTS uk_64j2dn17ycwlgr3pttpwna8dw;
ALTER TABLE IF EXISTS ONLY public.master_products DROP CONSTRAINT IF EXISTS uk_4mr2q9tc8gyymy9pind6uwg8;
ALTER TABLE IF EXISTS ONLY public.shops DROP CONSTRAINT IF EXISTS uk_1bphyyyptl7w9fp69a04krtfr;
ALTER TABLE IF EXISTS ONLY public.shops DROP CONSTRAINT IF EXISTS shops_pkey;
ALTER TABLE IF EXISTS ONLY public.shop_products DROP CONSTRAINT IF EXISTS shop_products_pkey;
ALTER TABLE IF EXISTS ONLY public.shop_product_images DROP CONSTRAINT IF EXISTS shop_product_images_pkey;
ALTER TABLE IF EXISTS ONLY public.shop_images DROP CONSTRAINT IF EXISTS shop_images_pkey;
ALTER TABLE IF EXISTS ONLY public.shop_documents DROP CONSTRAINT IF EXISTS shop_documents_pkey;
ALTER TABLE IF EXISTS ONLY public.settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE IF EXISTS ONLY public.promotions DROP CONSTRAINT IF EXISTS promotions_pkey;
ALTER TABLE IF EXISTS ONLY public.product_categories DROP CONSTRAINT IF EXISTS product_categories_pkey;
ALTER TABLE IF EXISTS ONLY public.permissions DROP CONSTRAINT IF EXISTS permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.password_reset_tokens DROP CONSTRAINT IF EXISTS password_reset_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.partner_zone_assignments DROP CONSTRAINT IF EXISTS partner_zone_assignments_pkey;
ALTER TABLE IF EXISTS ONLY public.partner_earnings DROP CONSTRAINT IF EXISTS partner_earnings_pkey;
ALTER TABLE IF EXISTS ONLY public.partner_availability DROP CONSTRAINT IF EXISTS partner_availability_pkey;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS orders_pkey;
ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS order_items_pkey;
ALTER TABLE IF EXISTS ONLY public.order_assignments DROP CONSTRAINT IF EXISTS order_assignments_pkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.mobile_otps DROP CONSTRAINT IF EXISTS mobile_otps_pkey;
ALTER TABLE IF EXISTS ONLY public.master_products DROP CONSTRAINT IF EXISTS master_products_pkey;
ALTER TABLE IF EXISTS ONLY public.master_product_images DROP CONSTRAINT IF EXISTS master_product_images_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_zones DROP CONSTRAINT IF EXISTS delivery_zones_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_partners DROP CONSTRAINT IF EXISTS delivery_partners_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_partner_documents DROP CONSTRAINT IF EXISTS delivery_partner_documents_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_notifications DROP CONSTRAINT IF EXISTS delivery_notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.customers DROP CONSTRAINT IF EXISTS customers_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_addresses DROP CONSTRAINT IF EXISTS customer_addresses_pkey;
ALTER TABLE IF EXISTS ONLY public.business_hours DROP CONSTRAINT IF EXISTS business_hours_pkey;
ALTER TABLE IF EXISTS ONLY public.analytics DROP CONSTRAINT IF EXISTS analytics_pkey;
ALTER TABLE IF EXISTS public.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shops ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shop_products ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shop_product_images ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shop_images ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.shop_documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.settings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.promotions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.product_categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.permissions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.password_reset_tokens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.partner_zone_assignments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.partner_earnings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.partner_availability ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.orders ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.order_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.order_assignments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.mobile_otps ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.master_products ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.master_product_images ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_zones ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_tracking ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_partners ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_partner_documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.customers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.customer_addresses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.business_hours ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.analytics ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.users_id_seq;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_permissions;
DROP SEQUENCE IF EXISTS public.shops_id_seq;
DROP TABLE IF EXISTS public.shops;
DROP SEQUENCE IF EXISTS public.shop_products_id_seq;
DROP TABLE IF EXISTS public.shop_products;
DROP SEQUENCE IF EXISTS public.shop_product_images_id_seq;
DROP TABLE IF EXISTS public.shop_product_images;
DROP SEQUENCE IF EXISTS public.shop_images_id_seq;
DROP TABLE IF EXISTS public.shop_images;
DROP SEQUENCE IF EXISTS public.shop_documents_id_seq;
DROP TABLE IF EXISTS public.shop_documents;
DROP SEQUENCE IF EXISTS public.settings_id_seq;
DROP TABLE IF EXISTS public.settings;
DROP SEQUENCE IF EXISTS public.promotions_id_seq;
DROP TABLE IF EXISTS public.promotions;
DROP SEQUENCE IF EXISTS public.product_categories_id_seq;
DROP TABLE IF EXISTS public.product_categories;
DROP SEQUENCE IF EXISTS public.permissions_id_seq;
DROP TABLE IF EXISTS public.permissions;
DROP SEQUENCE IF EXISTS public.password_reset_tokens_id_seq;
DROP TABLE IF EXISTS public.password_reset_tokens;
DROP SEQUENCE IF EXISTS public.partner_zone_assignments_id_seq;
DROP TABLE IF EXISTS public.partner_zone_assignments;
DROP SEQUENCE IF EXISTS public.partner_earnings_id_seq;
DROP TABLE IF EXISTS public.partner_earnings;
DROP SEQUENCE IF EXISTS public.partner_availability_id_seq;
DROP TABLE IF EXISTS public.partner_availability;
DROP SEQUENCE IF EXISTS public.orders_id_seq;
DROP TABLE IF EXISTS public.orders;
DROP SEQUENCE IF EXISTS public.order_items_id_seq;
DROP TABLE IF EXISTS public.order_items;
DROP SEQUENCE IF EXISTS public.order_assignments_id_seq;
DROP TABLE IF EXISTS public.order_assignments;
DROP SEQUENCE IF EXISTS public.notifications_id_seq;
DROP TABLE IF EXISTS public.notifications;
DROP SEQUENCE IF EXISTS public.mobile_otps_id_seq;
DROP TABLE IF EXISTS public.mobile_otps;
DROP SEQUENCE IF EXISTS public.master_products_id_seq;
DROP TABLE IF EXISTS public.master_products;
DROP SEQUENCE IF EXISTS public.master_product_images_id_seq;
DROP TABLE IF EXISTS public.master_product_images;
DROP SEQUENCE IF EXISTS public.delivery_zones_id_seq;
DROP TABLE IF EXISTS public.delivery_zones;
DROP SEQUENCE IF EXISTS public.delivery_tracking_id_seq;
DROP TABLE IF EXISTS public.delivery_tracking;
DROP SEQUENCE IF EXISTS public.delivery_partners_id_seq;
DROP TABLE IF EXISTS public.delivery_partners;
DROP SEQUENCE IF EXISTS public.delivery_partner_documents_id_seq;
DROP TABLE IF EXISTS public.delivery_partner_documents;
DROP SEQUENCE IF EXISTS public.delivery_notifications_id_seq;
DROP TABLE IF EXISTS public.delivery_notifications;
DROP SEQUENCE IF EXISTS public.customers_id_seq;
DROP TABLE IF EXISTS public.customers;
DROP SEQUENCE IF EXISTS public.customer_addresses_id_seq;
DROP TABLE IF EXISTS public.customer_addresses;
DROP SEQUENCE IF EXISTS public.business_hours_id_seq;
DROP TABLE IF EXISTS public.business_hours;
DROP SEQUENCE IF EXISTS public.analytics_id_seq;
DROP TABLE IF EXISTS public.analytics;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analytics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytics (
    id bigint NOT NULL,
    additional_data text,
    category character varying(100),
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    metric_name character varying(100) NOT NULL,
    metric_type character varying(50) NOT NULL,
    metric_value numeric(38,2) NOT NULL,
    period_end timestamp(6) without time zone NOT NULL,
    period_start timestamp(6) without time zone NOT NULL,
    period_type character varying(20) NOT NULL,
    shop_id bigint,
    sub_category character varying(100),
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    user_id bigint,
    CONSTRAINT analytics_metric_type_check CHECK (((metric_type)::text = ANY ((ARRAY['REVENUE'::character varying, 'ORDER_COUNT'::character varying, 'CUSTOMER_COUNT'::character varying, 'CONVERSION_RATE'::character varying, 'AVERAGE_ORDER_VALUE'::character varying, 'PRODUCT_SALES'::character varying, 'CUSTOMER_ACQUISITION'::character varying, 'CUSTOMER_RETENTION'::character varying, 'PAGE_VIEWS'::character varying, 'BOUNCE_RATE'::character varying, 'SESSION_DURATION'::character varying, 'TRAFFIC_SOURCE'::character varying, 'GEOGRAPHIC_DATA'::character varying, 'INVENTORY_TURNOVER'::character varying, 'PROFIT_MARGIN'::character varying, 'CUSTOMER_SATISFACTION'::character varying])::text[]))),
    CONSTRAINT analytics_period_type_check CHECK (((period_type)::text = ANY ((ARRAY['DAILY'::character varying, 'WEEKLY'::character varying, 'MONTHLY'::character varying, 'QUARTERLY'::character varying, 'YEARLY'::character varying, 'CUSTOM'::character varying])::text[])))
);


ALTER TABLE public.analytics OWNER TO postgres;

--
-- Name: analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analytics_id_seq OWNER TO postgres;

--
-- Name: analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytics_id_seq OWNED BY public.analytics.id;


--
-- Name: business_hours; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_hours (
    id bigint NOT NULL,
    break_end_time time(6) without time zone,
    break_start_time time(6) without time zone,
    close_time time(6) without time zone,
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    day_of_week character varying(255) NOT NULL,
    is24hours boolean,
    is_open boolean,
    open_time time(6) without time zone,
    shop_id bigint NOT NULL,
    special_note character varying(255),
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    CONSTRAINT business_hours_day_of_week_check CHECK (((day_of_week)::text = ANY ((ARRAY['MONDAY'::character varying, 'TUESDAY'::character varying, 'WEDNESDAY'::character varying, 'THURSDAY'::character varying, 'FRIDAY'::character varying, 'SATURDAY'::character varying, 'SUNDAY'::character varying])::text[])))
);


ALTER TABLE public.business_hours OWNER TO postgres;

--
-- Name: business_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.business_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.business_hours_id_seq OWNER TO postgres;

--
-- Name: business_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.business_hours_id_seq OWNED BY public.business_hours.id;


--
-- Name: customer_addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_addresses (
    id bigint NOT NULL,
    address_label character varying(100),
    address_line1 character varying(200) NOT NULL,
    address_line2 character varying(200),
    address_type character varying(50) NOT NULL,
    city character varying(100) NOT NULL,
    contact_mobile_number character varying(15),
    contact_person_name character varying(100),
    country character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100) NOT NULL,
    delivery_instructions character varying(500),
    is_active boolean,
    is_default boolean,
    landmark character varying(100),
    latitude double precision,
    longitude double precision,
    postal_code character varying(10) NOT NULL,
    state character varying(100) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    updated_by character varying(100) NOT NULL,
    customer_id bigint NOT NULL
);


ALTER TABLE public.customer_addresses OWNER TO postgres;

--
-- Name: customer_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_addresses_id_seq OWNER TO postgres;

--
-- Name: customer_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_addresses_id_seq OWNED BY public.customer_addresses.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customers (
    id bigint NOT NULL,
    address_line1 character varying(200),
    address_line2 character varying(200),
    alternate_mobile_number character varying(15),
    city character varying(100),
    country character varying(50),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100) NOT NULL,
    date_of_birth date,
    email character varying(100) NOT NULL,
    email_notifications boolean,
    email_verified_at timestamp(6) without time zone,
    first_name character varying(100) NOT NULL,
    gender character varying(10),
    is_active boolean,
    is_verified boolean,
    last_login_date timestamp(6) without time zone,
    last_name character varying(100) NOT NULL,
    last_order_date timestamp(6) without time zone,
    latitude double precision,
    longitude double precision,
    mobile_number character varying(15) NOT NULL,
    mobile_verified_at timestamp(6) without time zone,
    notes character varying(500),
    postal_code character varying(10),
    preferred_language character varying(50),
    promotional_emails boolean,
    referral_code character varying(50),
    referred_by character varying(50),
    sms_notifications boolean,
    state character varying(100),
    status character varying(20),
    total_orders integer,
    total_spent double precision,
    updated_at timestamp(6) without time zone NOT NULL,
    updated_by character varying(100) NOT NULL,
    CONSTRAINT customers_gender_check CHECK (((gender)::text = ANY ((ARRAY['MALE'::character varying, 'FEMALE'::character varying, 'OTHER'::character varying, 'PREFER_NOT_TO_SAY'::character varying])::text[]))),
    CONSTRAINT customers_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'BLOCKED'::character varying, 'PENDING_VERIFICATION'::character varying])::text[])))
);


ALTER TABLE public.customers OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customers_id_seq OWNER TO postgres;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: delivery_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_notifications (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    delivery_status character varying(20),
    is_sent boolean,
    message text NOT NULL,
    metadata jsonb,
    notification_type character varying(50) NOT NULL,
    send_email boolean,
    send_push boolean,
    send_sms boolean,
    sent_at timestamp(6) without time zone,
    title character varying(255) NOT NULL,
    customer_id bigint NOT NULL,
    partner_id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    CONSTRAINT delivery_notifications_notification_type_check CHECK (((notification_type)::text = ANY ((ARRAY['ORDER_ASSIGNED'::character varying, 'ORDER_ACCEPTED'::character varying, 'ORDER_PICKED_UP'::character varying, 'OUT_FOR_DELIVERY'::character varying, 'DELIVERED'::character varying, 'DELAYED'::character varying, 'CANCELLED'::character varying, 'LOCATION_UPDATE'::character varying])::text[])))
);


ALTER TABLE public.delivery_notifications OWNER TO postgres;

--
-- Name: delivery_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_notifications_id_seq OWNER TO postgres;

--
-- Name: delivery_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_notifications_id_seq OWNED BY public.delivery_notifications.id;


--
-- Name: delivery_partner_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_partner_documents (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    document_number character varying(100),
    document_type character varying(50) NOT NULL,
    document_url character varying(500) NOT NULL,
    expiry_date date,
    rejection_reason text,
    updated_at timestamp(6) without time zone NOT NULL,
    verification_status character varying(20),
    verified_at timestamp(6) without time zone,
    partner_id bigint NOT NULL,
    verified_by bigint,
    CONSTRAINT delivery_partner_documents_document_type_check CHECK (((document_type)::text = ANY ((ARRAY['DRIVING_LICENSE'::character varying, 'AADHAR_CARD'::character varying, 'PAN_CARD'::character varying, 'VEHICLE_RC'::character varying, 'INSURANCE_CERTIFICATE'::character varying, 'POLICE_VERIFICATION'::character varying, 'PROFILE_PHOTO'::character varying, 'BANK_PASSBOOK'::character varying, 'VEHICLE_PHOTO'::character varying])::text[]))),
    CONSTRAINT delivery_partner_documents_verification_status_check CHECK (((verification_status)::text = ANY ((ARRAY['PENDING'::character varying, 'VERIFIED'::character varying, 'REJECTED'::character varying])::text[])))
);


ALTER TABLE public.delivery_partner_documents OWNER TO postgres;

--
-- Name: delivery_partner_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_partner_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_partner_documents_id_seq OWNER TO postgres;

--
-- Name: delivery_partner_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_partner_documents_id_seq OWNED BY public.delivery_partner_documents.id;


--
-- Name: delivery_partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_partners (
    id bigint NOT NULL,
    account_holder_name character varying(255),
    address_line1 character varying(500) NOT NULL,
    address_line2 character varying(500),
    alternate_phone character varying(15),
    bank_account_number character varying(20),
    bank_ifsc_code character varying(11),
    bank_name character varying(100),
    city character varying(100) NOT NULL,
    country character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100),
    current_latitude numeric(10,6),
    current_longitude numeric(10,6),
    date_of_birth date,
    email character varying(255) NOT NULL,
    emergency_contact_name character varying(255),
    emergency_contact_phone character varying(15),
    full_name character varying(255) NOT NULL,
    gender character varying(10),
    is_available boolean,
    is_online boolean,
    last_location_update timestamp(6) without time zone,
    last_seen timestamp(6) without time zone,
    license_expiry_date date NOT NULL,
    license_number character varying(30) NOT NULL,
    max_delivery_radius numeric(8,2),
    partner_id character varying(20) NOT NULL,
    phone_number character varying(15) NOT NULL,
    postal_code character varying(20) NOT NULL,
    profile_image_url character varying(500),
    rating numeric(3,2),
    service_areas text,
    state character varying(100) NOT NULL,
    status character varying(20),
    successful_deliveries integer,
    total_deliveries integer,
    total_earnings numeric(10,2),
    updated_at timestamp(6) without time zone NOT NULL,
    updated_by character varying(100),
    vehicle_color character varying(50),
    vehicle_model character varying(100),
    vehicle_number character varying(20) NOT NULL,
    vehicle_type character varying(20) NOT NULL,
    verification_status character varying(20),
    user_id bigint,
    CONSTRAINT delivery_partners_gender_check CHECK (((gender)::text = ANY ((ARRAY['MALE'::character varying, 'FEMALE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT delivery_partners_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'SUSPENDED'::character varying, 'BLOCKED'::character varying, 'ACTIVE'::character varying])::text[]))),
    CONSTRAINT delivery_partners_vehicle_type_check CHECK (((vehicle_type)::text = ANY ((ARRAY['BIKE'::character varying, 'SCOOTER'::character varying, 'BICYCLE'::character varying, 'CAR'::character varying, 'AUTO'::character varying])::text[]))),
    CONSTRAINT delivery_partners_verification_status_check CHECK (((verification_status)::text = ANY ((ARRAY['PENDING'::character varying, 'VERIFIED'::character varying, 'REJECTED'::character varying])::text[])))
);


ALTER TABLE public.delivery_partners OWNER TO postgres;

--
-- Name: delivery_partners_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_partners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_partners_id_seq OWNER TO postgres;

--
-- Name: delivery_partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_partners_id_seq OWNED BY public.delivery_partners.id;


--
-- Name: delivery_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_tracking (
    id bigint NOT NULL,
    accuracy numeric(8,2),
    altitude numeric(8,2),
    battery_level integer,
    created_at timestamp(6) without time zone NOT NULL,
    distance_to_destination numeric(8,2),
    distance_traveled numeric(8,2),
    estimated_arrival_time timestamp(6) without time zone,
    heading numeric(5,2),
    is_moving boolean,
    latitude numeric(10,6) NOT NULL,
    longitude numeric(10,6) NOT NULL,
    speed numeric(8,2),
    tracked_at timestamp(6) without time zone,
    assignment_id bigint NOT NULL
);


ALTER TABLE public.delivery_tracking OWNER TO postgres;

--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_tracking_id_seq OWNER TO postgres;

--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_tracking_id_seq OWNED BY public.delivery_tracking.id;


--
-- Name: delivery_zones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delivery_zones (
    id bigint NOT NULL,
    boundaries jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    delivery_fee numeric(10,2),
    is_active boolean,
    max_delivery_time integer,
    min_order_amount numeric(10,2),
    service_end_time time(6) without time zone,
    service_start_time time(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    zone_code character varying(20) NOT NULL,
    zone_name character varying(100) NOT NULL
);


ALTER TABLE public.delivery_zones OWNER TO postgres;

--
-- Name: delivery_zones_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delivery_zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_zones_id_seq OWNER TO postgres;

--
-- Name: delivery_zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delivery_zones_id_seq OWNED BY public.delivery_zones.id;


--
-- Name: master_product_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.master_product_images (
    id bigint NOT NULL,
    alt_text character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    image_url character varying(255) NOT NULL,
    is_primary boolean,
    sort_order integer,
    master_product_id bigint NOT NULL
);


ALTER TABLE public.master_product_images OWNER TO postgres;

--
-- Name: master_product_images_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.master_product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.master_product_images_id_seq OWNER TO postgres;

--
-- Name: master_product_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.master_product_images_id_seq OWNED BY public.master_product_images.id;


--
-- Name: master_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.master_products (
    id bigint NOT NULL,
    barcode character varying(255),
    base_unit character varying(255),
    base_weight numeric(10,3),
    brand character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    description character varying(2000),
    is_featured boolean,
    is_global boolean,
    name character varying(255) NOT NULL,
    sku character varying(255) NOT NULL,
    specifications character varying(1000),
    status character varying(255),
    updated_at timestamp(6) without time zone,
    updated_by character varying(255),
    category_id bigint NOT NULL,
    CONSTRAINT master_products_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'DISCONTINUED'::character varying])::text[])))
);


ALTER TABLE public.master_products OWNER TO postgres;

--
-- Name: master_products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.master_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.master_products_id_seq OWNER TO postgres;

--
-- Name: master_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.master_products_id_seq OWNED BY public.master_products.id;


--
-- Name: mobile_otps; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mobile_otps (
    id bigint NOT NULL,
    app_version character varying(50),
    attempt_count integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    device_id character varying(100),
    device_type character varying(20),
    expires_at timestamp(6) without time zone NOT NULL,
    ip_address character varying(45),
    is_active boolean NOT NULL,
    is_used boolean NOT NULL,
    max_attempts integer NOT NULL,
    mobile_number character varying(15) NOT NULL,
    otp_code character varying(6) NOT NULL,
    purpose character varying(20) NOT NULL,
    session_id character varying(100),
    verified_at timestamp(6) without time zone,
    verified_by character varying(100),
    CONSTRAINT mobile_otps_purpose_check CHECK (((purpose)::text = ANY ((ARRAY['REGISTRATION'::character varying, 'LOGIN'::character varying, 'FORGOT_PASSWORD'::character varying, 'CHANGE_MOBILE'::character varying, 'VERIFY_MOBILE'::character varying, 'ORDER_CONFIRMATION'::character varying, 'ACCOUNT_VERIFICATION'::character varying])::text[])))
);


ALTER TABLE public.mobile_otps OWNER TO postgres;

--
-- Name: mobile_otps_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mobile_otps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mobile_otps_id_seq OWNER TO postgres;

--
-- Name: mobile_otps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mobile_otps_id_seq OWNED BY public.mobile_otps.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    action_text character varying(100),
    action_url character varying(500),
    category character varying(100),
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    expires_at timestamp(6) without time zone,
    icon character varying(100),
    image_url character varying(500),
    is_active boolean,
    is_email_sent boolean,
    is_persistent boolean,
    is_push_sent boolean,
    message text NOT NULL,
    metadata text,
    priority character varying(20) NOT NULL,
    read_at timestamp(6) without time zone,
    recipient_id bigint NOT NULL,
    recipient_type character varying(20) NOT NULL,
    reference_id bigint,
    reference_type character varying(50),
    scheduled_at timestamp(6) without time zone,
    sender_id bigint,
    sender_type character varying(20),
    sent_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    tags character varying(500),
    title character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    CONSTRAINT notifications_priority_check CHECK (((priority)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT notifications_recipient_type_check CHECK (((recipient_type)::text = ANY ((ARRAY['USER'::character varying, 'CUSTOMER'::character varying, 'SHOP_OWNER'::character varying, 'ADMIN'::character varying, 'ALL_USERS'::character varying, 'ALL_CUSTOMERS'::character varying, 'ALL_SHOP_OWNERS'::character varying])::text[]))),
    CONSTRAINT notifications_sender_type_check CHECK (((sender_type)::text = ANY ((ARRAY['SYSTEM'::character varying, 'USER'::character varying, 'ADMIN'::character varying, 'SHOP_OWNER'::character varying, 'CUSTOMER'::character varying])::text[]))),
    CONSTRAINT notifications_status_check CHECK (((status)::text = ANY ((ARRAY['UNREAD'::character varying, 'READ'::character varying, 'ARCHIVED'::character varying, 'DELETED'::character varying])::text[]))),
    CONSTRAINT notifications_type_check CHECK (((type)::text = ANY ((ARRAY['INFO'::character varying, 'SUCCESS'::character varying, 'WARNING'::character varying, 'ERROR'::character varying, 'ORDER'::character varying, 'PAYMENT'::character varying, 'SYSTEM'::character varying, 'PROMOTION'::character varying, 'REMINDER'::character varying, 'ANNOUNCEMENT'::character varying])::text[])))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO postgres;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: order_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_assignments (
    id bigint NOT NULL,
    accepted_at timestamp(6) without time zone,
    assigned_at timestamp(6) without time zone,
    assignment_type character varying(20),
    created_at timestamp(6) without time zone NOT NULL,
    customer_feedback text,
    customer_rating integer,
    delivery_fee numeric(10,2) NOT NULL,
    delivery_latitude numeric(10,6),
    delivery_longitude numeric(10,6),
    delivery_notes text,
    delivery_time timestamp(6) without time zone,
    partner_commission numeric(10,2),
    pickup_latitude numeric(10,6),
    pickup_longitude numeric(10,6),
    pickup_time timestamp(6) without time zone,
    rejection_reason text,
    status character varying(30),
    updated_at timestamp(6) without time zone NOT NULL,
    assigned_by bigint,
    partner_id bigint NOT NULL,
    order_id bigint NOT NULL,
    CONSTRAINT order_assignments_assignment_type_check CHECK (((assignment_type)::text = ANY ((ARRAY['AUTO'::character varying, 'MANUAL'::character varying])::text[]))),
    CONSTRAINT order_assignments_status_check CHECK (((status)::text = ANY ((ARRAY['ASSIGNED'::character varying, 'ACCEPTED'::character varying, 'REJECTED'::character varying, 'PICKED_UP'::character varying, 'IN_TRANSIT'::character varying, 'DELIVERED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying, 'RETURNED'::character varying])::text[])))
);


ALTER TABLE public.order_assignments OWNER TO postgres;

--
-- Name: order_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_assignments_id_seq OWNER TO postgres;

--
-- Name: order_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_assignments_id_seq OWNED BY public.order_assignments.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    product_description character varying(500),
    product_image_url character varying(500),
    product_name character varying(255) NOT NULL,
    product_sku character varying(50),
    quantity integer NOT NULL,
    special_instructions character varying(500),
    total_price numeric(10,2) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    order_id bigint NOT NULL,
    shop_product_id bigint NOT NULL
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_items_id_seq OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    actual_delivery_time timestamp(6) without time zone,
    cancellation_reason character varying(500),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100) NOT NULL,
    delivery_address character varying(200),
    delivery_city character varying(100),
    delivery_contact_name character varying(100),
    delivery_fee numeric(10,2) NOT NULL,
    delivery_phone character varying(15),
    delivery_postal_code character varying(10),
    delivery_state character varying(100),
    discount_amount numeric(10,2),
    estimated_delivery_time timestamp(6) without time zone,
    notes character varying(500),
    order_number character varying(255) NOT NULL,
    payment_method character varying(255),
    payment_status character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    tax_amount numeric(10,2) NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    updated_by character varying(100) NOT NULL,
    customer_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    CONSTRAINT orders_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['CASH_ON_DELIVERY'::character varying, 'ONLINE_PAYMENT'::character varying, 'UPI'::character varying, 'CARD'::character varying, 'WALLET'::character varying])::text[]))),
    CONSTRAINT orders_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['PENDING'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'REFUNDED'::character varying, 'PARTIALLY_REFUNDED'::character varying])::text[]))),
    CONSTRAINT orders_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'CONFIRMED'::character varying, 'PREPARING'::character varying, 'READY_FOR_PICKUP'::character varying, 'OUT_FOR_DELIVERY'::character varying, 'DELIVERED'::character varying, 'CANCELLED'::character varying, 'REFUNDED'::character varying])::text[])))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_id_seq OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: partner_availability; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_availability (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    day_of_week integer,
    end_time time(6) without time zone NOT NULL,
    is_available boolean,
    is_special_schedule boolean,
    specific_date date,
    start_time time(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    partner_id bigint NOT NULL
);


ALTER TABLE public.partner_availability OWNER TO postgres;

--
-- Name: partner_availability_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_availability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.partner_availability_id_seq OWNER TO postgres;

--
-- Name: partner_availability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_availability_id_seq OWNED BY public.partner_availability.id;


--
-- Name: partner_earnings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_earnings (
    id bigint NOT NULL,
    base_amount numeric(10,2) NOT NULL,
    bonus_amount numeric(10,2),
    created_at timestamp(6) without time zone NOT NULL,
    distance_covered numeric(8,2),
    earning_date date,
    incentive_amount numeric(10,2),
    payment_date timestamp(6) without time zone,
    payment_method character varying(20),
    payment_reference character varying(100),
    payment_status character varying(20),
    penalty_amount numeric(10,2),
    surge_multiplier numeric(3,2),
    time_taken integer,
    total_amount numeric(10,2) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    partner_id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    CONSTRAINT partner_earnings_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['BANK_TRANSFER'::character varying, 'UPI'::character varying, 'CASH'::character varying, 'WALLET'::character varying])::text[]))),
    CONSTRAINT partner_earnings_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['PENDING'::character varying, 'PROCESSED'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'HOLD'::character varying])::text[])))
);


ALTER TABLE public.partner_earnings OWNER TO postgres;

--
-- Name: partner_earnings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_earnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.partner_earnings_id_seq OWNER TO postgres;

--
-- Name: partner_earnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_earnings_id_seq OWNED BY public.partner_earnings.id;


--
-- Name: partner_zone_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_zone_assignments (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    priority integer,
    partner_id bigint NOT NULL,
    zone_id bigint NOT NULL
);


ALTER TABLE public.partner_zone_assignments OWNER TO postgres;

--
-- Name: partner_zone_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_zone_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.partner_zone_assignments_id_seq OWNER TO postgres;

--
-- Name: partner_zone_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_zone_assignments_id_seq OWNED BY public.partner_zone_assignments.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying(255) NOT NULL,
    expiry_date timestamp(6) without time zone NOT NULL,
    token character varying(255) NOT NULL,
    used boolean NOT NULL,
    username character varying(255) NOT NULL
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.password_reset_tokens_id_seq OWNER TO postgres;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    action_type character varying(50),
    active boolean,
    category character varying(100),
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    description character varying(200),
    name character varying(100) NOT NULL,
    resource_type character varying(50),
    updated_at timestamp(6) without time zone,
    updated_by character varying(100)
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_id_seq OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_categories (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    description character varying(255),
    icon_url character varying(255),
    is_active boolean,
    name character varying(255) NOT NULL,
    slug character varying(255),
    sort_order integer,
    updated_at timestamp(6) without time zone,
    updated_by character varying(255),
    parent_id bigint
);


ALTER TABLE public.product_categories OWNER TO postgres;

--
-- Name: product_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_categories_id_seq OWNER TO postgres;

--
-- Name: product_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_categories_id_seq OWNED BY public.product_categories.id;


--
-- Name: promotions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.promotions (
    id bigint NOT NULL,
    banner_url character varying(255),
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    description text,
    discount_value numeric(38,2) NOT NULL,
    end_date timestamp(6) without time zone NOT NULL,
    image_url character varying(255),
    is_first_time_only boolean,
    is_public boolean,
    maximum_discount_amount numeric(38,2),
    minimum_order_amount numeric(38,2),
    shop_id bigint,
    stackable boolean,
    start_date timestamp(6) without time zone NOT NULL,
    status character varying(20) NOT NULL,
    target_audience character varying(50),
    terms_and_conditions text,
    title character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    usage_limit integer,
    usage_limit_per_customer integer,
    used_count integer,
    CONSTRAINT promotions_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'EXPIRED'::character varying, 'SUSPENDED'::character varying])::text[]))),
    CONSTRAINT promotions_type_check CHECK (((type)::text = ANY ((ARRAY['PERCENTAGE'::character varying, 'FIXED_AMOUNT'::character varying, 'FREE_SHIPPING'::character varying, 'BUY_ONE_GET_ONE'::character varying])::text[])))
);


ALTER TABLE public.promotions OWNER TO postgres;

--
-- Name: promotions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.promotions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.promotions_id_seq OWNER TO postgres;

--
-- Name: promotions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.promotions_id_seq OWNED BY public.promotions.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    category character varying(50),
    created_at timestamp(6) without time zone,
    created_by character varying(100),
    default_value text,
    description character varying(200),
    display_order integer,
    is_active boolean,
    is_read_only boolean,
    is_required boolean,
    scope character varying(20) NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_type character varying(20) NOT NULL,
    setting_value text NOT NULL,
    shop_id bigint,
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    user_id bigint,
    validation_rules text,
    CONSTRAINT settings_scope_check CHECK (((scope)::text = ANY ((ARRAY['GLOBAL'::character varying, 'SHOP'::character varying, 'USER'::character varying])::text[]))),
    CONSTRAINT settings_setting_type_check CHECK (((setting_type)::text = ANY ((ARRAY['STRING'::character varying, 'INTEGER'::character varying, 'BOOLEAN'::character varying, 'DECIMAL'::character varying, 'JSON'::character varying, 'EMAIL'::character varying, 'URL'::character varying, 'PASSWORD'::character varying, 'FILE_PATH'::character varying, 'COLOR'::character varying, 'DATE'::character varying, 'TIME'::character varying, 'DATETIME'::character varying])::text[])))
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.settings_id_seq OWNER TO postgres;

--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: shop_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shop_documents (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    document_name character varying(255) NOT NULL,
    document_type character varying(255) NOT NULL,
    file_path character varying(255) NOT NULL,
    file_size bigint,
    file_type character varying(255),
    is_required boolean,
    original_filename character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone,
    verification_notes character varying(255),
    verification_status character varying(255),
    verified_at timestamp(6) without time zone,
    verified_by character varying(255),
    shop_id bigint NOT NULL,
    CONSTRAINT shop_documents_document_type_check CHECK (((document_type)::text = ANY ((ARRAY['BUSINESS_LICENSE'::character varying, 'GST_CERTIFICATE'::character varying, 'PAN_CARD'::character varying, 'AADHAR_CARD'::character varying, 'BANK_STATEMENT'::character varying, 'ADDRESS_PROOF'::character varying, 'OWNER_PHOTO'::character varying, 'SHOP_PHOTO'::character varying, 'FOOD_LICENSE'::character varying, 'FSSAI_CERTIFICATE'::character varying, 'DRUG_LICENSE'::character varying, 'TRADE_LICENSE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT shop_documents_verification_status_check CHECK (((verification_status)::text = ANY ((ARRAY['PENDING'::character varying, 'VERIFIED'::character varying, 'REJECTED'::character varying, 'EXPIRED'::character varying])::text[])))
);


ALTER TABLE public.shop_documents OWNER TO postgres;

--
-- Name: shop_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shop_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_documents_id_seq OWNER TO postgres;

--
-- Name: shop_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shop_documents_id_seq OWNED BY public.shop_documents.id;


--
-- Name: shop_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shop_images (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    image_type character varying(255),
    image_url character varying(255) NOT NULL,
    is_primary boolean,
    shop_id bigint NOT NULL,
    CONSTRAINT shop_images_image_type_check CHECK (((image_type)::text = ANY ((ARRAY['LOGO'::character varying, 'BANNER'::character varying, 'GALLERY'::character varying])::text[])))
);


ALTER TABLE public.shop_images OWNER TO postgres;

--
-- Name: shop_images_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shop_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_images_id_seq OWNER TO postgres;

--
-- Name: shop_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shop_images_id_seq OWNED BY public.shop_images.id;


--
-- Name: shop_product_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shop_product_images (
    id bigint NOT NULL,
    alt_text character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    image_url character varying(255) NOT NULL,
    is_primary boolean,
    sort_order integer,
    shop_product_id bigint NOT NULL
);


ALTER TABLE public.shop_product_images OWNER TO postgres;

--
-- Name: shop_product_images_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shop_product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_product_images_id_seq OWNER TO postgres;

--
-- Name: shop_product_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shop_product_images_id_seq OWNED BY public.shop_product_images.id;


--
-- Name: shop_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shop_products (
    id bigint NOT NULL,
    cost_price numeric(10,2),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    custom_attributes character varying(2000),
    custom_description character varying(1000),
    custom_name character varying(255),
    display_order integer,
    is_available boolean,
    is_featured boolean,
    max_stock_level integer,
    min_stock_level integer,
    original_price numeric(10,2),
    price numeric(10,2) NOT NULL,
    status character varying(255),
    stock_quantity integer,
    tags character varying(255),
    track_inventory boolean,
    updated_at timestamp(6) without time zone,
    updated_by character varying(255),
    master_product_id bigint NOT NULL,
    shop_id bigint NOT NULL,
    CONSTRAINT shop_products_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'OUT_OF_STOCK'::character varying, 'DISCONTINUED'::character varying])::text[])))
);


ALTER TABLE public.shop_products OWNER TO postgres;

--
-- Name: shop_products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shop_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shop_products_id_seq OWNER TO postgres;

--
-- Name: shop_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shop_products_id_seq OWNED BY public.shop_products.id;


--
-- Name: shops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.shops (
    id bigint NOT NULL,
    address_line1 character varying(255) NOT NULL,
    business_name character varying(255),
    business_type character varying(255) NOT NULL,
    city character varying(255) NOT NULL,
    commission_rate numeric(5,2),
    country character varying(255) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(255),
    delivery_fee numeric(10,2),
    delivery_radius numeric(8,2),
    description text,
    free_delivery_above numeric(10,2),
    gst_number character varying(255),
    is_active boolean,
    is_featured boolean,
    is_verified boolean,
    latitude numeric(10,6),
    longitude numeric(10,6),
    min_order_amount numeric(10,2),
    name character varying(255) NOT NULL,
    owner_email character varying(255) NOT NULL,
    owner_name character varying(255) NOT NULL,
    owner_phone character varying(255) NOT NULL,
    pan_number character varying(255),
    postal_code character varying(255) NOT NULL,
    product_count integer,
    rating numeric(3,2),
    shop_id character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    state character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    total_orders integer,
    total_revenue numeric(15,2),
    updated_at timestamp(6) without time zone,
    updated_by character varying(255),
    CONSTRAINT shops_business_type_check CHECK (((business_type)::text = ANY ((ARRAY['GROCERY'::character varying, 'PHARMACY'::character varying, 'RESTAURANT'::character varying, 'GENERAL'::character varying])::text[]))),
    CONSTRAINT shops_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'SUSPENDED'::character varying])::text[])))
);


ALTER TABLE public.shops OWNER TO postgres;

--
-- Name: shops_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shops_id_seq OWNER TO postgres;

--
-- Name: shops_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shops_id_seq OWNED BY public.shops.id;


--
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_permissions (
    user_id bigint NOT NULL,
    permission_id bigint NOT NULL
);


ALTER TABLE public.user_permissions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    account_locked_until timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100),
    department character varying(100),
    designation character varying(100),
    email character varying(100) NOT NULL,
    email_verified boolean,
    failed_login_attempts integer,
    first_name character varying(100),
    is_active boolean,
    is_temporary_password boolean,
    last_login timestamp(6) without time zone,
    last_name character varying(100),
    last_password_change timestamp(6) without time zone,
    mobile_number character varying(15),
    mobile_verified boolean,
    password character varying(255) NOT NULL,
    password_change_required boolean,
    profile_image_url character varying(255),
    reports_to bigint,
    role character varying(20) NOT NULL,
    status character varying(255) NOT NULL,
    two_factor_enabled boolean,
    updated_at timestamp(6) without time zone,
    updated_by character varying(100),
    username character varying(50) NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['SUPER_ADMIN'::character varying, 'ADMIN'::character varying, 'SHOP_OWNER'::character varying, 'MANAGER'::character varying, 'EMPLOYEE'::character varying, 'CUSTOMER_SERVICE'::character varying, 'DELIVERY_PARTNER'::character varying, 'USER'::character varying])::text[]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying, 'SUSPENDED'::character varying, 'PENDING_VERIFICATION'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: analytics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics ALTER COLUMN id SET DEFAULT nextval('public.analytics_id_seq'::regclass);


--
-- Name: business_hours id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_hours ALTER COLUMN id SET DEFAULT nextval('public.business_hours_id_seq'::regclass);


--
-- Name: customer_addresses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_addresses ALTER COLUMN id SET DEFAULT nextval('public.customer_addresses_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: delivery_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_notifications ALTER COLUMN id SET DEFAULT nextval('public.delivery_notifications_id_seq'::regclass);


--
-- Name: delivery_partner_documents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partner_documents ALTER COLUMN id SET DEFAULT nextval('public.delivery_partner_documents_id_seq'::regclass);


--
-- Name: delivery_partners id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners ALTER COLUMN id SET DEFAULT nextval('public.delivery_partners_id_seq'::regclass);


--
-- Name: delivery_tracking id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking ALTER COLUMN id SET DEFAULT nextval('public.delivery_tracking_id_seq'::regclass);


--
-- Name: delivery_zones id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_zones ALTER COLUMN id SET DEFAULT nextval('public.delivery_zones_id_seq'::regclass);


--
-- Name: master_product_images id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_product_images ALTER COLUMN id SET DEFAULT nextval('public.master_product_images_id_seq'::regclass);


--
-- Name: master_products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_products ALTER COLUMN id SET DEFAULT nextval('public.master_products_id_seq'::regclass);


--
-- Name: mobile_otps id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mobile_otps ALTER COLUMN id SET DEFAULT nextval('public.mobile_otps_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: order_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_assignments ALTER COLUMN id SET DEFAULT nextval('public.order_assignments_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: partner_availability id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_availability ALTER COLUMN id SET DEFAULT nextval('public.partner_availability_id_seq'::regclass);


--
-- Name: partner_earnings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_earnings ALTER COLUMN id SET DEFAULT nextval('public.partner_earnings_id_seq'::regclass);


--
-- Name: partner_zone_assignments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_zone_assignments ALTER COLUMN id SET DEFAULT nextval('public.partner_zone_assignments_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: product_categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_categories ALTER COLUMN id SET DEFAULT nextval('public.product_categories_id_seq'::regclass);


--
-- Name: promotions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promotions ALTER COLUMN id SET DEFAULT nextval('public.promotions_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: shop_documents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_documents ALTER COLUMN id SET DEFAULT nextval('public.shop_documents_id_seq'::regclass);


--
-- Name: shop_images id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_images ALTER COLUMN id SET DEFAULT nextval('public.shop_images_id_seq'::regclass);


--
-- Name: shop_product_images id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_product_images ALTER COLUMN id SET DEFAULT nextval('public.shop_product_images_id_seq'::regclass);


--
-- Name: shop_products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_products ALTER COLUMN id SET DEFAULT nextval('public.shop_products_id_seq'::regclass);


--
-- Name: shops id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shops ALTER COLUMN id SET DEFAULT nextval('public.shops_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: analytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.analytics (id, additional_data, category, created_at, created_by, metric_name, metric_type, metric_value, period_end, period_start, period_type, shop_id, sub_category, updated_at, updated_by, user_id) FROM stdin;
\.


--
-- Data for Name: business_hours; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.business_hours (id, break_end_time, break_start_time, close_time, created_at, created_by, day_of_week, is24hours, is_open, open_time, shop_id, special_note, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: customer_addresses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_addresses (id, address_label, address_line1, address_line2, address_type, city, contact_mobile_number, contact_person_name, country, created_at, created_by, delivery_instructions, is_active, is_default, landmark, latitude, longitude, postal_code, state, updated_at, updated_by, customer_id) FROM stdin;
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customers (id, address_line1, address_line2, alternate_mobile_number, city, country, created_at, created_by, date_of_birth, email, email_notifications, email_verified_at, first_name, gender, is_active, is_verified, last_login_date, last_name, last_order_date, latitude, longitude, mobile_number, mobile_verified_at, notes, postal_code, preferred_language, promotional_emails, referral_code, referred_by, sms_notifications, state, status, total_orders, total_spent, updated_at, updated_by) FROM stdin;
16	456 Brigade Road	\N	\N	Bangalore	India	2025-08-17 15:58:00.757436	system	\N	jane.smith@customer.com	\N	\N	Jane	\N	t	t	\N	Smith	\N	\N	\N	+919876543211	\N	\N	560002	\N	\N	\N	\N	\N	Karnataka	ACTIVE	\N	\N	2025-08-17 15:58:00.757436	system
15	123 MG Road	\N	\N	Bangalore	India	2025-08-17 15:58:00.757436	system	\N	thirunacse75@gmail.com	\N	\N	John	\N	t	t	\N	Doe	\N	\N	\N	+919876543210	\N	\N	560001	\N	\N	\N	\N	\N	Karnataka	ACTIVE	\N	\N	2025-08-17 15:58:00.757436	system
\.


--
-- Data for Name: delivery_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery_notifications (id, created_at, delivery_status, is_sent, message, metadata, notification_type, send_email, send_push, send_sms, sent_at, title, customer_id, partner_id, assignment_id) FROM stdin;
\.


--
-- Data for Name: delivery_partner_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery_partner_documents (id, created_at, document_number, document_type, document_url, expiry_date, rejection_reason, updated_at, verification_status, verified_at, partner_id, verified_by) FROM stdin;
\.


--
-- Data for Name: delivery_partners; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery_partners (id, account_holder_name, address_line1, address_line2, alternate_phone, bank_account_number, bank_ifsc_code, bank_name, city, country, created_at, created_by, current_latitude, current_longitude, date_of_birth, email, emergency_contact_name, emergency_contact_phone, full_name, gender, is_available, is_online, last_location_update, last_seen, license_expiry_date, license_number, max_delivery_radius, partner_id, phone_number, postal_code, profile_image_url, rating, service_areas, state, status, successful_deliveries, total_deliveries, total_earnings, updated_at, updated_by, vehicle_color, vehicle_model, vehicle_number, vehicle_type, verification_status, user_id) FROM stdin;
1	Ravi Kumar	123 Delivery Street	\N	\N	1234567890123456	HDFC0001234	\N	Chennai	India	2025-08-17 13:36:31.71435	system	\N	\N	1995-06-15	helec60392@jobzyy.com	Priya Kumar	9876543211	Ravi Kumar	MALE	t	t	\N	\N	2027-12-31	DL1420110012345	10.00	DP37791701	9876543210	600001	\N	5.00	\N	Tamil Nadu	ACTIVE	1	1	40.00	2025-08-17 13:57:16.207837	system	\N	Honda Activa 6G	TN01AB1234	BIKE	VERIFIED	90
\.


--
-- Data for Name: delivery_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery_tracking (id, accuracy, altitude, battery_level, created_at, distance_to_destination, distance_traveled, estimated_arrival_time, heading, is_moving, latitude, longitude, speed, tracked_at, assignment_id) FROM stdin;
\.


--
-- Data for Name: delivery_zones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delivery_zones (id, boundaries, created_at, delivery_fee, is_active, max_delivery_time, min_order_amount, service_end_time, service_start_time, updated_at, zone_code, zone_name) FROM stdin;
5	{"type": "Polygon", "coordinates": [[[77.5800, 12.9600], [77.6000, 12.9600], [77.6000, 12.9800], [77.5800, 12.9800], [77.5800, 12.9600]]]}	2025-08-18 01:19:15.027826	30.00	t	45	200.00	23:00:00	09:00:00	2025-08-18 01:19:15.027826	BLR_CENTRAL	Bangalore Central
6	{"type": "Polygon", "coordinates": [[[77.5600, 12.9800], [77.6200, 12.9800], [77.6200, 13.0200], [77.5600, 13.0200], [77.5600, 12.9800]]]}	2025-08-18 01:19:15.027826	40.00	t	60	250.00	22:00:00	08:00:00	2025-08-18 01:19:15.027826	BLR_NORTH	Bangalore North
7	{"type": "Polygon", "coordinates": [[[77.5500, 12.8500], [77.6500, 12.8500], [77.6500, 12.9500], [77.5500, 12.9500], [77.5500, 12.8500]]]}	2025-08-18 01:19:15.027826	35.00	t	50	300.00	21:00:00	09:00:00	2025-08-18 01:19:15.027826	BLR_SOUTH	Bangalore South
8	{"type": "Polygon", "coordinates": [[[77.6000, 12.9000], [77.7500, 12.9000], [77.7500, 13.0000], [77.6000, 13.0000], [77.6000, 12.9000]]]}	2025-08-18 01:19:15.027826	50.00	t	75	400.00	20:00:00	10:00:00	2025-08-18 01:19:15.027826	BLR_EAST	Bangalore East
\.


--
-- Data for Name: master_product_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.master_product_images (id, alt_text, created_at, created_by, image_url, is_primary, sort_order, master_product_id) FROM stdin;
\.


--
-- Data for Name: master_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.master_products (id, barcode, base_unit, base_weight, brand, created_at, created_by, description, is_featured, is_global, name, sku, specifications, status, updated_at, updated_by, category_id) FROM stdin;
1	1234567890123	pcs	0.168	Samsung	2025-08-17 15:21:10.381402	admin	Latest Samsung smartphone with advanced camera	t	t	Samsung Galaxy S24	SGS24-001	Display: 6.2 inches, RAM: 8GB, Storage: 256GB	ACTIVE	2025-08-17 15:21:10.381402	admin	1
2	2345678901234	pcs	0.500	Nike	2025-08-17 15:21:10.381402	admin	Comfortable running shoes	t	t	Nike Air Max 270	NAM270-001	Size: Various, Color: Multiple options available	ACTIVE	2025-08-17 15:21:10.381402	admin	2
3	3456789012345	box	0.100	Twinings	2025-08-17 15:21:10.381402	admin	Premium organic green tea leaves	f	t	Organic Green Tea	OGT-001	Weight: 100g, Organic certified, 20 tea bags	ACTIVE	2025-08-17 15:21:10.381402	admin	3
4	4567890123456	pcs	1.200	Dell	2025-08-17 15:21:10.381402	admin	High-performance ultrabook for professionals	t	t	Dell Laptop XPS 13	DELL-XPS13-001	Intel i7, 16GB RAM, 512GB SSD, 13.3 inch display	ACTIVE	2025-08-17 15:21:10.381402	admin	1
5	5678901234567	pcs	0.600	Levi's	2025-08-17 15:21:10.381402	admin	Classic straight fit denim jeans	f	t	Levi's Jeans 501	LEVI-501-001	Cotton denim, available in multiple sizes and washes	ACTIVE	2025-08-17 15:21:10.381402	admin	2
6	6789012345678	kg	1.000	Blue Tokai	2025-08-17 15:21:10.381402	admin	Premium roasted coffee beans	t	t	Coffee Beans Arabica	COFFEE-ARB-001	Single origin, medium roast, 250g pack	ACTIVE	2025-08-17 15:21:10.381402	admin	3
7	7890123456789	bag	5.000	Cocopeat	2025-08-17 15:21:10.381402	admin	Premium organic potting soil	f	t	Garden Soil Organic	SOIL-ORG-001	10kg bag, enriched with compost	ACTIVE	2025-08-17 15:21:10.381402	admin	4
8	8901234567890	pcs	0.800	O'Reilly	2025-08-17 15:21:10.381402	admin	Complete guide to Java programming	t	t	Programming Book Java	BOOK-JAVA-001	800 pages, includes examples and exercises	ACTIVE	2025-08-17 15:21:10.381402	admin	5
\.


--
-- Data for Name: mobile_otps; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mobile_otps (id, app_version, attempt_count, created_at, created_by, device_id, device_type, expires_at, ip_address, is_active, is_used, max_attempts, mobile_number, otp_code, purpose, session_id, verified_at, verified_by) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, action_text, action_url, category, created_at, created_by, expires_at, icon, image_url, is_active, is_email_sent, is_persistent, is_push_sent, message, metadata, priority, read_at, recipient_id, recipient_type, reference_id, reference_type, scheduled_at, sender_id, sender_type, sent_at, status, tags, title, type, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: order_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_assignments (id, accepted_at, assigned_at, assignment_type, created_at, customer_feedback, customer_rating, delivery_fee, delivery_latitude, delivery_longitude, delivery_notes, delivery_time, partner_commission, pickup_latitude, pickup_longitude, pickup_time, rejection_reason, status, updated_at, assigned_by, partner_id, order_id) FROM stdin;
1	2025-08-17 13:56:11.89223	2025-08-17 13:50:46.520299	MANUAL	2025-08-17 13:50:46.532117	\N	\N	50.00	13.087800	80.278500	Delivered successfully to customer. Package in good condition.	2025-08-17 13:57:16.182471	40.00	13.082700	80.270700	2025-08-17 13:56:31.470492	\N	DELIVERED	2025-08-17 13:57:16.195285	\N	1	34
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (id, created_at, product_description, product_image_url, product_name, product_sku, quantity, special_instructions, total_price, unit_price, updated_at, order_id, shop_product_id) FROM stdin;
11	2025-08-17 10:54:43.934535	Latest Samsung smartphone with advanced camera	\N	Samsung Galaxy S24	SGS24-001	1	\N	75000.00	75000.00	2025-08-17 10:54:43.934535	21	11
12	2025-08-17 10:54:43.937544	High-performance ultrabook for professionals	\N	Dell Laptop XPS 13	DELL-XPS13-001	1	\N	85000.00	85000.00	2025-08-17 10:54:43.937544	21	12
13	2025-08-17 11:13:22.919311	Latest Samsung smartphone with advanced camera	\N	Samsung Galaxy S24	SGS24-001	1	\N	75000.00	75000.00	2025-08-17 11:13:22.919311	22	11
14	2025-08-17 11:14:28.907833	High-performance ultrabook for professionals	\N	Dell Laptop XPS 13	DELL-XPS13-001	1	\N	85000.00	85000.00	2025-08-17 11:14:28.907833	23	12
15	2025-08-17 11:19:17.266881	Latest Samsung smartphone with advanced camera	\N	Samsung Galaxy S24	SGS24-001	1	\N	75000.00	75000.00	2025-08-17 11:19:17.266881	24	11
17	2025-08-17 11:23:34.404769	High-performance ultrabook for professionals	\N	Dell Laptop XPS 13	DELL-XPS13-001	1	\N	85000.00	85000.00	2025-08-17 11:23:34.404769	27	12
21	2025-08-17 13:04:52.970915	Latest Samsung smartphone with advanced camera	\N	Samsung Galaxy S24	SGS24-001	1	Handle with care	25999.00	25999.00	2025-08-17 13:04:52.970915	34	17
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, actual_delivery_time, cancellation_reason, created_at, created_by, delivery_address, delivery_city, delivery_contact_name, delivery_fee, delivery_phone, delivery_postal_code, delivery_state, discount_amount, estimated_delivery_time, notes, order_number, payment_method, payment_status, status, subtotal, tax_amount, total_amount, updated_at, updated_by, customer_id, shop_id) FROM stdin;
21	\N	\N	2025-08-17 10:54:43.924766	superadmin	123 MG Road, Bangalore	Bangalore	John Doe	50.00	9876543210	560001	Karnataka	0.00	\N	\N	ORD1755428083921	CASH_ON_DELIVERY	PENDING	PENDING	160000.00	8000.00	168050.00	2025-08-17 10:54:43.924766	superadmin	15	11
22	\N	\N	2025-08-17 11:13:22.915093	customer1	789 Test Lane	Bangalore	Test Customer	50.00	9876543210	560003	Karnataka	0.00	\N	\N	ORD1755429202915	CASH_ON_DELIVERY	PENDING	PENDING	75000.00	3750.00	78800.00	2025-08-17 11:13:22.915093	customer1	15	11
23	\N	\N	2025-08-17 11:14:28.90626	customer1	123 Email Test Street	Bangalore	Email Test Customer	50.00	9876543210	560003	Karnataka	0.00	\N	Test order for email integration	ORD1755429268905	CASH_ON_DELIVERY	PENDING	PENDING	85000.00	4250.00	89300.00	2025-08-17 11:14:28.90626	customer1	15	11
24	\N	\N	2025-08-17 11:19:17.264854	customer1	456 Template Test Road	Bangalore	Template Tester	50.00	9876543210	560004	Karnataka	0.00	\N	Testing email templates	ORD1755429557264	CASH_ON_DELIVERY	PENDING	PENDING	75000.00	3750.00	78800.00	2025-08-17 11:19:17.264854	customer1	15	11
27	\N	\N	2025-08-17 11:23:34.376051	customer1	789 Final Test Avenue	Bangalore	Final Tester	50.00	9876543210	560005	Karnataka	0.00	\N	Final email template test	ORD1755429814348	CASH_ON_DELIVERY	PENDING	PREPARING	85000.00	4250.00	89300.00	2025-08-17 11:27:04.873174	superadmin	15	11
34	2025-08-17 13:57:16.183363	\N	2025-08-17 13:04:52.965519	superadmin	456 Customer Street, Near Tech Park	Bangalore	Thiru Kumar	50.00	9876543211	560002	Karnataka	0.00	2025-08-17 13:35:25.562356	Test order for API workflow\n[Shop Owner] Order accepted - will be ready in 30 minutes	ORD1755435892960	CASH_ON_DELIVERY	PENDING	DELIVERED	25999.00	1299.95	27348.95	2025-08-17 13:57:16.197359	superadmin	15	16
\.


--
-- Data for Name: partner_availability; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.partner_availability (id, created_at, day_of_week, end_time, is_available, is_special_schedule, specific_date, start_time, updated_at, partner_id) FROM stdin;
\.


--
-- Data for Name: partner_earnings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.partner_earnings (id, base_amount, bonus_amount, created_at, distance_covered, earning_date, incentive_amount, payment_date, payment_method, payment_reference, payment_status, penalty_amount, surge_multiplier, time_taken, total_amount, updated_at, partner_id, assignment_id) FROM stdin;
1	40.00	0.00	2025-08-17 13:50:46.549115	\N	2025-08-17	0.00	\N	\N	\N	PROCESSED	0.00	1.00	\N	40.00	2025-08-17 13:57:16.193261	1	1
\.


--
-- Data for Name: partner_zone_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.partner_zone_assignments (id, created_at, priority, partner_id, zone_id) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (id, created_at, email, expiry_date, token, used, username) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, action_type, active, category, created_at, created_by, description, name, resource_type, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_categories (id, created_at, created_by, description, icon_url, is_active, name, slug, sort_order, updated_at, updated_by, parent_id) FROM stdin;
1	2025-08-17 15:21:10.378334	admin	Electronic devices and accessories	\N	t	Electronics	electronics	1	2025-08-17 15:21:10.378334	\N	\N
2	2025-08-17 15:21:10.378334	admin	Apparel and fashion items	\N	t	Clothing	clothing	2	2025-08-17 15:21:10.378334	\N	\N
3	2025-08-17 15:21:10.378334	admin	Food items and drinks	\N	t	Food & Beverages	food-beverages	3	2025-08-17 15:21:10.378334	\N	\N
4	2025-08-17 15:21:10.378334	admin	Home improvement and gardening items	\N	t	Home & Garden	home-garden	4	2025-08-17 15:21:10.378334	\N	\N
5	2025-08-17 15:21:10.378334	admin	Books and educational materials	\N	t	Books	books	5	2025-08-17 15:21:10.378334	\N	\N
\.


--
-- Data for Name: promotions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.promotions (id, banner_url, code, created_at, created_by, description, discount_value, end_date, image_url, is_first_time_only, is_public, maximum_discount_amount, minimum_order_amount, shop_id, stackable, start_date, status, target_audience, terms_and_conditions, title, type, updated_at, updated_by, usage_limit, usage_limit_per_customer, used_count) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (id, category, created_at, created_by, default_value, description, display_order, is_active, is_read_only, is_required, scope, setting_key, setting_type, setting_value, shop_id, updated_at, updated_by, user_id, validation_rules) FROM stdin;
\.


--
-- Data for Name: shop_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shop_documents (id, created_at, document_name, document_type, file_path, file_size, file_type, is_required, original_filename, updated_at, verification_notes, verification_status, verified_at, verified_by, shop_id) FROM stdin;
\.


--
-- Data for Name: shop_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shop_images (id, created_at, image_type, image_url, is_primary, shop_id) FROM stdin;
\.


--
-- Data for Name: shop_product_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shop_product_images (id, alt_text, created_at, created_by, image_url, is_primary, sort_order, shop_product_id) FROM stdin;
\.


--
-- Data for Name: shop_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shop_products (id, cost_price, created_at, created_by, custom_attributes, custom_description, custom_name, display_order, is_available, is_featured, max_stock_level, min_stock_level, original_price, price, status, stock_quantity, tags, track_inventory, updated_at, updated_by, master_product_id, shop_id) FROM stdin;
11	\N	2025-08-17 10:53:05.520058	superadmin	\N	\N	\N	\N	t	f	\N	\N	\N	75000.00	ACTIVE	10	\N	t	2025-08-17 10:53:05.520058	superadmin	1	11
12	\N	2025-08-17 10:53:24.123797	superadmin	\N	\N	\N	\N	t	f	\N	\N	\N	85000.00	ACTIVE	5	\N	t	2025-08-17 10:53:24.123797	superadmin	4	11
17	\N	2025-08-17 13:02:36.621149	superadmin	\N	\N	\N	\N	t	f	100	5	\N	25999.00	ACTIVE	50	\N	t	2025-08-17 13:02:36.621149	superadmin	1	16
18	\N	2025-08-17 13:03:35.289738	superadmin	\N	\N	\N	\N	t	f	\N	\N	\N	1999.00	ACTIVE	100	\N	t	2025-08-17 13:03:35.289738	superadmin	2	16
\.


--
-- Data for Name: shops; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.shops (id, address_line1, business_name, business_type, city, commission_rate, country, created_at, created_by, delivery_fee, delivery_radius, description, free_delivery_above, gst_number, is_active, is_featured, is_verified, latitude, longitude, min_order_amount, name, owner_email, owner_name, owner_phone, pan_number, postal_code, product_count, rating, shop_id, slug, state, status, total_orders, total_revenue, updated_at, updated_by) FROM stdin;
16	123 Tech Street, Electronics Complex	TechMart Electronics Pvt Ltd	GENERAL	Bangalore	5.00	India	2025-08-17 12:58:40.48703	superadmin	50.00	25.00	Premium electronics and gadgets store	1500.00	\N	t	f	t	12.971600	77.594600	500.00	TechMart Electronics	thiruna2394@gmail.com	Thiruna Kumar	9876543210	\N	560001	2	0.00	SH8F3668AF	techmart-electronics-bangalore	Karnataka	APPROVED	0	0.00	2025-08-17 13:03:35.299345	superadmin
11	123 Tech Street, Electronics Market	TechStore Electronics	GENERAL	Bangalore	5.00	India	2025-08-17 10:51:14.939967	superadmin	30.00	10.00	Electronic items and gadgets store	500.00	\N	t	f	t	12.971600	77.594600	100.00	TechStore	owner@techstore.com	Rajesh Kumar	9876543210	\N	560001	2	0.00	SH8B55D708	techstore-bangalore	Karnataka	APPROVED	0	0.00	2025-08-17 17:21:07.297896	superadmin
\.


--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_permissions (user_id, permission_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, account_locked_until, created_at, created_by, department, designation, email, email_verified, failed_login_attempts, first_name, is_active, is_temporary_password, last_login, last_name, last_password_change, mobile_number, mobile_verified, password, password_change_required, profile_image_url, reports_to, role, status, two_factor_enabled, updated_at, updated_by, username) FROM stdin;
54	\N	2025-08-17 16:02:14.435036	\N	\N	\N	shopowner@shopmanagement.com	\N	\N	Shop	t	\N	\N	Owner	\N	\N	\N	$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy	\N	\N	\N	SHOP_OWNER	ACTIVE	\N	2025-08-17 16:02:14.435036	\N	shopowner
55	\N	2025-08-17 16:02:14.47403	\N	\N	\N	user@shopmanagement.com	\N	\N	Regular	t	\N	\N	User	\N	\N	\N	$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy	\N	\N	\N	USER	ACTIVE	\N	2025-08-17 16:02:14.47403	\N	user
56	\N	2025-08-17 16:30:13.565668	system	\N	\N	john.doe@customer.com	t	0	John	t	f	\N	Doe	\N	\N	t	$2a$10$NqqgFA82ohQl2XsW0Jf.fOsO804cwYkUUWNOILzZ4miDaqtI0cCO2	f	\N	\N	USER	ACTIVE	f	2025-08-17 16:30:13.565668	system	customer1
131	\N	2025-08-18 01:18:11.665391	\N	\N	\N	admin@shopmanagement.com	t	\N	Admin	t	\N	\N	User	\N	\N	\N	$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy	\N	\N	\N	ADMIN	ACTIVE	\N	2025-08-18 11:54:16.793969	\N	admin
49	\N	2025-08-17 15:58:00.755381	system	\N	\N	owner1@electronics.com	t	0	Rajesh	t	f	\N	Kumar	\N	\N	t	$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6	f	\N	\N	SHOP_OWNER	ACTIVE	f	2025-08-17 15:58:00.755381	system	shopowner1
50	\N	2025-08-17 15:58:00.755381	system	\N	\N	raj.kumar@delivery.com	t	0	Raj	t	f	\N	Kumar	\N	\N	t	\\a\\0\\/C4.WQ5FHC5yNEVJ/6	f	\N	\N	DELIVERY_PARTNER	ACTIVE	f	2025-08-17 15:58:00.755381	system	delivery1
51	\N	2025-08-17 15:58:00.755381	system	\N	\N	user1@example.com	t	0	Regular	t	f	\N	User	\N	\N	t	\\a\\0\\/C4.WQ5FHC5yNEVJ/6	f	\N	\N	USER	ACTIVE	f	2025-08-17 15:58:00.755381	system	user1
69	\N	2025-08-17 12:59:25.50435	\N	\N	\N	thiruna2394@gmail.com	f	0	\N	t	t	\N	\N	\N	\N	f	$2a$10$a2XNFPo.ZZa3dKAoIQJKSeOj2/qRxWFkciR81pEYC14vf.IEZVBJ6	t	\N	\N	SHOP_OWNER	ACTIVE	f	2025-08-17 12:59:25.50435	\N	thirunakum100
90	\N	2025-08-17 13:36:31.656076	\N	\N	\N	helec60392@jobzyy.com	f	0	Ravi	t	f	\N	Kumar	\N	9876543210	f	$2a$10$YslF08ioyJ8TGyMjwNX7i.VWzqK/vh1M5Ohrq2QChRaJthJ/nL/Dm	f	\N	\N	DELIVERY_PARTNER	ACTIVE	f	2025-08-17 13:36:31.656076	\N	helec60392
92	\N	2025-08-17 19:09:34.414105	\N	\N	\N	thoruncse75@gmail.com	t	\N	Test	t	\N	\N	Admin	\N	\N	\N	\\a\\0\\.qGNr7b5R2BaFwBxOwLwCBdBgBQAMEoGBWZe7hAWlP2vhNvW	\N	\N	\N	ADMIN	ACTIVE	\N	2025-08-17 19:09:34.414105	\N	testadmin
129	\N	2025-08-17 17:21:01.794114	\N	\N	\N	owner@techstore.com	f	0	\N	t	t	\N	\N	\N	\N	f	$2a$10$91OCFNZ4vrGcUKiZ57BLfOBoGHYS.JsaQoEdmikc4klf7eSiJUCV2	t	\N	\N	SHOP_OWNER	ACTIVE	f	2025-08-17 17:21:01.794114	\N	rajeshkuma71
48	\N	2025-08-17 15:58:00.755381	system	\N	\N	admin1@shopmanagement.com	t	0	Admin	t	f	\N	One	\N	\N	t	\\a\\0\\2IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	f	\N	\N	ADMIN	ACTIVE	f	2025-08-17 15:58:00.755381	system	admin1
52	\N	2025-08-17 10:29:49.859779	\N	\N	\N	test@test.com	f	0	\N	t	f	\N	\N	\N	\N	f	\\a\\0\\/zo88UkrvQXSi6OQ.fLV4LUJXsLUBvG	f	\N	\N	SUPER_ADMIN	ACTIVE	f	2025-08-17 10:29:49.859779	\N	testuser
47	\N	2025-08-17 15:58:00.755381	system	\N	\N	superadmin@shopmanagement.com	t	0	Super	t	f	\N	Admin	\N	\N	t	\\a\\0\\/C4.WQ5FHC5yNEVJ/6	f	\N	\N	SUPER_ADMIN	ACTIVE	f	2025-08-17 15:58:00.755381	system	superadmin
133	\N	2025-08-17 19:53:10.057504	\N	\N	\N	test@work.com	f	0	\N	t	f	\N	\N	\N	\N	f	$2a$10$.VYrpp5dug8maWYJrvOs2eSXpweQeH7QC0Y1uddPvZF5mOWImIxUW	f	\N	\N	SUPER_ADMIN	ACTIVE	f	2025-08-17 19:53:10.057504	\N	testwork
\.


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
-- Name: analytics analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics
    ADD CONSTRAINT analytics_pkey PRIMARY KEY (id);


--
-- Name: business_hours business_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT business_hours_pkey PRIMARY KEY (id);


--
-- Name: customer_addresses customer_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_addresses
    ADD CONSTRAINT customer_addresses_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: delivery_notifications delivery_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_notifications
    ADD CONSTRAINT delivery_notifications_pkey PRIMARY KEY (id);


--
-- Name: delivery_partner_documents delivery_partner_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partner_documents
    ADD CONSTRAINT delivery_partner_documents_pkey PRIMARY KEY (id);


--
-- Name: delivery_partners delivery_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT delivery_partners_pkey PRIMARY KEY (id);


--
-- Name: delivery_tracking delivery_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking
    ADD CONSTRAINT delivery_tracking_pkey PRIMARY KEY (id);


--
-- Name: delivery_zones delivery_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_zones
    ADD CONSTRAINT delivery_zones_pkey PRIMARY KEY (id);


--
-- Name: master_product_images master_product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_product_images
    ADD CONSTRAINT master_product_images_pkey PRIMARY KEY (id);


--
-- Name: master_products master_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_products
    ADD CONSTRAINT master_products_pkey PRIMARY KEY (id);


--
-- Name: mobile_otps mobile_otps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mobile_otps
    ADD CONSTRAINT mobile_otps_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: order_assignments order_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_assignments
    ADD CONSTRAINT order_assignments_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: partner_availability partner_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_availability
    ADD CONSTRAINT partner_availability_pkey PRIMARY KEY (id);


--
-- Name: partner_earnings partner_earnings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_earnings
    ADD CONSTRAINT partner_earnings_pkey PRIMARY KEY (id);


--
-- Name: partner_zone_assignments partner_zone_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_zone_assignments
    ADD CONSTRAINT partner_zone_assignments_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: promotions promotions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT promotions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: shop_documents shop_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_documents
    ADD CONSTRAINT shop_documents_pkey PRIMARY KEY (id);


--
-- Name: shop_images shop_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_images
    ADD CONSTRAINT shop_images_pkey PRIMARY KEY (id);


--
-- Name: shop_product_images shop_product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_product_images
    ADD CONSTRAINT shop_product_images_pkey PRIMARY KEY (id);


--
-- Name: shop_products shop_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_products
    ADD CONSTRAINT shop_products_pkey PRIMARY KEY (id);


--
-- Name: shops shops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shops
    ADD CONSTRAINT shops_pkey PRIMARY KEY (id);


--
-- Name: shops uk_1bphyyyptl7w9fp69a04krtfr; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shops
    ADD CONSTRAINT uk_1bphyyyptl7w9fp69a04krtfr UNIQUE (slug);


--
-- Name: master_products uk_4mr2q9tc8gyymy9pind6uwg8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_products
    ADD CONSTRAINT uk_4mr2q9tc8gyymy9pind6uwg8 UNIQUE (sku);


--
-- Name: customers uk_64j2dn17ycwlgr3pttpwna8dw; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT uk_64j2dn17ycwlgr3pttpwna8dw UNIQUE (mobile_number);


--
-- Name: users uk_6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: delivery_partners uk_6g7q05u4yobrlorexltrna8lo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_6g7q05u4yobrlorexltrna8lo UNIQUE (license_number);


--
-- Name: product_categories uk_6h198ar0xronfoxlvnq7lsfc0; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT uk_6h198ar0xronfoxlvnq7lsfc0 UNIQUE (slug);


--
-- Name: password_reset_tokens uk_71lqwbwtklmljk3qlsugr1mig; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT uk_71lqwbwtklmljk3qlsugr1mig UNIQUE (token);


--
-- Name: partner_earnings uk_7d6l5noljbn8ov36otv5l1qhl; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_earnings
    ADD CONSTRAINT uk_7d6l5noljbn8ov36otv5l1qhl UNIQUE (assignment_id);


--
-- Name: delivery_zones uk_a8t0mt2lteswps27jw2iy1a2f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_zones
    ADD CONSTRAINT uk_a8t0mt2lteswps27jw2iy1a2f UNIQUE (zone_code);


--
-- Name: delivery_partners uk_fs4vedfwfxn8knki0ayxx2whn; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_fs4vedfwfxn8knki0ayxx2whn UNIQUE (vehicle_number);


--
-- Name: delivery_partners uk_glmaox582sjhei4vhpgf276f1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_glmaox582sjhei4vhpgf276f1 UNIQUE (partner_id);


--
-- Name: delivery_partners uk_jdebkmarjpm1ff5524i002a3w; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_jdebkmarjpm1ff5524i002a3w UNIQUE (email);


--
-- Name: promotions uk_jdho73ymbyu46p2hh562dk4kk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.promotions
    ADD CONSTRAINT uk_jdho73ymbyu46p2hh562dk4kk UNIQUE (code);


--
-- Name: delivery_partners uk_jk6qr1r0gd9ih7jknmkk8k6up; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_jk6qr1r0gd9ih7jknmkk8k6up UNIQUE (user_id);


--
-- Name: orders uk_nthkiu7pgmnqnu86i2jyoe2v7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT uk_nthkiu7pgmnqnu86i2jyoe2v7 UNIQUE (order_number);


--
-- Name: permissions uk_pnvtwliis6p05pn6i3ndjrqt2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT uk_pnvtwliis6p05pn6i3ndjrqt2 UNIQUE (name);


--
-- Name: users uk_r43af9ap4edm43mmtq01oddj6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk_r43af9ap4edm43mmtq01oddj6 UNIQUE (username);


--
-- Name: customers uk_rfbvkrffamfql7cjmen8v976v; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT uk_rfbvkrffamfql7cjmen8v976v UNIQUE (email);


--
-- Name: delivery_partners uk_rv2gnx8yoe0qh1meq1q915v57; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT uk_rv2gnx8yoe0qh1meq1q915v57 UNIQUE (phone_number);


--
-- Name: settings uk_swd05dvj4ukvw5q135bpbbfae; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT uk_swd05dvj4ukvw5q135bpbbfae UNIQUE (setting_key);


--
-- Name: shops uk_tjd5rnobjcgkwuyd6e46iwloq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shops
    ADD CONSTRAINT uk_tjd5rnobjcgkwuyd6e46iwloq UNIQUE (shop_id);


--
-- Name: shop_products ukpdptnfm1m4psscn4692ttseag; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_products
    ADD CONSTRAINT ukpdptnfm1m4psscn4692ttseag UNIQUE (shop_id, master_product_id);


--
-- Name: user_permissions user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (user_id, permission_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: shop_products fk16al3qn4hmw6o1ng4cmm5hstr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_products
    ADD CONSTRAINT fk16al3qn4hmw6o1ng4cmm5hstr FOREIGN KEY (master_product_id) REFERENCES public.master_products(id);


--
-- Name: orders fk21gttsw5evi5bbsvleui69d7r; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fk21gttsw5evi5bbsvleui69d7r FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: partner_availability fk42usw5lk35uby2tk449x7mnmy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_availability
    ADD CONSTRAINT fk42usw5lk35uby2tk449x7mnmy FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: order_assignments fk4t2ugkwpkt2wtb1rhheese2wy; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_assignments
    ADD CONSTRAINT fk4t2ugkwpkt2wtb1rhheese2wy FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: partner_zone_assignments fk50fi21ce02cuvtttbil4kq5hi; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_zone_assignments
    ADD CONSTRAINT fk50fi21ce02cuvtttbil4kq5hi FOREIGN KEY (zone_id) REFERENCES public.delivery_zones(id);


--
-- Name: delivery_partner_documents fk5sy8o681csuqchuswoxjqndfu; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partner_documents
    ADD CONSTRAINT fk5sy8o681csuqchuswoxjqndfu FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: master_product_images fk5vuvgiy2j8qsefraeyuyiugmt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_product_images
    ADD CONSTRAINT fk5vuvgiy2j8qsefraeyuyiugmt FOREIGN KEY (master_product_id) REFERENCES public.master_products(id);


--
-- Name: master_products fk62mmtbcgjxtdhsm5w0r20sa6y; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master_products
    ADD CONSTRAINT fk62mmtbcgjxtdhsm5w0r20sa6y FOREIGN KEY (category_id) REFERENCES public.product_categories(id);


--
-- Name: delivery_partner_documents fk69je6xvgg7ppwg2w1u3r8f5gd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partner_documents
    ADD CONSTRAINT fk69je6xvgg7ppwg2w1u3r8f5gd FOREIGN KEY (verified_by) REFERENCES public.users(id);


--
-- Name: delivery_partners fk6rwo25nsq7y9mm5vumhdc0l14; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_partners
    ADD CONSTRAINT fk6rwo25nsq7y9mm5vumhdc0l14 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shop_product_images fkbci6qq1h2uxhuyi04ymt4e0x; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_product_images
    ADD CONSTRAINT fkbci6qq1h2uxhuyi04ymt4e0x FOREIGN KEY (shop_product_id) REFERENCES public.shop_products(id);


--
-- Name: order_items fkbioxgbv59vetrxe0ejfubep1w; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fkbioxgbv59vetrxe0ejfubep1w FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: partner_earnings fke227lnikm12hr64gt014dtkmf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_earnings
    ADD CONSTRAINT fke227lnikm12hr64gt014dtkmf FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: delivery_notifications fkfox4c5s5tdsbrcan3r48d0aso; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_notifications
    ADD CONSTRAINT fkfox4c5s5tdsbrcan3r48d0aso FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: order_assignments fkhhu5nv7c14yxx28s4fotonkkk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_assignments
    ADD CONSTRAINT fkhhu5nv7c14yxx28s4fotonkkk FOREIGN KEY (order_id) REFERENCES public.orders(id);


--
-- Name: shop_images fkhklkimv3eu30fw1v56wp65kjx; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_images
    ADD CONSTRAINT fkhklkimv3eu30fw1v56wp65kjx FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: delivery_tracking fkiohrk3dcvm8yv2fg7n5n9k8op; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_tracking
    ADD CONSTRAINT fkiohrk3dcvm8yv2fg7n5n9k8op FOREIGN KEY (assignment_id) REFERENCES public.order_assignments(id);


--
-- Name: partner_zone_assignments fkj60otyd801xr8iuje7w8vlxdm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_zone_assignments
    ADD CONSTRAINT fkj60otyd801xr8iuje7w8vlxdm FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: shop_documents fkk8vq7f7n71qyuurdtktbjhs15; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_documents
    ADD CONSTRAINT fkk8vq7f7n71qyuurdtktbjhs15 FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: user_permissions fkkowxl8b2bngrxd1gafh13005u; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT fkkowxl8b2bngrxd1gafh13005u FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: delivery_notifications fkm7korrnvea8dheirstr3isnwt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_notifications
    ADD CONSTRAINT fkm7korrnvea8dheirstr3isnwt FOREIGN KEY (partner_id) REFERENCES public.delivery_partners(id);


--
-- Name: order_items fkmmjb9o26o9rw4ihdtirha3ex7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT fkmmjb9o26o9rw4ihdtirha3ex7 FOREIGN KEY (shop_product_id) REFERENCES public.shop_products(id);


--
-- Name: product_categories fknhstaep8s818kydkq4teq8v4e; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT fknhstaep8s818kydkq4teq8v4e FOREIGN KEY (parent_id) REFERENCES public.product_categories(id);


--
-- Name: order_assignments fknk4qg6khhmtb1kut6jphhpi8i; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_assignments
    ADD CONSTRAINT fknk4qg6khhmtb1kut6jphhpi8i FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: partner_earnings fkos7pnggl450adufc45npil5lc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_earnings
    ADD CONSTRAINT fkos7pnggl450adufc45npil5lc FOREIGN KEY (assignment_id) REFERENCES public.order_assignments(id);


--
-- Name: delivery_notifications fkpwjynkwc6ikmd23ywci3v0842; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delivery_notifications
    ADD CONSTRAINT fkpwjynkwc6ikmd23ywci3v0842 FOREIGN KEY (assignment_id) REFERENCES public.order_assignments(id);


--
-- Name: orders fkpxtb8awmi0dk6smoh2vp1litg; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT fkpxtb8awmi0dk6smoh2vp1litg FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: user_permissions fkq4qlrabt4s0etm9tfkoqfuib1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT fkq4qlrabt4s0etm9tfkoqfuib1 FOREIGN KEY (permission_id) REFERENCES public.permissions(id);


--
-- Name: shop_products fkr4w3pq6v1oqxkfhyhgr4ngn68; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.shop_products
    ADD CONSTRAINT fkr4w3pq6v1oqxkfhyhgr4ngn68 FOREIGN KEY (shop_id) REFERENCES public.shops(id);


--
-- Name: customer_addresses fkrvr6wl9gll7u98cda18smugp4; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_addresses
    ADD CONSTRAINT fkrvr6wl9gll7u98cda18smugp4 FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- PostgreSQL database dump complete
--

