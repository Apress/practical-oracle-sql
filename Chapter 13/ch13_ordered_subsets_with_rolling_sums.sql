/* ***************************************************** **
   ch13_ordered_subsets_with_rolling_sums.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 13
   Ordered Subsets with Rolling Sums
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

alter session set nls_date_format = 'YYYY-MM-DD';

/* -----------------------------------------------------
   Chapter 13 example code
   ----------------------------------------------------- */

-- Listing 13-2. Data for the order I am going to pick

select
   c.id           as c_id
 , c.name         as c_name
 , o.id           as o_id
 , ol.product_id  as p_id
 , p.name         as p_name
 , ol.qty
from orders o
join orderlines ol
   on ol.order_id = o.id
join products p
   on p.id = ol.product_id
join customers c
   on c.id = o.customer_id
where o.id = 421
order by o.id, ol.product_id;

-- Listing 13-3. Possible inventory to pick – in order of purchase date

select
   i.product_id as p_id
 , ol.qty       as ord_q
 , i.qty        as loc_q
 , sum(i.qty) over (
      partition by i.product_id
      order by i.purchased, i.qty
      rows between unbounded preceding and current row
   )            as acc_q
 , i.purchased
 , i.warehouse  as wh
 , i.aisle      as ai
 , i.position   as pos
from orderlines ol
join inventory_with_dims i
   on i.product_id = ol.product_id
where ol.order_id = 421
order by i.product_id, i.purchased, i.qty;

-- Listing 13-4. Filtering on the accumulated sum

select *
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and current row
      )            as acc_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_q <= ord_q
order by p_id, purchased, loc_q;

-- Listing 13-5. Accumulated sum of only the previous rows

select
   i.product_id as p_id
 , ol.qty       as ord_q
 , i.qty        as loc_q
 , sum(i.qty) over (
      partition by i.product_id
      order by i.purchased, i.qty
      rows between unbounded preceding and 1 preceding
   )            as acc_prv_q
 , i.purchased
 , i.warehouse  as wh
 , i.aisle      as ai
 , i.position   as pos
from orderlines ol
join inventory_with_dims i
   on i.product_id = ol.product_id
where ol.order_id = 421
order by i.product_id, i.purchased, i.qty;

-- Listing 13-6. Filtering on the accumulation of previous rows

select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Exchange FIFO principle with location order (shortest drive)

select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.warehouse, i.aisle, i.position    -- << only line changed
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Exchange with principle of least number of picks

select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.qty desc    -- << only line changed
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Exchange with principle of cleaning out small quantities first

select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.qty    -- << only line changed
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Listing 13-7. Consecutively numbering visited warehouse aisles

select
   wh, ai
 , dense_rank() over (
      order by wh, ai
   ) as ai#
 , pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ol.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderlines ol
   join inventory_with_dims i
      on i.product_id = ol.product_id
   where ol.order_id = 421
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Listing 13-8. Ordering ascending and descending alternately

select *
from (
   select
      wh, ai
    , dense_rank() over (
         order by wh, ai
      ) as ai#
    , pos, p_id
    , least(loc_q, ord_q - acc_prv_q) as pick_q
   from (
      select
         i.product_id as p_id
       , ol.qty       as ord_q
       , i.qty        as loc_q
       , nvl(sum(i.qty) over (
            partition by i.product_id
            order by i.purchased, i.qty
            rows between unbounded preceding and 1 preceding
         ), 0)        as acc_prv_q
       , i.purchased
       , i.warehouse  as wh
       , i.aisle      as ai
       , i.position   as pos
      from orderlines ol
      join inventory_with_dims i
         on i.product_id = ol.product_id
      where ol.order_id = 421
   )
   where acc_prv_q < ord_q
)
order by
   wh, ai#
 , case
      when mod(ai#, 2) = 1 then +pos
                           else -pos
   end;

-- Listing 13-9. Restarting aisle numbering within each warehouse

select *
from (
   select
      wh, ai
    , dense_rank() over (
         partition by wh
         order by ai
      ) as ai#
    , pos, p_id
    , least(loc_q, ord_q - acc_prv_q) as pick_q
   from (
      select
         i.product_id as p_id
       , ol.qty       as ord_q
       , i.qty        as loc_q
       , nvl(sum(i.qty) over (
            partition by i.product_id
            order by i.purchased, i.qty
            rows between unbounded preceding and 1 preceding
         ), 0)        as acc_prv_q
       , i.purchased
       , i.warehouse  as wh
       , i.aisle      as ai
       , i.position   as pos
      from orderlines ol
      join inventory_with_dims i
         on i.product_id = ol.product_id
      where ol.order_id = 421
   )
   where acc_prv_q < ord_q
)
order by
   wh, ai#
 , case
      when mod(ai#, 2) = 1 then +pos
                           else -pos
   end;

-- Now to batch pick multiple orders simultaneously

select
   c.id           as c_id
 , c.name         as c_name
 , o.id           as o_id
 , ol.product_id  as p_id
 , p.name         as p_name
 , ol.qty
from orders o
join orderlines ol
   on ol.order_id = o.id
join products p
   on p.id = ol.product_id
join customers c
   on c.id = o.customer_id
where o.id in (422, 423)
order by o.id, ol.product_id;

-- Listing 13-10. FIFO picking of the total quantities

with orderbatch as (
   select
      ol.product_id
    , sum(ol.qty) as qty
   from orderlines ol
   where ol.order_id in (422, 423)
   group by ol.product_id
)
select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
from (
   select
      i.product_id as p_id
    , ob.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderbatch ob
   join inventory_with_dims i
      on i.product_id = ob.product_id
)
where acc_prv_q < ord_q
order by wh, ai, pos;

-- Listing 13-11. Quantity intervals for each pick out of total per product

with orderbatch as (
   select
      ol.product_id
    , sum(ol.qty) as qty
   from orderlines ol
   where ol.order_id in (422, 423)
   group by ol.product_id
)
select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
 , acc_prv_q + 1       as from_q
 , least(acc_q, ord_q) as to_q
from (
   select
      i.product_id as p_id
    , ob.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and current row
      ), 0)        as acc_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderbatch ob
   join inventory_with_dims i
      on i.product_id = ob.product_id
)
where acc_prv_q < ord_q
order by p_id, purchased, loc_q, wh, ai, pos;

-- Listing 13-12. Quantity intervals with a single analytic sum

with orderbatch as (
   select
      ol.product_id
    , sum(ol.qty) as qty
   from orderlines ol
   where ol.order_id in (422, 423)
   group by ol.product_id
)
select
   wh, ai, pos, p_id
 , least(loc_q, ord_q - acc_prv_q) as pick_q
 , acc_prv_q + 1                   as from_q
 , least(acc_prv_q + loc_q, ord_q) as to_q
from (
   select
      i.product_id as p_id
    , ob.qty       as ord_q
    , i.qty        as loc_q
    , nvl(sum(i.qty) over (
         partition by i.product_id
         order by i.purchased, i.qty
         rows between unbounded preceding and 1 preceding
      ), 0)        as acc_prv_q
    , i.purchased
    , i.warehouse  as wh
    , i.aisle      as ai
    , i.position   as pos
   from orderbatch ob
   join inventory_with_dims i
      on i.product_id = ob.product_id
)
where acc_prv_q < ord_q
order by p_id, purchased, loc_q, wh, ai, pos;

-- Listing 13-13. Quantity intervals for each order out of total per product

select
   ol.order_id    as o_id
 , ol.product_id  as p_id
 , ol.qty
 , nvl(sum(ol.qty) over (
      partition by ol.product_id
      order by ol.order_id
      rows between unbounded preceding and 1 preceding
   ), 0) + 1      as from_q
 , nvl(sum(ol.qty) over (
      partition by ol.product_id
      order by ol.order_id
      rows between unbounded preceding and 1 preceding
   ), 0) + ol.qty as to_q
from orderlines ol
where ol.order_id in (422, 423)
order by ol.product_id, ol.order_id;

-- Listing 13-14. Join overlapping pick and order quantity intervals

with olines as (
   select
      ol.order_id    as o_id
    , ol.product_id  as p_id
    , ol.qty
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + 1      as from_q
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + ol.qty as to_q
   from orderlines ol
   where ol.order_id in (422, 423)
), orderbatch as (
   select
      ol.p_id
    , sum(ol.qty) as qty
   from olines ol
   group by ol.p_id
), fifo as (
   select
      wh, ai, pos, p_id, loc_q
    , least(loc_q, ord_q - acc_prv_q) as pick_q
    , acc_prv_q + 1                   as from_q
    , least(acc_prv_q + loc_q, ord_q) as to_q
   from (
      select
         i.product_id as p_id
       , ob.qty       as ord_q
       , i.qty        as loc_q
       , nvl(sum(i.qty) over (
            partition by i.product_id
            order by i.purchased, i.qty
            rows between unbounded preceding and 1 preceding
         ), 0)        as acc_prv_q
       , i.purchased
       , i.warehouse  as wh
       , i.aisle      as ai
       , i.position   as pos
      from orderbatch ob
      join inventory_with_dims i
         on i.product_id = ob.p_id
   )
   where acc_prv_q < ord_q
)
select
   f.wh, f.ai, f.pos, f.p_id
 , f.pick_q, f.from_q as p_f_q, f.to_q as p_t_q
 , o.o_id  , o.from_q as o_f_q, o.to_q as o_t_q
from fifo f
join olines o
   on o.p_id = f.p_id
   and o.to_q >= f.from_q
   and o.from_q <= f.to_q
order by f.p_id, f.from_q, o.from_q;

-- Listing 13-15. How much quantity from each pick goes to which order

with olines as (
   select
      ol.order_id    as o_id
    , ol.product_id  as p_id
    , ol.qty
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + 1      as from_q
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + ol.qty as to_q
   from orderlines ol
   where ol.order_id in (422, 423)
), orderbatch as (
   select
      ol.p_id
    , sum(ol.qty) as qty
   from olines ol
   group by ol.p_id
), fifo as (
   select
      wh, ai, pos, p_id, loc_q
    , least(loc_q, ord_q - acc_prv_q) as pick_q
    , acc_prv_q + 1                   as from_q
    , least(acc_prv_q + loc_q, ord_q) as to_q
   from (
      select
         i.product_id as p_id
       , ob.qty       as ord_q
       , i.qty        as loc_q
       , nvl(sum(i.qty) over (
            partition by i.product_id
            order by i.purchased, i.qty
            rows between unbounded preceding and 1 preceding
         ), 0)        as acc_prv_q
       , i.purchased
       , i.warehouse  as wh
       , i.aisle      as ai
       , i.position   as pos
      from orderbatch ob
      join inventory_with_dims i
         on i.product_id = ob.p_id
   )
   where acc_prv_q < ord_q
)
select
   f.wh, f.ai, f.pos, f.p_id
 , f.pick_q, o.o_id
 , least(
      f.loc_q
    , least(o.to_q, f.to_q) - greatest(o.from_q, f.from_q) + 1
   ) as q_f_o
from fifo f
join olines o
   on o.p_id = f.p_id
   and o.to_q >= f.from_q
   and o.from_q <= f.to_q
order by f.p_id, f.from_q, o.from_q;

-- Listing 13-16. The ultimate FIFO batch-picking SQL statement

with olines as (
   select
      ol.order_id    as o_id
    , ol.product_id  as p_id
    , ol.qty
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + 1      as from_q
    , nvl(sum(ol.qty) over (
         partition by ol.product_id
         order by ol.order_id
         rows between unbounded preceding and 1 preceding
      ), 0) + ol.qty as to_q
   from orderlines ol
   where ol.order_id in (422, 423)
), orderbatch as (
   select
      ol.p_id
    , sum(ol.qty) as qty
   from olines ol
   group by ol.p_id
), fifo as (
   select
      wh, ai, pos, p_id, loc_q
    , least(loc_q, ord_q - acc_prv_q) as pick_q
    , acc_prv_q + 1                   as from_q
    , least(acc_prv_q + loc_q, ord_q) as to_q
   from (
      select
         i.product_id as p_id
       , ob.qty       as ord_q
       , i.qty        as loc_q
       , nvl(sum(i.qty) over (
            partition by i.product_id
            order by i.purchased, i.qty
            rows between unbounded preceding and 1 preceding
         ), 0)        as acc_prv_q
       , i.purchased
       , i.warehouse  as wh
       , i.aisle      as ai
       , i.position   as pos
      from orderbatch ob
      join inventory_with_dims i
         on i.product_id = ob.p_id
   )
   where acc_prv_q < ord_q
), pick as (
   select
      f.wh, f.ai
    , dense_rank() over (
         order by wh, ai
      ) as ai#
    , f.pos, f.p_id
    , f.pick_q, o.o_id
    , least(
         f.loc_q
       , least(o.to_q, f.to_q) - greatest(o.from_q, f.from_q) + 1
      ) as q_f_o
   from fifo f
   join olines o
      on o.p_id = f.p_id
      and o.to_q >= f.from_q
      and o.from_q <= f.to_q
)
select
   p.wh, p.ai, p.pos
 , p.p_id, p.pick_q
 , p.o_id, p.q_f_o
from pick p
order by p.wh
       , p.ai#
       , case
            when mod(p.ai#, 2) = 1 then +p.pos
                                   else -p.pos
         end;

/* ***************************************************** */
