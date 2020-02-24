/* ***************************************************** **
   ch05_functions_defined_within_sql.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 5
   Functions Defined Within SQL
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 6 example code
   ----------------------------------------------------- */

-- Listing 5-1. The alcohol data for the beers in the Stout product group

select
   p.id as p_id
 , p.name
 , pa.sales_volume as vol
 , pa.abv
from products p
join product_alcohol pa
   on pa.product_id = p.id
where p.group_id = 142
order by p.id;

-- Listing 5-2. Calculating blood alcohol concentration for male and female

select
   p.id as p_id
 , p.name
 , pa.sales_volume as vol
 , pa.abv
 , round(
      100 * (pa.sales_volume * pa.abv / 100 * 0.789)
       / (80 * 1000 * 0.68)
    , 3
   ) bac_m
 , round(
      100 * (pa.sales_volume * pa.abv / 100 * 0.789)
       / (60 * 1000 * 0.55)
    , 3
   ) bac_f
from products p
join product_alcohol pa
   on pa.product_id = p.id
where p.group_id = 142
order by p.id;

-- Listing 5-4. Querying male and female BAC using packaged formula

select
   p.id as p_id
 , p.name
 , pa.sales_volume as vol
 , pa.abv
 , formulas.bac(pa.sales_volume, pa.abv, 80, 'M') bac_m
 , formulas.bac(pa.sales_volume, pa.abv, 60, 'F') bac_f
from products p
join product_alcohol pa
   on pa.product_id = p.id
where p.group_id = 142
order by p.id;

-- Listing 5-5. Querying BAC with a function in the with clause

with
   function bac (
      p_volume in number
    , p_abv    in number
    , p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
   begin
      return round(
         100 * (p_volume * p_abv / 100 * 0.789)
          / (p_weight * 1000 * case p_gender
                                  when 'M' then 0.68
                                  when 'F' then 0.55
                               end)
       , 3
      );
   end;
select
   p.id as p_id
 , p.name
 , pa.sales_volume as vol
 , pa.abv
 , bac(pa.sales_volume, pa.abv, 80, 'M') bac_m
 , bac(pa.sales_volume, pa.abv, 60, 'F') bac_f
from products p
join product_alcohol pa
   on pa.product_id = p.id
where p.group_id = 142
order by p.id
/

-- Listing 5-6. Having multiple functions in one with clause

with
   function gram_alcohol (
      p_volume in number
    , p_abv    in number
   ) return number deterministic
   is
   begin
      return p_volume * p_abv / 100 * 0.789;
   end;
   function gram_body_fluid (
      p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
   begin
      return p_weight * 1000 * case p_gender
                                  when 'M' then 0.68
                                  when 'F' then 0.55
                               end;
   end;
   function bac (
      p_volume in number
    , p_abv    in number
    , p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
   begin
      return round(
         100 * gram_alcohol(p_volume, p_abv)
          / gram_body_fluid(p_weight, p_gender)
       , 3
      );
   end;
select
   p.id as p_id
 , p.name
 , pa.sales_volume as vol
 , pa.abv
 , bac(pa.sales_volume, pa.abv, 80, 'M') bac_m
 , bac(pa.sales_volume, pa.abv, 60, 'F') bac_f
from products p
join product_alcohol pa
   on pa.product_id = p.id
where p.group_id = 142
order by p.id
/

-- Listing 5-8. Querying BAC data using the view

select
   p.id as p_id
 , p.name
 , pab.sales_volume as vol
 , pab.abv
 , pab.bac_m
 , pab.bac_f
from products p
join product_alcohol_bac pab
   on pab.product_id = p.id
where p.group_id = 142
order by p.id;

/* ***************************************************** */
