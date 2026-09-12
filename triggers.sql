create or replace function deduct_inventory()
returns trigger
language plpgsql
as $$
declare
selected_warehouse varchar(20);
begin

select warehouse_id
into selected_warehouse

from inventory

where
product_id = new.product_id and quantity_available >= new.quantity
order by quantity_available desc
limit 1;

if selected_warehouse is null then
raise exception 'insufficient inventory';
end if;

update inventory set quantity_available = quantity_available - new.quantity
where
warehouse_id = selected_warehouse and product_id = new.product_id;

return new;
end;
$$;

create or replace trigger trg_inventory_deduction
after insert
on order_items
for each row
execute function deduct_inventory();


--testing
select warehouse_id, product_id, quantity_available
from inventory
where product_id = 'PROD00001'
order by quantity_available desc;

insert into order_items
(order_item_id, order_id, product_id, quantity, unit_price, discount, line_total)
VALUES
('test98', 'ORD000001', 'PROD00001', 5, 1000, 0, 5000);

select warehouse_id, product_id, quantity_available
from inventory
where product_id = 'PROD00001'
order by quantity_available desc;



-- second trigger
create table price_audit (
audit_id serial primary key,
product_id varchar(20),
old_price numeric(14,2),
new_price numeric(14,2),
changed_at timestamp default current_timestamp
);

create or replace function audit_price_change()
returns trigger
language plpgsql
as $$
begin

if old.price <> new.price then

insert into price_audit(product_id,old_price,new_price)
values(old.product_id,old.price,new.price);

end if;
return new;
end;
$$;

create trigger trg_price_audit
after update of price
on product_prices
for each row
execute function audit_price_change();

select
price_id,
product_id,
country,
price
from product_prices
where product_id = 'PROD00001';

update product_prices
set price = price + 100
where product_id = 'PROD00001';

select * from price_audit

-- third trigger

create or replace function restore_returned_inventory()
returns trigger
language plpgsql
as $$
declare
returned_product varchar(20);
target_warehouse varchar(20);
begin

select product_id
into returned_product
from order_items
where order_item_id =new.order_item_id;

select warehouse_id
into target_warehouse
from shipments s
join return_requests r
on s.order_id = r.order_id
where r.return_id = new.return_id
limit 1;

update inventory

set quantity_available =quantity_available+ new.quantity

where
warehouse_id =target_warehouse
and product_id = returned_product;

return new;

end;
$$;

create trigger trg_return_stock
after insert
on return_items
for each row
execute function restore_returned_inventory();