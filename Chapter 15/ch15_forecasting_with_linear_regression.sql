/* ***************************************************** **
   ch15_forecasting_with_linear_regression.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 15
   Forecasting with Linear Regression
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

-- Unlike most other chapters, this chapter manually formats
-- columns instead of using sqlformat ansiconsole

set pagesize 100
set linesize 100
set sqlformat
alter session set nls_date_format = 'YYYY-MM';
alter session set nls_numeric_characters = '.,';

column product_id format a4
column mth        format a7
column ts         format 99
column yr         format 9999
column mthno      format 9999
column qty        format 999
column cma        format 99D9
column s          format 0D9999
column des        format 999D9
column t          format 99D9
column forecast   format 999D9

/* -----------------------------------------------------
   Chapter 15 example code
   ----------------------------------------------------- */

-- Listing 15-1. The two products for showing forecasting

select id, name
from products
where id in (4160, 7790);

-- The sales of 2016-2018 for the two beers pivoted to two columns

select *
from (
   select product_id, mth, qty
   from monthly_sales
   where product_id in (4160, 7790)
)
pivot (
   sum(qty)
   for product_id in (
      4160 as reindeer_fuel
    , 7790 as summer_in_india
   )
)
order by mth;

-- Listing 15-2. Building time series 2016-2019 for the two beers

select
   ms.product_id
 , mths.mth
 , mths.ts
 , extract(year from mths.mth) as yr
 , extract(month from mths.mth) as mthno
 , ms.qty
from (
   select
      add_months(date '2016-01-01', level - 1) as mth
    , level as ts --time series
   from dual
   connect by level <= 48
) mths
left outer join (
   select product_id, mth, qty
   from monthly_sales
   where product_id in (4160, 7790)
) ms
   partition by (ms.product_id)
   on  ms.mth = mths.mth
order by ms.product_id, mths.mth;

-- Listing 15-3. Calculating centered moving average

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
)
select
   product_id, mth, ts, yr, mthno, qty
 , case
      when ts between 7 and 30 then
         (nvl(avg(qty) over (
            partition by product_id
            order by ts
            rows between 5 preceding and 6 following
         ), 0) + nvl(avg(qty) over (
            partition by product_id
            order by ts
            rows between 6 preceding and 5 following
         ), 0)) / 2
      else
         null
   end as cma -- centered moving average
from s1
order by product_id, mth;

-- Listing 15-4. Calculating seasonality factor

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
), s2 as (
   select
      product_id, mth, ts, yr, mthno, qty
    , case
         when ts between 7 and 30 then
            (nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 5 preceding and 6 following
            ), 0) + nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 6 preceding and 5 following
            ), 0)) / 2
         else
            null
      end as cma -- centered moving average
   from s1
)
select
   product_id, mth, ts, yr, mthno, qty, cma
 , nvl(avg(
      case qty
         when 0 then 0.0001
         else qty
      end / nullif(cma, 0)
   ) over (
      partition by product_id, mthno
   ),0) as s -- seasonality
from s2
order by product_id, mth;

-- Listing 15-5. Deseasonalizing sales data

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
), s2 as (
   select
      product_id, mth, ts, yr, mthno, qty
    , case
         when ts between 7 and 30 then
            (nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 5 preceding and 6 following
            ), 0) + nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 6 preceding and 5 following
            ), 0)) / 2
         else
            null
      end as cma -- centered moving average
   from s1
), s3 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma
    , nvl(avg(
         case qty
            when 0 then 0.0001
            else qty
         end / nullif(cma, 0)
      ) over (
         partition by product_id, mthno
      ), 0) as s -- seasonality
   from s2
)
select
   product_id, mth, ts, yr, mthno, qty, cma, s
 , case when ts <= 36 then
      nvl(
         case qty
            when 0 then 0.0001
            else qty
         end / nullif(s, 0)
       , 0)
   end as des -- deseasonalized
from s3
order by product_id, mth;

-- Listing 15-6. Calculating trend line

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
), s2 as (
   select
      product_id, mth, ts, yr, mthno, qty
    , case
         when ts between 7 and 30 then
            (nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 5 preceding and 6 following
            ), 0) + nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 6 preceding and 5 following
            ), 0)) / 2
         else
            null
      end as cma -- centered moving average
   from s1
), s3 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma
    , nvl(avg(
         case qty
            when 0 then 0.0001
            else qty
         end / nullif(cma, 0)
      ) over (
         partition by product_id, mthno
      ), 0) as s -- seasonality
   from s2
), s4 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma, s
    , case when ts <= 36 then
         nvl(
            case qty
               when 0 then 0.0001
               else qty
            end / nullif(s, 0)
          , 0)
      end as des -- deseasonalized
   from s3
)
select
   product_id, mth, ts, yr, mthno, qty, cma, s, des
 , regr_intercept(des, ts) over (
      partition by product_id
   ) + ts * regr_slope(des, ts) over (
               partition by product_id
            ) as t -- trend
from s4
order by product_id, mth;

-- Listing 15-7. Reseasonalizing trend => forecast

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
), s2 as (
   select
      product_id, mth, ts, yr, mthno, qty
    , case
         when ts between 7 and 30 then
            (nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 5 preceding and 6 following
            ), 0) + nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 6 preceding and 5 following
            ), 0)) / 2
         else
            null
      end as cma -- centered moving average
   from s1
), s3 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma
    , nvl(avg(
         case qty
            when 0 then 0.0001
            else qty
         end / nullif(cma, 0)
      ) over (
         partition by product_id, mthno
      ), 0) as s -- seasonality
   from s2
), s4 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma, s
    , case when ts <= 36 then
         nvl(
            case qty
               when 0 then 0.0001
               else qty
            end / nullif(s, 0)
          , 0)
      end as des -- deseasonalized
   from s3
), s5 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma, s, des
    , regr_intercept(des, ts) over (
         partition by product_id
      ) + ts * regr_slope(des, ts) over (
                  partition by product_id
               ) as t -- trend
   from s4
)
select
   product_id, mth, ts, yr, mthno, qty, cma, s, des
 , t * s as forecast --reseasonalized
from s5
order by product_id, mth;

-- Listing 15-8. Selecting actual and forecast

with s1 as (
   select
      ms.product_id
    , mths.mth
    , mths.ts
    , extract(year from mths.mth) as yr
    , extract(month from mths.mth) as mthno
    , ms.qty
   from (
      select
         add_months(date '2016-01-01', level - 1) as mth
       , level as ts --time series
      from dual
      connect by level <= 48
   ) mths
   left outer join (
      select product_id, mth, qty
      from monthly_sales
      where product_id in (4160, 7790)
   ) ms
      partition by (ms.product_id)
      on  ms.mth = mths.mth
), s2 as (
   select
      product_id, mth, ts, yr, mthno, qty
    , case
         when ts between 7 and 30 then
            (nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 5 preceding and 6 following
            ), 0) + nvl(avg(qty) over (
               partition by product_id
               order by ts
               rows between 6 preceding and 5 following
            ), 0)) / 2
         else
            null
      end as cma -- centered moving average
   from s1
), s3 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma
    , nvl(avg(
         case qty
            when 0 then 0.0001
            else qty
         end / nullif(cma, 0)
      ) over (
         partition by product_id, mthno
      ), 0) as s -- seasonality
   from s2
), s4 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma, s
    , case when ts <= 36 then
         nvl(
            case qty
               when 0 then 0.0001
               else qty
            end / nullif(s, 0)
          , 0)
      end as des -- deseasonalized
   from s3
), s5 as (
   select
      product_id, mth, ts, yr, mthno, qty, cma, s, des
    , regr_intercept(des, ts) over (
         partition by product_id
      ) + ts * regr_slope(des, ts) over (
                  partition by product_id
               ) as t -- trend
   from s4
)
select
   product_id
 , mth
 , case
      when ts <= 36 then qty
      else round(t * s)
   end as qty
 , case
      when ts <= 36 then 'Actual'
      else 'Forecast'
   end as type
from s5
order by product_id, mth;

/* ***************************************************** */
