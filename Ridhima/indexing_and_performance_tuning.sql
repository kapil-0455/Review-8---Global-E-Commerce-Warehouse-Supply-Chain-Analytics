-- Indexing and Performance Tuning
-- Queries that can benefit from indexes

-- Q1: Product Search
SELECT product_id, sku, product_name
FROM products
WHERE product_name = 'Laptop 1';

EXPLAIN
SELECT product_id, sku, product_name
FROM products
WHERE product_name = 'Laptop 1';

EXPLAIN ANALYZE
SELECT product_id, sku, product_name
FROM products
WHERE product_name = 'Laptop 1';

-- Q2: Shipment Tracking
SELECT shipment_id, location, event_time
FROM shipment_tracking
WHERE shipment_id = 'SHP000100'
ORDER BY event_time DESC;

EXPLAIN
SELECT shipment_id, location, event_time
FROM shipment_tracking
WHERE shipment_id = 'SHP000100'
ORDER BY event_time DESC;

EXPLAIN ANALYZE
SELECT shipment_id, location, event_time
FROM shipment_tracking
WHERE shipment_id = 'SHP000100'
ORDER BY event_time DESC;

-- Q3: Warehouse Inventory
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001';

EXPLAIN
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001';

EXPLAIN ANALYZE
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001';

-- Q4: Specific Product in Warehouse
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001'
AND product_id = 'PROD00010';

EXPLAIN
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001'
AND product_id = 'PROD00010';

EXPLAIN ANALYZE
SELECT product_id, quantity_available, quantity_reserved
FROM inventory
WHERE warehouse_id = 'WH001'
AND product_id = 'PROD00010';

-- Q5: Active Shipments
SELECT shipment_id, tracking_number, shipment_status, expected_delivery_date
FROM shipments
WHERE shipment_status IN
(
    'CREATED',
    'DISPATCHED',
    'IN_TRANSIT',
    'OUT_FOR_DELIVERY',
    'DELAYED'
);

EXPLAIN
SELECT shipment_id,
       tracking_number,
       shipment_status,
       expected_delivery_date
FROM shipments
WHERE shipment_status IN
(
    'CREATED',
    'DISPATCHED',
    'IN_TRANSIT',
    'OUT_FOR_DELIVERY',
    'DELAYED'
);

EXPLAIN ANALYZE
SELECT shipment_id,
       tracking_number,
       shipment_status,
       expected_delivery_date
FROM shipments
WHERE shipment_status IN
(
    'CREATED',
    'DISPATCHED',
    'IN_TRANSIT',
    'OUT_FOR_DELIVERY',
    'DELAYED'
);

-- Product search index
CREATE INDEX idx_products_product_name
ON products(product_name);

-- Composite index for shipment tracking
CREATE INDEX idx_tracking_shipment_event_time
ON shipment_tracking
(
    shipment_id,
    event_time DESC
);

-- Warehouse inventory index
CREATE INDEX idx_inventory_warehouse
ON inventory(warehouse_id);

-- Composite warehouse + product index
CREATE INDEX idx_inventory_warehouse_product
ON inventory
(
    warehouse_id,
    product_id
);

-- Partial index for active shipments
CREATE INDEX idx_shipments_active
ON shipments
(
    shipment_status,
    expected_delivery_date
)
WHERE shipment_status IN
(
    'CREATED',
    'DISPATCHED',
    'IN_TRANSIT',
    'OUT_FOR_DELIVERY',
    'DELAYED'
);

-- VERIFY INDEXES

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
ORDER BY tablename, indexname;

-- checking index usage

SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS times_used
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- performance comparison table

CREATE TABLE index_comparison
(
    comparison_id SERIAL PRIMARY KEY,
    query_name VARCHAR(100),
    indexed_column VARCHAR(100),
    before_plan TEXT,
    after_plan TEXT,
    before_time NUMERIC(12,3),
    after_time NUMERIC(12,3),
    improved VARCHAR(10),
    remarks TEXT
);

SELECT *
FROM index_comparison
ORDER BY comparison_id;

INSERT INTO index_comparison
(
    query_name,
    indexed_column,
    before_plan,
    after_plan,
    before_time,
    after_time,
    improved,
    remarks
)
VALUES
(
    'Q1 Product Search',
    'product_name',
    'Seq Scan',
    'Seq Scan',
    0.091,
    0.076,
    'YES',
    'Execution time decreased, but PostgreSQL continued to use a sequential scan because the products table is small.'
),

(
    'Q2 Shipment Tracking',
    'shipment_id, event_time',
    'Seq Scan + Sort',
    'Bitmap Index Scan + Bitmap Heap Scan + Sort',
    1.248,
    0.142,
    'YES',
    'Composite index was used for shipment filtering and significantly reduced execution time.'
),

(
    'Q3 Warehouse Inventory',
    'warehouse_id',
    'Seq Scan',
    'Index Scan',
    0.233,
    0.133,
    'YES',
    'Warehouse index was used and execution time decreased.'
),

(
    'Q4 Warehouse Product',
    'warehouse_id, product_id',
    'Seq Scan',
    'Index Scan',
    0.115,
    0.095,
    'YES',
    'Composite index was used for warehouse and product filtering and improved execution time.'
),

(
    'Q5 Active Shipments',
    'shipment_status, expected_delivery_date',
    'Seq Scan',
    'Seq Scan',
    1.1691,
    1.393,
    'NO',
    'Partial index was not selected by the optimizer; the sequential scan was faster for this query and dataset.'
);


SELECT
    comparison_id,
    query_name,
    indexed_column,
    before_plan,
    after_plan,
    before_time,
    after_time,
    improved,
    remarks
FROM index_comparison
ORDER BY comparison_id;