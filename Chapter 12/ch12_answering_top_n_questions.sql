/* ***************************************************** **
   ch12_answering_top_n_questions.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 12
   Answering Top-N Questions
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 12 example code
   ----------------------------------------------------- */

-- Listing 12-2. A view of the total sales data

select product_name, total_qty
from total_sales
order by total_qty desc;

-- A view of the yearly sales data

select yr, product_name, yr_qty
from yearly_sales
order by yr, yr_qty desc;

-- Listing 12-3. A view of the yearly sales data
-- (manually formatted, not ansiconsole)

set pagesize 60
set linesize 60
set sqlformat
column rn format 99
column 2016_prod format a9
column 2016 format 999
column 2017_prod format a9
column 2017 format 999
column 2018_prod format a9
column 2018 format 999

select *
from (
   select
      yr, product_name, yr_qty
    , row_number() over (
         partition by yr
         order by yr_qty desc
      ) as rn
   from yearly_sales
)
pivot (
   max(product_name) as prod
 , max(yr_qty)
   for yr in (
      2016, 2017, 2018
   )
)
order by rn;

set pagesize 60
set linesize 60
set sqlformat ansiconsole

-- Listing 12-4. Top-3 using inline view and filter on rownum

select *
from (
   select product_name, total_qty
   from total_sales
   order by total_qty desc
)
where rownum <= 3;

-- Listing 12-5. Top-3 using inline view and filter on row_number()

select *
from (
   select
      product_name, total_qty
    , row_number() over (order by total_qty desc) as ranking
   from total_sales
)
where ranking <= 3
order by ranking;

-- Listing 12-6. Comparison of the three analytic ranking functions

select
   product_name, total_qty
 , row_number() over (order by total_qty desc) as rn
 , rank() over (order by total_qty desc) as rnk
 , dense_rank() over (order by total_qty desc) as dr
from total_sales
order by total_qty desc;

-- Changing ranking function of Listing 12-5 to rank()

select *
from (
   select
      product_name, total_qty
    , rank() over (order by total_qty desc) as ranking
   from total_sales
)
where ranking <= 3
order by ranking;

-- Changing ranking function of Listing 12-5 to dense_rank()

select *
from (
   select
      product_name, total_qty
    , dense_rank() over (order by total_qty desc) as ranking
   from total_sales
)
where ranking <= 3
order by ranking;

-- Listing 12-7. Fetching only the first three rows

select product_name, total_qty
from total_sales
order by total_qty desc
fetch first 3 rows only;

-- Fetching the first three rows with ties

select product_name, total_qty
from total_sales
order by total_qty desc
fetch first 3 rows with ties;

-- Listing 12-8. Comparison of analytic functions for 2018 sales

select
   product_name, yr_qty
 , row_number() over (order by yr_qty desc) as rn
 , rank() over (order by yr_qty desc) as rnk
 , dense_rank() over (order by yr_qty desc) as dr
from yearly_sales
where yr = 2018
order by yr_qty desc
fetch first 5 rows only;

-- Listing 12-9. Fetching first three rows for 2018

select product_name, yr_qty
from yearly_sales
where yr = 2018
order by yr_qty desc
fetch first 3 rows only;

-- Making deterministic output

select product_name, yr_qty
from yearly_sales
where yr = 2018
order by yr_qty desc, product_id
fetch first 3 rows only;

-- Fetching with ties

select product_name, yr_qty
from yearly_sales
where yr = 2018
order by yr_qty desc
fetch first 3 rows with ties;

-- Distinct order and with ties makes no sense

select product_name, yr_qty
from yearly_sales
where yr = 2018
order by yr_qty desc, product_id
fetch first 3 rows with ties;

-- Comparison in 2017 (copy of Listing 12-8)

select
   product_name, yr_qty
 , row_number() over (order by yr_qty desc) as rn
 , rank() over (order by yr_qty desc) as rnk
 , dense_rank() over (order by yr_qty desc) as dr
from yearly_sales
where yr = 2017
order by yr_qty desc
fetch first 5 rows only;

-- Listing 12-10. Fetching with ties for 2017

select product_name, yr_qty
from yearly_sales
where yr = 2017
order by yr_qty desc
fetch first 3 rows with ties;

-- Listing 12-11. Using dense_rank for what fetch first cannot do

select *
from (
   select
      product_name, yr_qty
    , dense_rank() over (order by yr_qty desc) as ranking
   from yearly_sales
   where yr = 2017
)
where ranking <= 3
order by ranking;

-- Listing 12-12. Ranking with row_number within each year

select *
from (
   select
      yr, product_name, yr_qty
    , row_number() over (
         partition by yr
         order by yr_qty desc
      ) as ranking
   from yearly_sales
)
where ranking <= 3
order by yr, ranking;

-- Changing ranking function to rank()

select *
from (
   select
      yr, product_name, yr_qty
    , rank() over (
         partition by yr
         order by yr_qty desc
      ) as ranking
   from yearly_sales
)
where ranking <= 3
order by yr, ranking;

-- Changing ranking function to dense_rank()

select *
from (
   select
      yr, product_name, yr_qty
    , dense_rank() over (
         partition by yr
         order by yr_qty desc
      ) as ranking
   from yearly_sales
)
where ranking <= 3
order by yr, ranking;

-- Listing 12-13. Using fetch first in a laterally joined inline view

select top_sales.*
from (
   select 2016 as yr from dual union all
   select 2017 as yr from dual union all
   select 2018 as yr from dual
) years
cross join lateral (
   select yr, product_name, yr_qty
   from yearly_sales
   where yearly_sales.yr = years.yr
   order by yr_qty desc
   fetch first 3 rows with ties
) top_sales;

/* ***************************************************** */
