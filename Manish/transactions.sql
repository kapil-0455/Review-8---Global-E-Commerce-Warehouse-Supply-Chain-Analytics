-- TRANSACTION 1: ORDER PLACEMENT

BEGIN;

SELECT warehouse_id, product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017'
FOR UPDATE;

-- Reserve 2 units for the new order.
UPDATE inventory
SET quantity_available = quantity_available - 2, quantity_reserved = quantity_reserved + 2
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017' AND quantity_available >= 2;

-- Create the order
INSERT INTO orders (order_id, customer_id, order_date, order_status, currency, subtotal, tax_amount, shipping_cost, discount_amount, total_amount)
VALUES ('TEST_ORD_001', 'CUST00120', CURRENT_TIMESTAMP, 'PENDING', 'AED', 10162.98, 508.15, 100.00, 0.00, 10771.13);

-- Add the ordered products
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price, discount, line_total)
VALUES ('TEST_ITEM_001', 'TEST_ORD_001', 'PROD00017', 2, 5081.49, 0.00, 10162.98);

-- Record the inventory movement
INSERT INTO inventory_transactions (warehouse_id, product_id, transaction_type, quantity, transaction_date)
VALUES ('WH008', 'PROD00017', 'SALE', -2, CURRENT_TIMESTAMP);

COMMIT;


-- TRANSACTION 2: PAYMENT CONFIRMATION

BEGIN;

SELECT payment_id, order_id, payment_status
FROM payments
WHERE payment_id = 'PAY000001'
FOR UPDATE;

UPDATE payments
SET payment_status = 'SUCCESS', payment_date = CURRENT_TIMESTAMP
WHERE payment_id = 'PAY000001' AND payment_status = 'PENDING';

-- Update the order after successful payment
UPDATE orders
SET order_status = 'CONFIRMED'
WHERE order_id = (SELECT order_id FROM payments WHERE payment_id = 'PAY000001');

COMMIT;


-- TRANSACTION 3: INVENTORY UPDATE

BEGIN;

SELECT warehouse_id, product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017'
FOR UPDATE;

UPDATE inventory
SET quantity_available = quantity_available - 1, quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017' AND quantity_available >= 1;

-- Record the inventory transaction
INSERT INTO inventory_transactions (warehouse_id, product_id, transaction_type, quantity, transaction_date)
VALUES ('WH008', 'PROD00017', 'SALE', -1, CURRENT_TIMESTAMP);

COMMIT;


-- TRANSACTION 4: REFUND PROCESSING

BEGIN;

SELECT return_id, order_id, return_status, refund_amount
FROM return_requests
WHERE return_id = 'TEST_RETURN_001'
FOR UPDATE;

UPDATE return_requests
SET return_status = 'REFUNDED', refund_amount = 5081.49
WHERE return_id = 'TEST_RETURN_001';

-- Mark the corresponding payment as refunded
UPDATE payments
SET payment_status = 'REFUNDED'
WHERE order_id = (SELECT order_id FROM return_requests WHERE return_id = 'TEST_RETURN_001');

-- Mark the order as returned
UPDATE orders
SET order_status = 'RETURNED'
WHERE order_id = (SELECT order_id FROM return_requests WHERE return_id = 'TEST_RETURN_001');

COMMIT;


-- TRANSACTION 5: ROLLBACK SIMULATION

BEGIN;

INSERT INTO orders (order_id, customer_id, order_date, order_status, currency, subtotal, tax_amount, shipping_cost, discount_amount, total_amount)
VALUES ('TEST_ROLLBACK_ORDER', 'CUST00120', CURRENT_TIMESTAMP, 'PENDING', 'AED', 5081.49, 254.07, 100.00, 0.00, 5435.56);

UPDATE inventory
SET quantity_available = quantity_available - 1, quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD017' AND quantity_available >= 1;

SELECT *
FROM orders
WHERE order_id = 'TEST_ROLLBACK_ORDER';

ROLLBACK;

-- Verification:
-- This should return zero rows because the order was rolled back
SELECT *
FROM orders
WHERE order_id = 'TEST_ROLLBACK_ORDER';


-- TRANSACTION 6: DEADLOCK SIMULATION

-- Run this first in Session A
BEGIN;

-- Session A locks inventory row for PROD00017
SELECT *
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017'
FOR UPDATE;

-- Keep this transaction open.

-- Run this in a second PostgreSQL session
BEGIN;

-- Session B locks another resource first
SELECT *
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00018'
FOR UPDATE;

-- Now Session A tries to lock PROD00018
-- It waits for Session B

-- Run in SESSION A:
UPDATE inventory
SET quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00018';

-- Now Session B tries to lock PROD00017
-- It waits for Session A

-- Run in SESSION B:
UPDATE inventory
SET quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017';

-- PostgreSQL detects the circular wait and reports:
-- ERROR: deadlock detected


-- TRANSACTION 7: CONCURRENT ORDER PROCESSING SIMULATION

-- Run in Session A.
BEGIN;

-- Lock the inventory row
SELECT warehouse_id, product_id, quantity_available
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017'
FOR UPDATE;

-- Reserve one unit
UPDATE inventory
SET quantity_available = quantity_available - 1, quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017' AND quantity_available >= 1;

-- Insert first concurrent order
INSERT INTO orders (order_id, customer_id, order_date, order_status, currency, subtotal, tax_amount, shipping_cost, discount_amount, total_amount)
VALUES ('TEST_CONCURRENT_A', 'CUST00120', CURRENT_TIMESTAMP, 'PENDING', 'AED', 5081.49, 254.07, 100.00, 0.00, 5435.56);

-- Do not commit immediately.
-- Leave Session A open so Session B has to wait.

-- Run in Session B while Session A is still open
BEGIN;

-- Session B attempts to lock the same inventory row
SELECT warehouse_id, product_id, quantity_available
FROM inventory
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017'
FOR UPDATE;

-- After Session A commits, Session B gets the latest inventory value
-- and can safely attempt its own reservation.

UPDATE inventory
SET quantity_available = quantity_available - 1, quantity_reserved = quantity_reserved + 1
WHERE warehouse_id = 'WH008' AND product_id = 'PROD00017' AND quantity_available >= 1;

-- Insert second concurrent order
INSERT INTO orders (order_id, customer_id, order_date, order_status, currency, subtotal, tax_amount, shipping_cost, discount_amount, total_amount)
VALUES ('TEST_CONCURRENT_B', 'CUST00120', CURRENT_TIMESTAMP, 'PENDING', 'AED', 5081.49, 254.07, 100.00, 0.00, 5435.56);

-- Commit Session B
COMMIT;

-- After Session B has demonstrated waiting, return to Session A
-- and commit it.
COMMIT;