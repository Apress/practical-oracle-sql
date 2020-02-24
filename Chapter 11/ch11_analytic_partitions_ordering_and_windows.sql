/* ***************************************************** **
   ch11_analytic_partitions_ordering_and_windows.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 11
   Analytic Partitions, Ordering and Windows
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 11 example code
   ----------------------------------------------------- */

-- Listing 11-1. Content of orderlines table for two beers

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-2. The simplest analytic function call is a grand total

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over () as t_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-3. Creating subtotals by product with partitioning

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-4. Creating a running sum with ordering and windowing

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      order by ol.qty
      rows between unbounded preceding
               and current row
   ) as r_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.qty;

-- Ordering of analytic function and query does not need to be identical

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      order by ol.qty
      rows between unbounded preceding
               and current row
   ) as r_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-5. Combining partitioning, ordering and windowing

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between unbounded preceding
               and current row
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-6. Window with all previous rows

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between unbounded preceding
               and 1 preceding
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Window with reversed running sum

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between current row
               and unbounded following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Window of all rows yet to come

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between 1 following
               and unbounded following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Window bounded in both ends

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between 1 preceding
               and 1 following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Window unbounded in both ends

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between unbounded preceding
               and unbounded following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-7. Range window based on qty value

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      range between 20 preceding
                and 20 following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Window does not have to include current row value

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      range between  5 following
                and 25 following
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Running sum in range window includes following rows in case of ties
 
select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      range between unbounded preceding
                and current row
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-8. Comparing running sum with default, range and rows window

select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      /* no window - rely on default */
   ) as def_q
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      range between unbounded preceding
                and current row
   ) as range_q
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty
      rows between unbounded preceding
               and current row
   ) as rows_q
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty;

-- Listing 11-9. A best practice for a running sum
 
select
   ol.product_id as p_id
 , p.name        as product_name
 , ol.order_id   as o_id
 , ol.qty
 , sum(ol.qty) over (
      partition by ol.product_id
      order by ol.qty, ol.order_id
      rows between unbounded preceding
               and current row
   ) as p_qty
from orderlines ol
join products p
   on p.id = ol.product_id
where ol.product_id in (4280, 6600)
order by ol.product_id, ol.qty, ol.order_id;

/* ***************************************************** */
