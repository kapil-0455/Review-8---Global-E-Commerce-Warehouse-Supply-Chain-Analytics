-- copy command and data operations
-- Schema: public

-- BULK IMPORT PRODUCT CATALOGS
-- Step 1: Create raw staging table for the original CSV

CREATE TABLE ecommerce_raw
(
    customer_id VARCHAR(20),
    customer_first_name VARCHAR(100),
    customer_last_name VARCHAR(100),
    customer_email VARCHAR(200),
    customer_phone VARCHAR(50),
    customer_street VARCHAR(200),
    customer_city VARCHAR(100),
    customer_state VARCHAR(100),
    customer_postal_code VARCHAR(20),
    customer_country VARCHAR(100),
    customer_registration_date DATE,

    order_id VARCHAR(20),
    order_date DATE,
    order_status VARCHAR(30),
    order_currency VARCHAR(10),
    order_subtotal NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    discount_amount NUMERIC(14,2),
    order_total NUMERIC(14,2),

    order_item_id VARCHAR(20),
    product_id VARCHAR(20),
    sku VARCHAR(50),
    product_name VARCHAR(200),
    category_name VARCHAR(100),
    product_weight_kg NUMERIC(10,2),
    unit_price NUMERIC(14,2),
    quantity INTEGER,
    line_discount NUMERIC(14,2),
    line_total NUMERIC(14,2),

    supplier_id VARCHAR(20),
    supplier_name VARCHAR(200),
    supplier_country VARCHAR(100),
    supplier_rating NUMERIC(3,2),
    supplier_price NUMERIC(14,2),
    supplier_lead_time_days INTEGER,

    warehouse_id VARCHAR(20),
    warehouse_name VARCHAR(200),
    warehouse_city VARCHAR(100),
    warehouse_state VARCHAR(100),
    warehouse_country VARCHAR(100),
    warehouse_capacity INTEGER,

    inventory_quantity_available INTEGER,
    inventory_quantity_reserved INTEGER,
    reorder_level INTEGER,

    payment_id VARCHAR(20),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    payment_transaction_reference VARCHAR(100),
    payment_date DATE,

    shipment_id VARCHAR(20),
    tracking_number VARCHAR(100),
    logistics_provider_id VARCHAR(20),
    logistics_provider_name VARCHAR(200),
    shipment_status VARCHAR(50),
    dispatch_date DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,

    tracking_location VARCHAR(200),
    tracking_event_time TIMESTAMP,

    return_id VARCHAR(20),
    return_status VARCHAR(50),
    return_reason VARCHAR(200),
    return_quantity NUMERIC(10,2),
    return_item_condition VARCHAR(50),
    refund_amount NUMERIC(14,2),

    price_country VARCHAR(100),
    dynamic_price NUMERIC(14,2),
    price_effective_from DATE,

    inventory_transaction_type VARCHAR(50),
    inventory_transaction_quantity INTEGER,
    inventory_transaction_date DATE
);

-- Step 2: Bulk import the original CSV

COPY ecommerce_raw
FROM 'C:\Users\Public\global_ecommerce_denormalized.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Step 3: Verify raw data

SELECT COUNT(*) AS total_records
FROM ecommerce_raw;


-- Step 4: Create product catalog import table

CREATE TABLE product_catalog_import
(
    product_id VARCHAR(20),
    sku VARCHAR(50),
    product_name VARCHAR(200),
    category_name VARCHAR(100),
    product_weight_kg NUMERIC(10,2)
);

-- Step 5: Extract product catalog from raw data

INSERT INTO product_catalog_import
(
    product_id,
    sku,
    product_name,
    category_name,
    product_weight_kg
)
SELECT DISTINCT
    product_id,
    sku,
    product_name,
    category_name,
    product_weight_kg
FROM ecommerce_raw
WHERE product_id IS NOT NULL;


-- Step 6: Verify product catalog

SELECT *
FROM product_catalog_import
LIMIT 10;


SELECT COUNT(*) AS imported_products
FROM product_catalog_import;

-- export financial summaries
-- Step 1: Create financial summary table

CREATE TABLE financial_summary
(
    order_date DATE,
    order_count BIGINT,
    subtotal NUMERIC(14,2),
    tax_amount NUMERIC(14,2),
    shipping_cost NUMERIC(14,2),
    discount_amount NUMERIC(14,2),
    total_revenue NUMERIC(14,2)
);

-- Step 2: Generate financial summary

INSERT INTO financial_summary
(
    order_date,
    order_count,
    subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    total_revenue
)
SELECT
    order_date,
    COUNT(*) AS order_count,
    SUM(subtotal) AS subtotal,
    SUM(tax_amount) AS tax_amount,
    SUM(shipping_cost) AS shipping_cost,
    SUM(discount_amount) AS discount_amount,
    SUM(total_amount) AS total_revenue
FROM orders
GROUP BY order_date
ORDER BY order_date;

-- Step 3: Verify financial summary

SELECT *
FROM financial_summary
ORDER BY order_date;

-- Step 4: Export financial summary to CSV

COPY financial_summary
TO 'C:\Users\Public\financial_summary.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- import logistics tracking data
-- Step 1: Create logistics tracking staging table

CREATE TABLE logistics_tracking_import
(
    shipment_id VARCHAR(20),
    location VARCHAR(200),
    event_time TIMESTAMP
);

-- Step 2: Extract logistics tracking data from the original imported CSV data

INSERT INTO logistics_tracking_import
(
    shipment_id,
    location,
    event_time
)
SELECT DISTINCT
    shipment_id,
    tracking_location,
    tracking_event_time
FROM ecommerce_raw
WHERE shipment_id IS NOT NULL
  AND tracking_location IS NOT NULL
  AND tracking_event_time IS NOT NULL;

-- Step 3: Verify imported logistics data

SELECT *
FROM logistics_tracking_import
LIMIT 10;


SELECT COUNT(*) AS imported_tracking_records
FROM logistics_tracking_import;

-- Step 4: Insert valid tracking records into the normalized shipment_tracking table

INSERT INTO shipment_tracking
(
    shipment_id,
    location,
    event_time
)
SELECT
    l.shipment_id,
    l.location,
    l.event_time
FROM logistics_tracking_import l
WHERE EXISTS
(
    SELECT 1
    FROM shipments s
    WHERE s.shipment_id = l.shipment_id
);

-- Step 5: Verify final shipment tracking data

SELECT *
FROM shipment_tracking
LIMIT 10;


SELECT COUNT(*) AS total_tracking_records
FROM shipment_tracking;