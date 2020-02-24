/* ***************************************************** **
   ch09_splitting_delimited_text.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 9
   Splitting Delimited Text
   
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
   Chapter 9 example code
   ----------------------------------------------------- */

-- Listing 9-1. Comma-delimited content of customer_favorites table

select customer_id, favorite_list
from customer_favorites
order by customer_id;

-- Listing 9-3. Using pipelined table function to split string

select
   cf.customer_id
 , fl.column_value as product_id
from customer_favorites cf
   , table(
        favorite_list_to_coll_type(cf.favorite_list)
     ) fl
order by cf.customer_id, fl.column_value;

-- Including customers with no favorites

select
   cf.customer_id
 , fl.column_value as product_id
from customer_favorites cf
   , table(
        favorite_list_to_coll_type(cf.favorite_list)
     )(+) fl
order by cf.customer_id, fl.column_value;

-- Listing 9-4. Join the results of the splitting to products

select
   cf.customer_id  as c_id
 , c.name          as cust_name
 , fl.column_value as p_id
 , p.name          as prod_name
from customer_favorites cf
cross apply table(
   favorite_list_to_coll_type(cf.favorite_list)
) fl
join customers c
   on c.id = cf.customer_id
join products p
   on p.id = fl.column_value
order by cf.customer_id, fl.column_value;

-- Including customers with no favorites - ANSI style

select
   cf.customer_id  as c_id
 , c.name          as cust_name
 , fl.column_value as p_id
 , p.name          as prod_name
from customer_favorites cf
outer apply table(
   favorite_list_to_coll_type(cf.favorite_list)
) fl
join customers c
   on c.id = cf.customer_id
left outer join products p
   on p.id = fl.column_value
order by cf.customer_id, fl.column_value;

-- Listing 9-5. Splitting with apex_string.split

select
   cf.customer_id  as c_id
 , c.name          as cust_name
 , to_number(fl.column_value) as p_id
 , p.name          as prod_name
from customer_favorites cf
cross apply table(
   apex_string.split(cf.favorite_list, ',')
) fl
join customers c
   on c.id = cf.customer_id
join products p
   on p.id = to_number(fl.column_value)
order by cf.customer_id, p_id;

-- Including customers with no favorites - ANSI style

select
   cf.customer_id  as c_id
 , c.name          as cust_name
 , to_number(fl.column_value) as p_id
 , p.name          as prod_name
from customer_favorites cf
outer apply table(
   apex_string.split(cf.favorite_list, ',')
) fl
join customers c
   on c.id = cf.customer_id
left outer join products p
   on p.id = to_number(fl.column_value)
order by cf.customer_id, p_id;

--  Listing 9-6. Generating as many rows as delimiter count

select
   favs.customer_id as c_id
 , c.name           as cust_name
 , favs.product_id  as p_id
 , p.name           as prod_name
from (
   select
      cf.customer_id
    , to_number(
         regexp_substr(cf.favorite_list, '[^,]+', 1, sub#)
      ) as product_id
   from customer_favorites cf
   cross join lateral(
      select level sub#
      from dual
      connect by level <= regexp_count(cf.favorite_list, ',') + 1
   ) fl
) favs
join customers c
   on c.id = favs.customer_id
join products p
   on p.id = favs.product_id
order by favs.customer_id, favs.product_id;

-- Handling if there could have been blanks in the string

select
   favs.customer_id as c_id
 , c.name           as cust_name
 , favs.product_id  as p_id
 , p.name           as prod_name
from (
   select
      cf.customer_id
    , to_number(
         regexp_substr(
            cf.favorite_list
          , '(^|,)([^,]*)'
          , 1
          , sub#
          , null
          , 2
         )
      ) as product_id
   from customer_favorites cf
   cross join lateral(
      select level sub#
      from dual
      connect by level <= regexp_count(cf.favorite_list, ',') + 1
   ) fl
) favs
join customers c
   on c.id = favs.customer_id
join products p
   on p.id = favs.product_id
order by favs.customer_id, favs.product_id;

-- Listing 9-7. Treating the string as a JSON array

select
   cf.customer_id  as c_id
 , c.name          as cust_name
 , fl.product_id   as p_id
 , p.name          as prod_name
from customer_favorites cf
outer apply json_table(
   '[' || cf.favorite_list || ']'
 , '$[*]'
   columns (
      product_id number path '$'
   )
) fl
join customers c
   on c.id = cf.customer_id
left outer join products p
   on p.id = fl.product_id
order by cf.customer_id, fl.product_id;

-- Listing 9-8. Comma- and colon-delimited content of customer_reviews table

select customer_id, review_list
from customer_reviews
order by customer_id;

--  Listing 9-10. Using the ODCI table function to parse the delimited data

select cr.customer_id, rl.product_id, rl.score
from customer_reviews cr
outer apply table (
   delimited_col_row.parser(
      cr.review_list
    , 'PRODUCT_ID:NUMBER,SCORE:VARCHAR2(1)'
    , ':'
    , ','
   )
) rl
order by cr.customer_id, rl.product_id;

-- Listing 9-11. Joining with real column names instead of generic column_value

select
   cr.customer_id  as c_id
 , c.name          as cust_name
 , rl.product_id   as p_id
 , p.name          as prod_name
 , rl.score
from customer_reviews cr
cross apply table (
   delimited_col_row.parser(
      cr.review_list
    , 'PRODUCT_ID:NUMBER,SCORE:VARCHAR2(1)'
    , ':'
    , ','
   )
) rl
join customers c
   on c.id = cr.customer_id
join products p
   on p.id = rl.product_id
order by cr.customer_id, rl.product_id;

-- Listing 9-12. Getting rows with apex_string.split and columns with substr

select
   cr.customer_id  as c_id
 , c.name          as cust_name
 , p.id            as p_id
 , p.name          as prod_name
 , substr(
      rl.column_value
    , instr(rl.column_value, ':') + 1
   ) as score
from customer_reviews cr
cross apply table(
   apex_string.split(cr.review_list, ',')
) rl
join customers c
   on c.id = cr.customer_id
join products p
   on p.id = to_number(
                substr(
                   rl.column_value
                 , 1
                 , instr(rl.column_value, ':') - 1
             ))
order by cr.customer_id, p_id;

-- Listing 9-13. Generating as many rows as delimiter count

select
   revs.customer_id as c_id
 , c.name           as cust_name
 , revs.product_id  as p_id
 , p.name           as prod_name
 , revs.score
from (
   select
      cr.customer_id
    , to_number(
         regexp_substr(
            cr.review_list
          , '(^|,)([^:,]*)'
          , 1
          , sub#
          , null
          , 2
         )
      ) as product_id
    , regexp_substr(
         cr.review_list
       , '([^:,]*)(,|$)'
       , 1
       , sub#
       , null
       , 1
      ) as score
   from customer_reviews cr
   cross join lateral(
      select level sub#
      from dual
      connect by level <= regexp_count(cr.review_list, ',') + 1
   ) rl
) revs
join customers c
   on c.id = revs.customer_id
join products p
   on p.id = revs.product_id
order by revs.customer_id, revs.product_id;

-- Listing 9-14. Turning delimited text into JSON

select
   customer_id
 , '[["'
   || replace(
         replace(
            review_list
          , ','
          , '"],["'
         )
       , ':'
       , '","'
      )
   || '"]]'
   as json_list
from customer_reviews
order by customer_id;

-- Listing 9-15. Parsing JSON with json_table

select
   cr.customer_id  as c_id
 , c.name          as cust_name
 , rl.product_id   as p_id
 , p.name          as prod_name
 , rl.score
from customer_reviews cr
cross apply json_table (
   '[["'
   || replace(
         replace(
            cr.review_list
          , ','
          , '"],["'
         )
       , ':'
       , '","'
      )
   || '"]]'
 , '$[*]'
   columns (
      product_id  number      path '$[0]'
    , score       varchar2(1) path '$[1]'
   )
) rl
join customers c
   on c.id = cr.customer_id
join products p
   on p.id = rl.product_id
order by cr.customer_id, rl.product_id;

-- Bonus: Using JSON objects instead of arrays

select
   cr.customer_id  as c_id
 , c.name          as cust_name
 , rl.product_id   as p_id
 , p.name          as prod_name
 , rl.score
from customer_reviews cr
cross apply json_table (
   nvl2(cr.review_list, '[{"p":', null)
   || replace(
         replace(
            replace(cr.review_list, ',', '|')
          , ':'
          , ',"r":"'
         )
       , '|'
       , '"},{"p":'
      )
   || nvl2(cr.review_list, '"}]', null)
 , '$[*]'
   columns (
      product_id  number      path '$.p'
    , score       varchar2(1) path '$.r'
   )
) rl
join customers c
   on c.id = cr.customer_id
join products p
   on p.id = rl.product_id
order by cr.customer_id, rl.product_id;

-- Bonus: Turning delimited text into XML

select
   customer_id
 , '<c>' || nvl2(review_list, '<o p="', null)
   || replace(
         replace(
            replace(review_list, ',', '|')
          , ':'
          , '" r="'
         )
       , '|'
       , '"/><o p="'
      )
   || nvl2(review_list, '"/>', null) || '</c>'
   as xml_list
from customer_reviews
order by customer_id;

-- Bonus: Parsing XML with xmltable

select
   cr.customer_id  as c_id
 , c.name          as cust_name
 , rl.product_id   as p_id
 , p.name          as prod_name
 , rl.score
from customer_reviews cr
outer apply xmltable (
   '/c/o'
   passing xmltype(
      '<c>' || nvl2(cr.review_list, '<o p="', null)
      || replace(
            replace(
               replace(cr.review_list, ',', '|')
             , ':'
             , '" r="'
            )
          , '|'
          , '"/><o p="'
         )
      || nvl2(cr.review_list, '"/>', null) || '</c>'
   )
   columns
      product_id  number      path '@p'
    , score       varchar2(1) path '@r'
) rl
join customers c
   on c.id = cr.customer_id
left outer join products p
   on p.id = rl.product_id
order by cr.customer_id, rl.product_id;

/* ***************************************************** */
