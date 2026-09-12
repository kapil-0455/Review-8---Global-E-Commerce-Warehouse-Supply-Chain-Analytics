create view customer_order_history 
as
select
c.customer_id,
c.first_name,
c.last_name,
o.order_id,
o.order_date,
o.order_status,
o.total_amount

from customers c

join orders o 
on c.customer_id = o.customer_id;

select * from customer_order_history;


-- second view
create or replace view live_inventory_dashboard as

select
w.warehouse_name,
p.product_name,
p.sku,
i.quantity_available,
i.quantity_reserved,
(i.quantity_available-i.quantity_reserved) as usable_inventory,
i.reorder_level

from inventory i

join warehouses w
on i.warehouse_id =w.warehouse_id

join products p
on i.product_id =p.product_id;

select * from live_inventory_dashboard;

-- third

create view delayed_shipments as

select
shipment_id,
order_id,
tracking_number,
dispatch_date,
expected_delivery_date,
actual_delivery_date

from shipments

where(actual_delivery_date > expected_delivery_date)

select * from delayed_shipments


-- forth view
create view profitability_report as

select
p.product_id,
p.product_name,
sum(oi.quantity) as units_sold,
sum(oi.line_total) as revenue

from order_items oi

join products p
on oi.product_id = p.product_id

group by p.product_id,p.product_name;

select * from profitability_report

