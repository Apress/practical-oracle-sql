/* ***************************************************** **
   ch03_divide_and_conquer_with_subquery_factoring.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 3
   Divide and Conquer WITH Subquery Factoring
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 3 example code
   ----------------------------------------------------- */

-- Listing 3-1. Dividing the beers into alcohol class 1 and 2

select
   pa.product_id as p_id
 , p.name        as product_name
 , pa.abv
 , ntile(2) over (
      order by pa.abv, pa.product_id
   ) as alc_class
from product_alcohol pa
join products p
   on p.id = pa.product_id
order by pa.abv, pa.product_id;

-- Listing 3-2. Viewing yearly sales of the beers in alcohol class 1

select
   pac.product_id as p_id
 , extract(year from ms.mth) as yr
 , sum(ms.qty) as yr_qty
from (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
) pac
join monthly_sales ms
   on ms.product_id = pac.product_id
where pac.alc_class = 1
group by
   pac.product_id
 , extract(year from ms.mth)
order by p_id, yr;

-- Listing 3-3. Viewing just the years that sold more than the average year per beer

select
   p_id, yr, yr_qty
 , round(avg_yr) as avg_yr
from (
   select
      pac.product_id as p_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by pac.product_id
      ) as avg_yr
   from (
      select
         pa.product_id
       , ntile(2) over (
            order by pa.abv, pa.product_id
         ) as alc_class
      from product_alcohol pa
   ) pac
   join monthly_sales ms
      on ms.product_id = pac.product_id
   where pac.alc_class = 1
   group by
      pac.product_id
    , extract(year from ms.mth)
)
where yr_qty > avg_yr
order by p_id, yr;

-- Listing 3-4. Rewriting Listing 3-3 using subquery factoring

with product_alc_class as (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
), class_one_yearly_sales as (
   select
      pac.product_id as p_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by pac.product_id
      ) as avg_yr
   from product_alc_class pac
   join monthly_sales ms
      on ms.product_id = pac.product_id
   where pac.alc_class = 1
   group by
      pac.product_id
    , extract(year from ms.mth)
)
select
   p_id, yr, yr_qty
 , round(avg_yr) as avg_yr
from class_one_yearly_sales
where yr_qty > avg_yr
order by p_id, yr;

-- Listing 3-5. Alternative rewrite using independent named subqueries

with product_alc_class as (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
), yearly_sales as (
   select
      ms.product_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by ms.product_id
      ) as avg_yr
   from monthly_sales ms
   group by
      ms.product_id
    , extract(year from ms.mth)
)
select
   pac.product_id as p_id
 , ys.yr
 , ys.yr_qty
 , round(ys.avg_yr) as avg_yr
from product_alc_class pac
join yearly_sales ys
   on ys.product_id = pac.product_id
where pac.alc_class = 1
and ys.yr_qty > ys.avg_yr
order by p_id, yr;

-- Listing 3-6. Querying one subquery multiple places

with product_alc_class as (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
), yearly_sales as (
   select
      ms.product_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by ms.product_id
      ) as avg_yr
   from monthly_sales ms
   where ms.product_id in (
      select pac.product_id
      from product_alc_class pac
      where pac.alc_class = 1
   )
   group by
      ms.product_id
    , extract(year from ms.mth)
)
select
   pac.product_id as p_id
 , ys.yr
 , ys.yr_qty
 , round(ys.avg_yr) as avg_yr
from product_alc_class pac
join yearly_sales ys
   on ys.product_id = pac.product_id
where ys.yr_qty > ys.avg_yr
order by p_id, yr;

-- Undocumented hint to force materializing as adhoc temporary table

with product_alc_class as (
   select /*+ materialize */
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
), yearly_sales as (
   select
      ms.product_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by ms.product_id
      ) as avg_yr
   from monthly_sales ms
   where ms.product_id in (
      select pac.product_id
      from product_alc_class pac
      where pac.alc_class = 1
   )
   group by
      ms.product_id
    , extract(year from ms.mth)
)
select
   pac.product_id as p_id
 , ys.yr
 , ys.yr_qty
 , round(ys.avg_yr) as avg_yr
from product_alc_class pac
join yearly_sales ys
   on ys.product_id = pac.product_id
where ys.yr_qty > ys.avg_yr
order by p_id, yr;

-- Adding always true filter on rownum also forces materialization

with product_alc_class as (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      ) as alc_class
   from product_alcohol pa
   where rownum >= 1
), yearly_sales as (
   select
      ms.product_id
    , extract(year from ms.mth) as yr
    , sum(ms.qty) as yr_qty
    , avg(sum(ms.qty)) over (
         partition by ms.product_id
      ) as avg_yr
   from monthly_sales ms
   where ms.product_id in (
      select pac.product_id
      from product_alc_class pac
      where pac.alc_class = 1
   )
   group by
      ms.product_id
    , extract(year from ms.mth)
)
select
   pac.product_id as p_id
 , ys.yr
 , ys.yr_qty
 , round(ys.avg_yr) as avg_yr
from product_alc_class pac
join yearly_sales ys
   on ys.product_id = pac.product_id
where ys.yr_qty > ys.avg_yr
order by p_id, yr;

-- Listing 3-7. Specifying column names list instead of column aliases

with product_alc_class (
   product_id, alc_class
) as (
   select
      pa.product_id
    , ntile(2) over (
         order by pa.abv, pa.product_id
      )
   from product_alcohol pa
), yearly_sales (
   product_id, yr, yr_qty, avg_yr
) as (
   select
      ms.product_id
    , extract(year from ms.mth)
    , sum(ms.qty)
    , avg(sum(ms.qty)) over (
         partition by ms.product_id
      )
   from monthly_sales ms
   where ms.product_id in (
      select pac.product_id
      from product_alc_class pac
      where pac.alc_class = 1
   )
   group by
      ms.product_id
    , extract(year from ms.mth)
)
select
   pac.product_id as p_id
 , ys.yr
 , ys.yr_qty
 , round(ys.avg_yr) as avg_yr
from product_alc_class pac
join yearly_sales ys
   on ys.product_id = pac.product_id
where ys.yr_qty > ys.avg_yr
order by p_id, yr;

-- Listing 3-8. “Overloading” a table with test data in a with clause

with product_alcohol (
   product_id, sales_volume, abv
) as (
   /* Simulation of table product_alcohol */
   select 4040, 330, 4.5 from dual union all
   select 4160, 500, 7.0 from dual union all
   select 4280, 330, 8.0 from dual union all
   select 5310, 330, 4.0 from dual union all
   select 5430, 330, 8.5 from dual union all
   select 6520, 500, 6.5 from dual union all
   select 6600, 500, 5.0 from dual union all
   select 7790, 500, 4.5 from dual union all
   select 7870, 330, 6.5 from dual union all
   select 7950, 330, 6.0 from dual
)
/* Query to test with simulated data */
select
   pa.product_id as p_id
 , p.name        as product_name
 , pa.abv
 , ntile(2) over (
      order by pa.abv, pa.product_id
   ) as alc_class
from product_alcohol pa
join products p
   on p.id = pa.product_id
order by pa.abv, pa.product_id;

/* ***************************************************** */
