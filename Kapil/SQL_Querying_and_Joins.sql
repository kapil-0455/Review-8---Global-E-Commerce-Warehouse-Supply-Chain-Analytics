-- SQL Querying & Joins

-- ===========================================================
-- Top-Selling Products 
-- ===========================================================


select
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    sum(oi.quantity) as total_units_sold,
    sum(oi.line_total) as total_revenue
from order_items oi
join products p
    on oi.product_id = p.product_id
join categories c
    on p.category_id = c.category_id
join orders o
    on oi.order_id = o.order_id
where o.order_status != 'CANCELLED'
group by
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name
order by total_units_sold desc
limit 10;

-- ===========================================================
-- Warehouse utilization 
-- ===========================================================

select
    w.warehouse_id,
    w.warehouse_name,
    w.capacity,
    sum(i.quantity_available) as total_inventory,
    round(
        sum(i.quantity_available) * 100.0 / w.capacity,
        2
    ) as utilization_percentage
from warehouses w
join inventory i
    on w.warehouse_id = i.warehouse_id
group by
    w.warehouse_id,
    w.warehouse_name,
    w.capacity
order by utilization_percentage desc;

-- ===========================================================
-- Vendor performance
-- ===========================================================
select
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.rating,
    count(distinct sp.product_id) as products_supplied,
    sum(oi.quantity) as units_sold,
    sum(oi.line_total) as sales_revenue,
    avg(sp.lead_time_days) as avg_lead_time
from suppliers s
join supplier_products sp
    on s.supplier_id = sp.supplier_id
join order_items oi
    on sp.product_id = oi.product_id
group by
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.rating
order by sales_revenue desc;

-- ===========================================================
-- Delivery delay analysis
-- ===========================================================

select
    s.shipment_id,
    s.tracking_number,
    o.order_id,
    s.dispatch_date,
    s.expected_delivery_date,
    s.actual_delivery_date,
    case
        when s.actual_delivery_date > s.expected_delivery_date
        then date(s.actual_delivery_date) - date(s.expected_delivery_date)
        else 0
    end as delay_days,
    s.shipment_status
from shipments s
join orders o
    on s.order_id = o.order_id
where s.actual_delivery_date is not null
order by delay_days desc;
	
-- ===========================================================
-- Customer purchase segmentation
-- ===========================================================
select
    c.customer_id,
    c.first_name,
    c.last_name,
    count(distinct o.order_id) as total_orders,
    sum(o.total_amount) as total_spent,
    case
        when sum(o.total_amount) >= 100000
            then 'VIP'
        when sum(o.total_amount) >= 50000
            then 'PREMIUM'
        when sum(o.total_amount) >= 10000
            then 'REGULAR'
        else 'LOW_VALUE'
    end as customer_segment
from customers c
join orders o
    on c.customer_id = o.customer_id
where o.order_status != 'CANCELLED'

group by
    c.customer_id,
    c.first_name,
    c.last_name

order by total_spent desc;
