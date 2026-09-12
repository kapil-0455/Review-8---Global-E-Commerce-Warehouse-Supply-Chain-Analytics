--Create table customers to maintain normalisation till 3NF
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
FROM ecommerce_raw;

--Create data 
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
FROM ecommerce_raw;

-- CREATE table categories
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,

    category_name VARCHAR(100)
        UNIQUE NOT NULL
);
```

-- insert data in categories
INSERT INTO categories(category_name)
SELECT DISTINCT category_name
FROM ecommerce_raw;
