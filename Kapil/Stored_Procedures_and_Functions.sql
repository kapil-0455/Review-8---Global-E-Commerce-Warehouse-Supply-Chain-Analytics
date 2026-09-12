-- ===========================================================
-- Dynamic shipping cost calculation
-- ===========================================================
create or replace function calculate_shipping_cost(
    p_weight numeric,
    p_quantity int
)
returns numeric
language plpgsql
as $$
begin
    return 100 + (p_weight * 50) + (p_quantity * 20);
end;
$$;

select calculate_shipping_cost(5, 2);


-- ===========================================================
-- Inventory replenishment alerts
-- ===========================================================

create or replace function inventory_replenishment_alert(
    p_warehouse_id varchar,
    p_product_id varchar
)
returns text
language plpgsql
as $$
declare
    stock int;
    reorder int;
begin

    select quantity_available, reorder_level
    into stock, reorder
    from inventory
    where warehouse_id = p_warehouse_id
    and product_id = p_product_id;

    if stock <= reorder then
        return 'replenishment required';
    else
        return 'stock sufficient';
    end if;

end;
$$;

select inventory_replenishment_alert('w001', 'p0001');

-- ===========================================================
-- Product discount calculation
-- ===========================================================

create or replace function calculate_discount(
    price numeric,
    discount_percent numeric
)
returns numeric
language plpgsql
as $$
begin
    return price * discount_percent / 100;
end;
$$;

select calculate_discount(10000, 10);


-- ===========================================================
-- Tax Computation
-- ===========================================================

create or replace function calculate_tax(
    amount numeric,
    tax_rate numeric
)
returns numeric
language plpgsql
as $$
begin
    return amount * tax_rate / 100;
end;
$$;

select calculate_tax(10000, 18);

-- ===========================================================
-- Vendor Ranking
-- ===========================================================

create or replace function vendor_ranking()
returns table (
    supplier_id varchar,
    supplier_name varchar,
    rank bigint
)
language sql
as $$
    select
        s.supplier_id,
        s.supplier_name,
        rank() over (
            order by sum(oi.line_total) desc
        )
    from suppliers s
    join supplier_products sp
        on s.supplier_id = sp.supplier_id
    join order_items oi
        on sp.product_id = oi.product_id
    group by
        s.supplier_id,
        s.supplier_name;
$$;

select * from vendor_ranking();
