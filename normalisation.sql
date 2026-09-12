--Create table customers to maintain normalisation till 3NF

select count(*) from global_raw
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(30),
    registration_date DATE NOT NULL,

    CONSTRAINT chk_customer_email
        CHECK (email LIKE '%@%')
);

--Get data into customers
INSERT INTO customers
(
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    registration_date
)
SELECT DISTINCT
    customer_id,
    customer_first_name,
    customer_last_name,
    customer_email,
    customer_phone,
    customer_registration_date
FROM global_raw;

--Create table customer address
CREATE TABLE customer_addresses (
    address_id BIGSERIAL PRIMARY KEY,

    customer_id VARCHAR(20) NOT NULL,

    street VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,

    CONSTRAINT fk_address_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

--Insert into customer address
INSERT INTO customer_addresses
(
    customer_id,
    street,
    city,
    state,
    postal_code,
    country
)
SELECT DISTINCT
    customer_id,
    customer_street,
    customer_city,
    customer_state,
    customer_postal_code,
    customer_country
FROM global_raw;

-- CREATE table categories
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,

    category_name VARCHAR(100)
        UNIQUE NOT NULL
);

-- insert data in categories
INSERT INTO categories(category_name)
SELECT DISTINCT category_name
FROM global_raw;


-- Create table Products
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,

    sku VARCHAR(50)
        UNIQUE NOT NULL,

    product_name VARCHAR(200)
        NOT NULL,

    category_id INT NOT NULL,

    weight_kg NUMERIC(10,2),

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id),

    CONSTRAINT chk_product_weight
        CHECK (weight_kg >= 0)
);

-- insert data in products
INSERT INTO products
(
    product_id,
    sku,
    product_name,
    category_id,
    weight_kg
)
SELECT DISTINCT
    r.product_id,
    r.sku,
    r.product_name,
    c.category_id,
    r.product_weight_kg
FROM global_raw r
JOIN categories c
ON r.category_name = c.category_name;

-- create table Suppliers
CREATE TABLE suppliers (
    supplier_id VARCHAR(20) PRIMARY KEY,

    supplier_name VARCHAR(150)
        NOT NULL,

    country VARCHAR(100),

    rating NUMERIC(3,2),

    CONSTRAINT chk_supplier_rating
        CHECK (rating BETWEEN 0 AND 5)
);

-- Insert data in suppliers
INSERT INTO suppliers
SELECT DISTINCT
    supplier_id,
    supplier_name,
    supplier_country,
    supplier_rating
FROM global_raw;


-- CREATE TABLE Supplier Products

CREATE TABLE supplier_products (
    supplier_id VARCHAR(20),
    product_id VARCHAR(20),

    supplier_price NUMERIC(14,2) NOT NULL,

    lead_time_days INT,

    PRIMARY KEY (supplier_id, product_id),

    CONSTRAINT fk_sp_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_sp_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_supplier_price
        CHECK (supplier_price >= 0),

    CONSTRAINT chk_lead_time
        CHECK (lead_time_days >= 0)
);

-- insert data in supplier_products
INSERT INTO supplier_products
SELECT DISTINCT
    supplier_id,
    product_id,
    supplier_price,
    supplier_lead_time_days
FROM global_raw
ON CONFLICT (supplier_id, product_id) DO NOTHING;


--- create table warehouse
CREATE TABLE warehouses (
    warehouse_id VARCHAR(20) PRIMARY KEY,

    warehouse_name VARCHAR(150)
        NOT NULL,

    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),

    capacity INT NOT NULL,

    CONSTRAINT chk_warehouse_capacity
        CHECK (capacity > 0)
);
-- insert data in warehouse
INSERT INTO warehouses
SELECT DISTINCT
    warehouse_id,
    warehouse_name,
    warehouse_city,
    warehouse_state,
    warehouse_country,
    warehouse_capacity
FROM global_raw;

--- table inventory

CREATE TABLE inventory (
    warehouse_id VARCHAR(20),
    product_id VARCHAR(20),

    quantity_available INT DEFAULT 0,
    quantity_reserved INT DEFAULT 0,
    reorder_level INT DEFAULT 10,

    PRIMARY KEY (warehouse_id, product_id),

    CONSTRAINT fk_inventory_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_inventory_available
        CHECK (quantity_available >= 0),

    CONSTRAINT chk_inventory_reserved
        CHECK (quantity_reserved >= 0),

    CONSTRAINT chk_reorder_level
        CHECK (reorder_level >= 0),

    CONSTRAINT chk_reserved_stock
        CHECK (quantity_reserved <= quantity_available)
);
 -- insert data into inventory
INSERT INTO inventory
(
    warehouse_id,
    product_id,
    quantity_available,
    quantity_reserved,
    reorder_level
)
SELECT DISTINCT ON (warehouse_id, product_id)
    warehouse_id,
    product_id,
    inventory_quantity_available,
    inventory_quantity_reserved,
    reorder_level
FROM global_raw
ORDER BY warehouse_id, product_id
ON CONFLICT (warehouse_id, product_id) DO NOTHING;

-- create table orders
CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,

    customer_id VARCHAR(20) NOT NULL,

    order_date TIMESTAMP NOT NULL,

    order_status VARCHAR(30) NOT NULL,

    currency CHAR(3) NOT NULL,

    subtotal NUMERIC(14,2) DEFAULT 0,
    tax_amount NUMERIC(14,2) DEFAULT 0,
    shipping_cost NUMERIC(14,2) DEFAULT 0,
    discount_amount NUMERIC(14,2) DEFAULT 0,
    total_amount NUMERIC(14,2) NOT NULL,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT chk_order_status
        CHECK (
            order_status IN (
                'PENDING',
                'CONFIRMED',
                'PROCESSING',
                'SHIPPED',
                'DELIVERED',
                'CANCELLED',
                'RETURNED'
            )
        ),

    CONSTRAINT chk_order_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_tax
        CHECK (tax_amount >= 0),

    CONSTRAINT chk_shipping_cost
        CHECK (shipping_cost >= 0),

    CONSTRAINT chk_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_total_amount
        CHECK (total_amount >= 0)
);
-- insert into orders
INSERT INTO orders
SELECT DISTINCT
    order_id,
    customer_id,
    order_date,
    order_status,
    order_currency,
    order_subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    order_total
FROM global_raw;

select * from orders

-- create table  OrderItems
CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,

    order_id VARCHAR(20) NOT NULL,

    product_id VARCHAR(20) NOT NULL,

    quantity INT NOT NULL,

    unit_price NUMERIC(14,2) NOT NULL,

    discount NUMERIC(14,2) DEFAULT 0,

    line_total NUMERIC(14,2) NOT NULL,

    CONSTRAINT fk_item_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_item_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT chk_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_line_discount
        CHECK (discount >= 0),

    CONSTRAINT chk_line_total
        CHECK (line_total >= 0)
);
 -- order items data insert
INSERT INTO order_items
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    line_discount,
    line_total
FROM global_raw;

-- create table Payments
CREATE TABLE payments (
    payment_id VARCHAR(20) PRIMARY KEY,

    order_id VARCHAR(20) NOT NULL,

    payment_method VARCHAR(30),

    payment_status VARCHAR(30),

    transaction_reference VARCHAR(100)
        UNIQUE,

    payment_date TIMESTAMP,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_payment_method
        CHECK (
            payment_method IN (
                'CARD',
                'UPI',
                'PAYPAL',
                'BANK_TRANSFER',
                'COD'
            )
        ),

    CONSTRAINT chk_payment_status
        CHECK (
            payment_status IN (
                'PENDING',
                'SUCCESS',
                'FAILED',
                'REFUNDED'
            )
        )
);
 -- insert into payments
INSERT INTO payments
SELECT DISTINCT
    payment_id,
    order_id,
    payment_method,
    payment_status,
    payment_transaction_reference,
    payment_date
FROM global_raw;

-- create table  Logistics Providers

CREATE TABLE logistics_providers (
    logistics_provider_id VARCHAR(20) PRIMARY KEY,

    provider_name VARCHAR(100)
        UNIQUE NOT NULL
);

 -- insert data in 
INSERT INTO logistics_providers
SELECT DISTINCT
    logistics_provider_id,
    logistics_provider_name
FROM global_raw;

-- create table Shipments
CREATE TABLE shipments (
    shipment_id VARCHAR(20) PRIMARY KEY,

    order_id VARCHAR(20) NOT NULL,

    warehouse_id VARCHAR(20) NOT NULL,

    logistics_provider_id VARCHAR(20),

    tracking_number VARCHAR(100)
        UNIQUE NOT NULL,

    shipment_status VARCHAR(30),

    dispatch_date TIMESTAMP,

    expected_delivery_date TIMESTAMP,

    actual_delivery_date TIMESTAMP,

    CONSTRAINT fk_shipment_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT fk_shipment_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id),

    CONSTRAINT fk_shipment_provider
        FOREIGN KEY (logistics_provider_id)
        REFERENCES logistics_providers(logistics_provider_id),

    CONSTRAINT chk_shipment_status
        CHECK (
            shipment_status IN (
                'CREATED',
                'DISPATCHED',
                'IN_TRANSIT',
                'OUT_FOR_DELIVERY',
                'DELIVERED',
                'DELAYED',
                'LOST'
            )
        ),

    CONSTRAINT chk_expected_delivery
        CHECK (
            expected_delivery_date IS NULL
            OR dispatch_date IS NULL
            OR expected_delivery_date >= dispatch_date
        ),

    CONSTRAINT chk_actual_delivery
        CHECK (
            actual_delivery_date IS NULL
            OR dispatch_date IS NULL
            OR actual_delivery_date >= dispatch_date
        )
);
 -- insert into shipments
 
INSERT INTO shipments
SELECT DISTINCT
    shipment_id,
    order_id,
    warehouse_id,
    logistics_provider_id,
    tracking_number,
    shipment_status,
    dispatch_date,
    expected_delivery_date,
    actual_delivery_date
FROM global_raw;


-- Shipment Tracking

CREATE TABLE shipment_tracking (
    tracking_event_id BIGSERIAL PRIMARY KEY,

    shipment_id VARCHAR(20) NOT NULL,

    location VARCHAR(200),

    event_time TIMESTAMP NOT NULL,

    CONSTRAINT fk_tracking_shipment
        FOREIGN KEY (shipment_id)
        REFERENCES shipments(shipment_id)
        ON DELETE CASCADE
);


-- insert into shipment- tracking
INSERT INTO shipment_tracking
(
    shipment_id,
    location,
    event_time
)
SELECT DISTINCT
    shipment_id,
    tracking_location,
    tracking_event_time
FROM global_raw;

-- create into Return_Request
CREATE TABLE return_requests (
    return_id VARCHAR(20) PRIMARY KEY,

    order_id VARCHAR(20) NOT NULL,

    return_status VARCHAR(30),

    reason VARCHAR(200),

    refund_amount NUMERIC(14,2) DEFAULT 0,

    CONSTRAINT fk_return_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id),

    CONSTRAINT chk_return_status
        CHECK (
            return_status IN (
                'REQUESTED',
                'APPROVED',
                'REJECTED',
                'PICKED_UP',
                'RECEIVED',
                'REFUNDED'
            )
        ),

    CONSTRAINT chk_refund
        CHECK (refund_amount >= 0)
);
 -- insert into returns
INSERT INTO return_requests
SELECT DISTINCT
    return_id,
    order_id,
    return_status,
    return_reason,
    COALESCE(refund_amount,0)
FROM global_raw
WHERE return_id IS NOT NULL
AND return_id <> '';

-- create table  return_items
CREATE TABLE return_items (
    return_item_id BIGSERIAL PRIMARY KEY,

    return_id VARCHAR(20) NOT NULL,

    order_item_id VARCHAR(20) NOT NULL,

    quantity INT NOT NULL,

    item_condition VARCHAR(30),

    CONSTRAINT fk_return_item_request
        FOREIGN KEY (return_id)
        REFERENCES return_requests(return_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_return_item_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES order_items(order_item_id),

    CONSTRAINT chk_return_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_item_condition
        CHECK (
            item_condition IN (
                'UNOPENED',
                'GOOD',
                'DAMAGED',
                'DEFECTIVE'
            )
        )
);
 -- insert INTO return_items
INSERT INTO return_items
(
    return_id,
    order_item_id,
    quantity,
    item_condition
)
SELECT
    return_id,
    order_item_id,
    return_quantity,
    return_item_condition
FROM global_raw
WHERE return_id IS NOT NULL
AND return_id <> '';

-- create into Product Prices
CREATE TABLE product_prices (
    price_id BIGSERIAL PRIMARY KEY,

    product_id VARCHAR(20) NOT NULL,

    country VARCHAR(100) NOT NULL,

    price NUMERIC(14,2) NOT NULL,

    effective_from DATE NOT NULL,

    CONSTRAINT fk_price_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_dynamic_price
        CHECK (price >= 0)
);
 -- insert into product_prices
INSERT INTO product_prices
(
    product_id,
    country,
    price,
    effective_from
)
SELECT DISTINCT
    product_id,
    price_country,
    dynamic_price,
    price_effective_from
FROM global_raw;

-- CREATE TABLE inventory_transactions
CREATE TABLE inventory_transactions (
    inventory_transaction_id BIGSERIAL PRIMARY KEY,

    warehouse_id VARCHAR(20) NOT NULL,

    product_id VARCHAR(20) NOT NULL,

    transaction_type VARCHAR(30) NOT NULL,

    quantity INT NOT NULL,

    transaction_date TIMESTAMP NOT NULL,

    CONSTRAINT fk_transaction_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id),

    CONSTRAINT fk_transaction_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT chk_transaction_type
        CHECK (
            transaction_type IN (
                'PURCHASE',
                'SALE',
                'RETURN',
                'TRANSFER_IN',
                'TRANSFER_OUT',
                'ADJUSTMENT'
            )
        ),

    CONSTRAINT chk_transaction_quantity
        CHECK (quantity <> 0)
);
 -- insert into inventory_transactions
INSERT INTO inventory_transactions
(
    warehouse_id,
    product_id,
    transaction_type,
    quantity,
    transaction_date
)
SELECT
    warehouse_id,
    product_id,
    inventory_transaction_type,
    inventory_transaction_quantity,
    inventory_transaction_date
FROM global_raw;