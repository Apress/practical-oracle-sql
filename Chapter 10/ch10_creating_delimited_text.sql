/* ***************************************************** **
   ch10_creating_delimited_text.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 10
   Creating Delimited Text
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole
set long 8000

/* -----------------------------------------------------
   Chapter 10 example code
   ----------------------------------------------------- */

-- Listing 10-2. The breweries and products

select *
from brewery_products
order by brewery_id, product_id;

-- Listing 10-3. Using listagg to create product list

select
   max(brewery_name) as brewery_name
 , listagg(product_name, ',') within group (
      order by product_id
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Changing order of the list

select
   max(brewery_name) as brewery_name
 , listagg(product_name, ',') within group (
      order by product_name
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Listing 10-5. Using collect and the created function

select
   max(brewery_name) as brewery_name
 , name_coll_type_to_varchar2(
      cast(
         collect(
            product_name
            order by product_id
         )
         as name_coll_type
      ) 
    , ','
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Alternative using generic apex_t_varchar2 and apex_string.join

select
   max(brewery_name) as brewery_name
 , apex_string.join(
      cast(
         collect(
            product_name
            order by product_id
         )
         as apex_t_varchar2
      ) 
    , ','
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Listing 10-7. Using stragg custom aggregate function

select
   max(brewery_name) as brewery_name
 , stragg(
      stragg_expr_type(product_name, ',')
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Using unnecessary distinct can get lucky and get ordered result

select
   max(brewery_name) as brewery_name
 , stragg(
      distinct stragg_expr_type(product_name, ',')
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Listing 10-8. Using xmlagg and extract text from xml

select
   max(brewery_name) as brewery_name
 , rtrim(
      xmlagg(
         xmlelement(z, product_name, ',')
         order by product_id
      ).extract('//text()').getstringval()
    , ','
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Skip extraction by claiming content is xml

select
   max(brewery_name) as brewery_name
 , rtrim(
      xmlagg(
         xmlparse(content product_name || ',' wellformed)
         order by product_id
      ).getstringval()
    , ','
   ) as product_list
from brewery_products
group by brewery_id
order by brewery_id;

-- Listing 10-9. Getting ORA-01489 with listagg

select
   listagg(rpad(p.name, 20)) within group (
      order by p.id
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Listing 10-10. Suppressing error in listagg

select
   listagg(
      rpad(p.name, 20)
      on overflow truncate '{more}' with count
   ) within group (
      order by p.id
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Listing 10-11. Reducing data with distinct

select
   listagg(distinct rpad(p.name, 20)) within group (
      order by p.id
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Bonus: Un-ordered pre-19c version using stragg

select
   stragg(
      distinct stragg_expr_type(rpad(p.name, 20), null)
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Listing 10-12. Using xmlagg to aggregate to a clob

select
   xmlagg(
      xmlparse(
         content rpad(p.name, 20) wellformed
      )
      order by p.id
   ).getclobval() as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Listing 10-13. Using json_arrayagg to aggregate to a clob

select
   json_value(
      replace(
         json_arrayagg(
            rpad(p.name, 20)
            order by p.id
            returning clob
         )
       , '","'
       , ''
      )
    , '$[0]' returning clob
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

-- Listing 10-14. Using apex_string.join_clob to aggregate to a clob

select
   apex_string.join_clob(
      cast(
         collect(
            rpad(p.name, 20)
            order by p.id
         )
         as apex_t_varchar2
      )
    , ''
    , 12 /* dbms_lob.call */
   ) as product_list
from products p
join monthly_sales ms
   on ms.product_id = p.id;

/* ***************************************************** */
