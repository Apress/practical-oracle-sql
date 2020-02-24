/* ***************************************************** **
   ch16_rolling_sums_to_forecast_reaching_minimums.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 16
   Rolling Sums to Forecast Reaching Minimums
   
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
   Chapter 16 example code
   ----------------------------------------------------- */

-- Listing 16-3. The inventory totals for two products

select it.product_id, p.name, it.qty
from inventory_totals it
join products p
   on p.id = it.product_id
where product_id in (6520, 6600)
order by product_id;

-- Listing 16-4. The 2019 monthly budget for the two beers

select mb.product_id, mb.mth, mb.qty
from monthly_budget mb
where mb.product_id in (6520, 6600)
and mb.mth >= date '2019-01-01'
order by mb.product_id, mb.mth;

-- Listing 16-5. The current monthly order quantities

select mo.product_id, mo.mth, mo.qty
from monthly_orders mo
where mo.product_id in (6520, 6600)
order by mo.product_id, mo.mth;

-- Listing 16-6. Accumulating quantities

select
   mb.product_id as p_id, mb.mth
 , mb.qty b_qty, mo.qty o_qty
 , greatest(mb.qty, nvl(mo.qty, 0)) as qty
 , sum(greatest(mb.qty, nvl(mo.qty, 0))) over (
      partition by mb.product_id
      order by mb.mth
      rows between unbounded preceding and current row
   ) as acc_qty
from monthly_budget mb
left outer join monthly_orders mo
   on mo.product_id = mb.product_id
   and mo.mth = mb.mth
where mb.product_id in (6520, 6600)
and mb.mth >= date '2019-01-01'
order by mb.product_id, mb.mth;

-- Listing 16-7. Dwindling inventory

select
   mb.product_id as p_id, mb.mth
 , greatest(mb.qty, nvl(mo.qty, 0)) as qty
 , greatest(
      it.qty - nvl(sum(
          greatest(mb.qty, nvl(mo.qty, 0))
      ) over (
         partition by mb.product_id
         order by mb.mth
         rows between unbounded preceding and 1 preceding
      ), 0)
    , 0
   ) as inv_begin
 , greatest(
      it.qty - sum(
          greatest(mb.qty, nvl(mo.qty, 0))
      ) over (
         partition by mb.product_id
         order by mb.mth
         rows between unbounded preceding and current row
      )
    , 0
   ) as inv_end
from monthly_budget mb
left outer join monthly_orders mo
   on mo.product_id = mb.product_id
   and mo.mth = mb.mth
join inventory_totals it
   on it.product_id = mb.product_id
where mb.product_id in (6520, 6600)
and mb.mth >= date '2019-01-01'
order by mb.product_id, mb.mth;

-- Listing 16-8. Estimating when zero is reached

select
   product_id as p_id, mth, inv_begin, inv_end
 , trunc(
      mth + numtodsinterval(
               (add_months(mth, 1) - 1 - mth) * inv_begin / qty
             , 'day'
            )
   ) as zero_day
from (
   select
      mb.product_id, mb.mth
    , greatest(mb.qty, nvl(mo.qty, 0)) as qty
    , greatest(
         it.qty - nvl(sum(
             greatest(mb.qty, nvl(mo.qty, 0))
         ) over (
            partition by mb.product_id
            order by mb.mth
            rows between unbounded preceding and 1 preceding
         ), 0)
       , 0
      ) as inv_begin
    , greatest(
         it.qty - sum(
             greatest(mb.qty, nvl(mo.qty, 0))
         ) over (
            partition by mb.product_id
            order by mb.mth
            rows between unbounded preceding and current row
         )
       , 0
      ) as inv_end
   from monthly_budget mb
   left outer join monthly_orders mo
      on mo.product_id = mb.product_id
      and mo.mth = mb.mth
   join inventory_totals it
      on it.product_id = mb.product_id
   where mb.product_id in (6520, 6600)
   and mb.mth >= date '2019-01-01'
)
where inv_begin > 0 and inv_end = 0
order by product_id;

-- Listing 16-9. Product minimum restocking parameters

select product_id, qty_minimum, qty_purchase
from product_minimums pm
where pm.product_id in (6520, 6600)
order by pm.product_id;

-- Listing 16-10. Restocking when a minimum is reached

with mb_recur(
   product_id, mth, qty, inv_begin, date_purch
 , p_qty, inv_end, qty_minimum, qty_purchase
) as (
   select
      it.product_id
    , date '2018-12-01' as mth
    , 0 as qty
    , 0 as inv_begin
    , cast(null as date) as date_purch
    , 0 as p_qty
    , it.qty as inv_end
    , pm.qty_minimum
    , pm.qty_purchase
   from inventory_totals it
   join product_minimums pm
      on pm.product_id = it.product_id
   where it.product_id in (6520, 6600)
union all
   select
      mb.product_id
    , mb.mth
    , greatest(mb.qty, nvl(mo.qty, 0)) as qty
    , mbr.inv_end as inv_begin
    , case
         when mbr.inv_end - greatest(mb.qty, nvl(mo.qty, 0))
               < mbr.qty_minimum
         then
            trunc(
               mb.mth
             + numtodsinterval(
                  (add_months(mb.mth, 1) - 1 - mb.mth)
                   * (mbr.inv_end - mbr.qty_minimum)
                   / mb.qty
                , 'day'
               )
            )
      end as date_purch
    , case
         when mbr.inv_end - greatest(mb.qty, nvl(mo.qty, 0))
               < mbr.qty_minimum
         then mbr.qty_purchase
      end as p_qty
    , mbr.inv_end - greatest(mb.qty, nvl(mo.qty, 0))
       + case
            when mbr.inv_end - greatest(mb.qty, nvl(mo.qty, 0))
                  < mbr.qty_minimum
            then mbr.qty_purchase
            else 0
         end as inv_end
    , mbr.qty_minimum
    , mbr.qty_purchase
   from mb_recur mbr
   join monthly_budget mb
      on mb.product_id = mbr.product_id
      and mb.mth = add_months(mbr.mth, 1)
   left outer join monthly_orders mo
      on mo.product_id = mb.product_id
      and mo.mth = mb.mth
)
select
   product_id as p_id, mth, qty, inv_begin
 , date_purch, p_qty, inv_end
from mb_recur
where mth >= date '2019-01-01'
and p_qty is not null
order by product_id, mth;

-- Listing 16-11. Restocking with model clause

select
   product_id as p_id, mth, qty, inv_begin
 , date_purch, p_qty, inv_end
from (
   select *
   from monthly_budget mb
   left outer join monthly_orders mo
      on mo.product_id = mb.product_id
      and mo.mth = mb.mth
   join inventory_totals it
      on it.product_id = mb.product_id
   join product_minimums pm
      on pm.product_id = mb.product_id
   where mb.product_id in (6520, 6600)
   and mb.mth >= date '2019-01-01'
   model
   partition by (mb.product_id)
   dimension by (
      row_number() over (
         partition by mb.product_id order by mb.mth
      ) - 1 as rn
   )
   measures (
      mb.mth
    , greatest(mb.qty, nvl(mo.qty, 0)) as qty
    , 0 as inv_begin
    , cast(null as date) as date_purch
    , 0 as p_qty
    , 0 as inv_end
    , it.qty as inv_orig
    , pm.qty_minimum
    , pm.qty_purchase
   )
   rules sequential order iterate (12) (
      inv_begin[iteration_number]
       = nvl(inv_end[iteration_number-1], inv_orig[cv()])
    , p_qty[iteration_number]
       = case
            when inv_begin[cv()] - qty[cv()]
                  < qty_minimum[cv()]
            then qty_purchase[cv()]
         end
    , date_purch[iteration_number]
       = case
            when p_qty[cv()] is not null
            then
               trunc(
                  mth[cv()]
                + numtodsinterval(
                     (add_months(mth[cv()], 1) - 1 - mth[cv()])
                      * (inv_begin[cv()] - qty_minimum[cv()])
                      / qty[cv()]
                   , 'day'
                  )
               )
         end
    , inv_end[iteration_number]
       = inv_begin[cv()] + nvl(p_qty[cv()], 0) - qty[cv()]
   )
)
where p_qty is not null
order by product_id, mth;

/* ***************************************************** */
