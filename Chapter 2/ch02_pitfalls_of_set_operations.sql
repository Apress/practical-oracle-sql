/* ***************************************************** **
   ch02_pitfalls_of_set_operations.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 2
   Pitfalls of Set Operations
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

-- Unlike most other chapters, this chapter manually formats
-- columns instead of using sqlformat ansiconsole

set pagesize 80
set linesize 80
set sqlformat
alter session set nls_date_format = 'YYYY-MM-DD';

column c_id          format 99999
column customer_name format a15
column b_id          format 99999
column brewery_name  format a18
column p_id          format 9999
column product_name  format a17
column c_or_b_id     format 99999
column c_or_b_name   format a18
column ordered       format a10
column qty           format 999
column product_coll  format a40
column multiset_coll format a60
column rn            format 9

/* -----------------------------------------------------
   Chapter 2 example code
   ----------------------------------------------------- */

-- Listing 2-2. Data for two customers and their orders

select
   customer_id as c_id, customer_name, ordered
 , product_id  as p_id, product_name , qty
from customer_order_products
where customer_id in (50042, 50741)
order by customer_id, product_id;

-- Listing 2-3. Data for two breweries and the products bought from them

select
   brewery_id as b_id, brewery_name
 , product_id as p_id, product_name
from brewery_products
where brewery_id in (518, 523)
order by brewery_id, product_id;

-- Listing 2-4. Concatenating the results of two queries

select product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
union all
select product_id as p_id, product_name
from brewery_products
where brewery_id = 523;

-- Listing 2-5. Different columns from the two queries

select
   customer_id as c_or_b_id, customer_name as c_or_b_name
 , product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
union all
select
   brewery_id, brewery_name
 , product_id as p_id, product_name
from brewery_products
where brewery_id = 523;

-- Attempting to order by a table column leads to ORA-00904: "PRODUCT_ID": invalid identifier

select
   customer_id as c_or_b_id, customer_name as c_or_b_name
 , product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
union all
select
   brewery_id, brewery_name
 , product_id as p_id, product_name
from brewery_products
where brewery_id = 523
order by product_id;

-- Ordering by column alias works

select
   customer_id as c_or_b_id, customer_name as c_or_b_name
 , product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
union all
select
   brewery_id, brewery_name
 , product_id as p_id, product_name
from brewery_products
where brewery_id = 523
order by p_id;

-- Listing 2-6. Union is a true set operation that implicitly performs a distinct of the query result

select product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
union
select product_id as p_id, product_name
from brewery_products
where brewery_id = 523
order by p_id;

-- Where union is the distinct joined results, intersect is the distinct common results

select product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
intersect
select product_id as p_id, product_name
from brewery_products
where brewery_id = 523
order by p_id;

-- Minus is the set subtraction - also known as except

select product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
minus
select product_id as p_id, product_name
from brewery_products
where brewery_id = 523
order by p_id;

-- Listing 2-7. The customer product data viewed as a collection type

select
   customer_id as c_id, customer_name
 , product_coll
from customer_order_products_obj
where customer_id in (50042, 50741)
order by customer_id;

-- Listing 2-8. Doing union as a multiset operation on the collections

select
   whitehart.product_coll
   multiset union
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- Multiset union all is the same as multiset union

select
   whitehart.product_coll
   multiset union all
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- Multiset union distinct exists too

select
   whitehart.product_coll
   multiset union distinct
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- For multiset an intersect all is possible

select
   whitehart.product_coll
   multiset intersect all
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- As well as an intersect distinct

select
   whitehart.product_coll
   multiset intersect distinct
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- Naturally there is an except all as well

select
   whitehart.product_coll
   multiset except all
   hyggehumle.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- More interesting results of the reversed except all

select
   hyggehumle.product_coll
   multiset except all
   whitehart.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- Except distinct result shows distinct is performed before set subtraction

select
   hyggehumle.product_coll
   multiset except distinct
   whitehart.product_coll
      as multiset_coll
from customer_order_products_obj whitehart
cross join customer_order_products_obj hyggehumle
where whitehart.customer_id = 50042
and hyggehumle.customer_id = 50741;

-- Listing 2-9. Minus is like multiset except distinct

select product_id as p_id, product_name
from customer_order_products
where customer_id = 50741
minus
select product_id as p_id, product_name
from customer_order_products
where customer_id = 50042
order by p_id;

-- Listing 2-10. Emulating minus all using multiset except all

select
   minus_all_table.id   as p_id
 , minus_all_table.name as product_name
from table(
   cast(
      multiset(
         select product_id, product_name
         from customer_order_products
         where customer_id = 50741
      )
      as id_name_coll_type
   )
   multiset except all
   cast(
      multiset(
         select product_id, product_name
         from customer_order_products
         where customer_id = 50042
      )
      as id_name_coll_type
   )
) minus_all_table
order by p_id;

-- Listing 2-11. Emulating minus all using analytic row_number function

select
   product_id as p_id
 , product_name
 , row_number() over (
      partition by product_id, product_name
      order by rownum
   ) as rn
from customer_order_products
where customer_id = 50741
minus
select
   product_id as p_id
 , product_name
 , row_number() over (
      partition by product_id, product_name
      order by rownum
   ) as rn
from customer_order_products
where customer_id = 50042
order by p_id;

/* ***************************************************** */
