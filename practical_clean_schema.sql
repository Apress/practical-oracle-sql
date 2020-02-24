/* ***************************************************** **
   practical_clean_schema.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Drop objects in schema PRACTICAL
   Tables, data and other objects
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   Drop views
   ----------------------------------------------------- */

drop view customer_order_products_obj;
drop view customer_order_products;

drop package formulas;

drop view purchases_with_dims;

drop view brewery_products;

drop view total_sales;
drop view yearly_sales;

drop view inventory_with_dims;

drop view inventory_totals;
drop view monthly_orders;

drop view emp_hire_periods_with_name;

drop view web_page_counter_hist;

/* -----------------------------------------------------
   Drop packages, functions and procedures
   ----------------------------------------------------- */

drop view product_alcohol_bac;

drop function favorite_list_to_coll_type;

drop function stragg;
drop function name_coll_type_to_varchar2;

/* -----------------------------------------------------
   Drop types and type bodies
   ----------------------------------------------------- */

drop type id_name_coll_type force;
drop type id_name_type force;

drop type favorite_coll_type force;
drop type delimited_col_row force;

drop type stragg_type force;
drop type stragg_expr_type force;
drop type name_coll_type force;

/* -----------------------------------------------------
   Drop tables
   ----------------------------------------------------- */

drop table conway_gen_zero    cascade constraints purge;

drop table customer_favorites cascade constraints purge;
drop table customer_reviews   cascade constraints purge;

drop table product_alcohol    cascade constraints purge;

drop table web_devices        cascade constraints purge;
drop table web_demographics   cascade constraints purge;
drop table channels_dim       cascade constraints purge;
drop table gender_dim         cascade constraints purge;

drop table picking_log     cascade constraints purge;
drop table picking_line    cascade constraints purge;
drop table picking_list    cascade constraints purge;

drop table orderlines         cascade constraints purge;
drop table orders             cascade constraints purge;
drop table inventory          cascade constraints purge;
drop table locations          cascade constraints purge;
drop table customers          cascade constraints purge;

drop table purchases          cascade constraints purge;
drop table breweries          cascade constraints purge;

drop table monthly_budget     cascade constraints purge;
drop table product_minimums   cascade constraints purge;

drop table monthly_sales      cascade constraints purge;
drop table products           cascade constraints purge;
drop table product_groups     cascade constraints purge;

drop table packaging_relations   cascade constraints purge;
drop table packaging             cascade constraints purge;

drop table ticker             cascade constraints purge;
drop table stock              cascade constraints purge;

drop table server_heartbeat   cascade constraints purge;
drop table web_page_visits    cascade constraints purge;

drop table web_counter_hist   cascade constraints purge;
drop table web_pages          cascade constraints purge;
drop table web_apps           cascade constraints purge;

drop table emp_hire_periods   cascade constraints purge;

drop table employees          cascade constraints purge;

-- Everything is now dropped

/* ***************************************************** */
