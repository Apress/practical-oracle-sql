/* ***************************************************** **
   ch21_bin_fitting.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 21
   Bin Fitting
   
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
   Chapter 21 example code
   ----------------------------------------------------- */

-- Listing 21-1. The inventory of the beer "Der Helle Kumpel"

select
   product_name
 , warehouse as wh
 , aisle
 , position  as pos
 , qty
from inventory_with_dims
where product_name = 'Der Helle Kumpel'
order by wh, aisle, pos;

-- Bin fitting with unlimited number of bins of limited capacity

-- Listing 21-2. Bin fitting in order of location

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 72
)
order by wh, aisle, pos;

-- Change to order by descending quantity

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by qty desc, wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 72
)
order by qty desc, wh, aisle, pos;

-- Listing 21-3. Using a simple best-fit approximation

select wh, aisle, pos, qty, run_qty, box#, box_qty
     , prio ,rn
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
    , case when qty > 72*2/3 then 1 else 2 end prio
    , least(
         row_number() over (
            partition by
               case when qty > 72*2/3 then 1 else 2 end
            order by qty
         )
       , row_number() over (
            partition by
               case when qty > 72*2/3 then 1 else 2 end
            order by qty desc
         )
      ) rn
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by prio, rn, qty desc, wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 72
)
order by prio, rn, qty desc, wh, aisle, pos;

-- Listing 21-4. Using partition by to bin fit all products

select product_id
     , wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_id
    , product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
    , case when qty > 72*2/3 then 1 else 2 end prio
    , least(
         row_number() over (
            partition by
               product_id
             , case when qty > 72*2/3 then 1 else 2 end
            order by qty
         )
       , row_number() over (
            partition by
               product_id
             , case when qty > 72*2/3 then 1 else 2 end
            order by qty desc
         )
      ) rn
   from inventory_with_dims
) iwd
match_recognize (
   partition by product_id
   order by prio, rn, qty desc, wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 72
)
order by product_id, prio, rn, qty desc, wh, aisle, pos;

-- Listing 21-5. Getting a single output row for each box

select product_id, product_name, box#, box_qty, locs
from (
   select
      product_id
    , product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
    , case when qty > 72*2/3 then 1 else 2 end prio
    , least(
         row_number() over (
            partition by
               product_id
             , case when qty > 72*2/3 then 1 else 2 end
            order by qty
         )
       , row_number() over (
            partition by
               product_id
             , case when qty > 72*2/3 then 1 else 2 end
            order by qty desc
         )
      ) rn
   from inventory_with_dims
) iwd
match_recognize (
   partition by product_id
   order by prio, rn, qty desc, wh, aisle, pos
   measures
      max(product_name) as product_name
    , match_number()    as box#
    , final sum(qty)    as box_qty
    , final count(*)    as locs
   one row per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 72
)
order by product_id, box#;

-- Listing 21-6. Problems when the boxes are too small

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 64
)
order by wh, aisle, pos;

-- Changing + in the pattern to a *

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match
   pattern (
      fits_in_box*
   )
   define
      fits_in_box as sum(qty) <= 64
)
order by wh, aisle, pos;

-- Omit empty matches

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match omit empty matches
   pattern (
      fits_in_box*
   )
   define
      fits_in_box as sum(qty) <= 64
)
order by wh, aisle, pos;

-- Back to + but with unmatched rows

select wh, aisle, pos, qty, run_qty, box#, box_qty
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by wh, aisle, pos
   measures
      match_number()   as box#
    , running sum(qty) as run_qty
    , final   sum(qty) as box_qty
   all rows per match with unmatched rows
   pattern (
      fits_in_box+
   )
   define
      fits_in_box as sum(qty) <= 64
)
order by wh, aisle, pos;

-- Bin fitting with limited number of bins of unlimited capacity

-- Listing 21-7. The inventory of the beer “Der Helle Kumpel” in order of descending quantity

select
   product_name
 , warehouse as wh
 , aisle
 , position  as pos
 , qty
from inventory_with_dims
where product_name = 'Der Helle Kumpel'
order by qty desc, wh, aisle, pos;

-- Listing 21-8. All rows in a single match, distributing with logic in define clause

select wh, aisle, pos, qty, box, qty1, qty2, qty3
from (
   select
      product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
   where product_name = 'Der Helle Kumpel'
) iwd
match_recognize (
   order by qty desc, wh, aisle, pos
   measures
      classifier()          as box
    , running sum(box1.qty) as qty1
    , running sum(box2.qty) as qty2
    , running sum(box3.qty) as qty3
   all rows per match
   pattern (
      (box1 | box2 | box3)*
   )
   define
      box1 as count(box1.*) = 1
           or sum(box1.qty) - box1.qty
                <= least(sum(box2.qty), sum(box3.qty))
    , box2 as count(box2.*) = 1
           or sum(box2.qty) - box2.qty
                <= sum(box3.qty)
)
order by qty desc, wh, aisle, pos;

-- Listing 21-9. All products in 3 boxes each - output sorted by location

select product_name, wh, aisle, pos, qty, box
from (
   select
      product_id
    , product_name
    , warehouse as wh
    , aisle
    , position  as pos
    , qty
   from inventory_with_dims
) iwd
match_recognize (
   partition by product_id
   order by qty desc, wh, aisle, pos
   measures
      classifier()          as box
   all rows per match
   pattern (
      (box1 | box2 | box3)*
   )
   define
      box1 as count(box1.*) = 1
           or sum(box1.qty) - box1.qty
                <= least(sum(box2.qty), sum(box3.qty))
    , box2 as count(box2.*) = 1
           or sum(box2.qty) - box2.qty
                <= sum(box3.qty)
)
order by wh, aisle, pos;

/* ***************************************************** */
