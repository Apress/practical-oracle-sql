/* ***************************************************** **
   ch08_pivoting_rows_to_columns.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 8
   Pivoting Rows to Columns
   
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
   Chapter 8 example code
   ----------------------------------------------------- */

-- Listing 8-2. Yearly purchased quantities by brewery and product group

select
   brewery_name
 , group_name
 , extract(year from purchased) as yr
 , sum(qty) as qty
from purchases_with_dims pwd
group by 
   brewery_name
 , group_name
 , extract(year from purchased)
order by
   brewery_name
 , group_name
 , yr;

-- Listing 8-3. Pivoting the year rows into columns

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , sum(qty) as qty
   from purchases_with_dims pwd
   group by 
      brewery_name
    , group_name
    , extract(year from purchased)
) pivot (
   sum(qty)
   for yr
   in (
      2016 as y2016
    , 2017 as y2017
    , 2018 as y2018
   )
)
order by brewery_name, group_name;

-- Listing 8-4. Utilizing the implicit group by

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , qty
   from purchases_with_dims pwd
) pivot (
   sum(qty)
   for yr
   in (
      2016 as y2016
    , 2017 as y2017
    , 2018 as y2018
   )
)
order by brewery_name, group_name;

-- Listing 8-5. Manual pivoting without using pivot clause

select
   brewery_name
 , group_name
 , sum(
      case extract(year from purchased)
         when 2016 then qty
      end
   ) as y2016
 , sum(
      case extract(year from purchased)
         when 2017 then qty
      end
   ) as y2017
 , sum(
      case extract(year from purchased)
         when 2018 then qty
      end
   ) as y2018
from purchases_with_dims pwd
group by 
   brewery_name
 , group_name
order by brewery_name, group_name;

-- Listing 8-6. Getting an ORA-00918 error with multiple measures

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , qty
    , cost
   from purchases_with_dims pwd
) pivot (
   sum(qty)
 , sum(cost)
   for yr
   in (
      2016 as y2016
    , 2017 as y2017
    , 2018 as y2018
   )
)
order by brewery_name, group_name;

-- Fixing it with measure aliases

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , qty
    , cost
   from purchases_with_dims pwd
) pivot (
   sum(qty) as q
 , sum(cost) as c
   for yr
   in (
      2016 as "16"
    , 2017 as "17"
    , 2018 as "18"
   )
)
order by brewery_name, group_name;

-- Listing 8-7. Combining two dimensions and two measures

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , qty
    , cost
   from purchases_with_dims pwd
   where group_name in ('IPA', 'Wheat')
   and   purchased >= date '2017-01-01'
   and   purchased <  date '2019-01-01'
) pivot (
   sum(qty)  as q
 , sum(cost) as c
   for (group_name, yr)
   in (
      ('IPA'  , 2017) as i17
    , ('IPA'  , 2018) as i18
    , ('Wheat', 2017) as w17
    , ('Wheat', 2018) as w18
   )
)
order by brewery_name;

-- Same output without where clause, but bad idea

select *
from (
   select
      brewery_name
    , group_name
    , extract(year from purchased) as yr
    , qty
    , cost
   from purchases_with_dims pwd
) pivot (
   sum(qty)  as q
 , sum(cost) as c
   for (group_name, yr)
   in (
      ('IPA'  , 2017) as i17
    , ('IPA'  , 2018) as i18
    , ('Wheat', 2017) as w17
    , ('Wheat', 2018) as w18
   )
)
order by brewery_name;

/* ***************************************************** */
