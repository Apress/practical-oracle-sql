/* ***************************************************** **
   ch20_finding_abnormal_peaks.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 20
   Finding Abnormal Peaks
   
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
   Chapter 20 example code
   ----------------------------------------------------- */

-- Listing 20-2. The pages in my webshop app

select
   p.app_id
 , a.name as app_name
 , p.page_no
 , p.friendly_url
from web_apps a
join web_pages p
   on p.app_id = a.id
order by p.app_id, p.page_no;

-- Listing 20-3. Web page counter history data

select
   friendly_url, day, counter
from web_page_counter_hist
where app_id = 542
order by page_no, day;

-- Listing 20-4. Recognizing days where counter grew by at least 200

select
   url, from_day, to_day, days, begin, growth, daily
from web_page_counter_hist
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , last(day) as to_day
    , count(*) as days
    , first(counter) as begin
    , next(counter) - first(counter) as growth
    , (next(counter) - first(counter)) / count(*)
         as daily
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as next(counter) - counter >= 200
)
order by page_no, from_day;

-- Explicitly using final and last

select
   url, from_day, to_day, days, begin, growth, daily
from web_page_counter_hist
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , next(final last(counter)) - first(counter) as growth
    , (next(final last(counter)) - first(counter))
         / final count(*) as daily
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as next(counter) - counter >= 200
)
order by page_no, from_day;

-- Listing 20-5. Recognizing days where counter grew by at least 4 percent

select
   url, from_day, to_day, days, begin, pct, daily
from web_page_counter_hist
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , round(
         100 * (next(final last(counter)) / first(counter))
             - 100
       , 1
      ) as pct
    , round(
         (100 * (next(final last(counter)) / first(counter))
                  - 100) / final count(*)
       , 1
      ) as daily
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as next(counter) / counter >= 1.04
)
order by page_no, from_day;

-- Periods where counter grew by by at least 4% on average per day

select
   url, from_day, to_day, days, begin, pct, daily
from web_page_counter_hist
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , round(
         100 * (next(final last(counter)) / first(counter))
             - 100
       , 1
      ) as pct
    , round(
         (100 * (next(final last(counter)) / first(counter))
                  - 100) / final count(*)
       , 1
      ) as daily
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as ((next(counter) / first(counter)) - 1)
                 / running count(*)  >= 0.04
)
order by page_no, from_day;

-- Listing 20-6. Focusing on daily visits

select
   friendly_url, day
 , lead(counter) over (
      partition by page_no order by day
   ) - counter as visits
from web_page_counter_hist
order by page_no, day;

-- Listing 20-7. Daily visits at least 50 higher than previous day

select
   url, from_day, to_day, days, begin, p_v, f_v, t_v, d_v
from web_page_counter_hist
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , first(counter) - prev(first(counter)) as p_v
    , next(first(counter)) - first(counter) as f_v
    , next(final last(counter)) - first(counter) as t_v
    , round(
         (next(final last(counter)) - first(counter))
            / final count(*)
       , 1
      ) as d_v
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as next(counter) - counter
               - (first(counter) - prev(first(counter))) >= 50
)
order by page_no, from_day;

-- Listing 20-8. Pre-calculating visits for simplifying code

select
   url, from_day, to_day, days, begin, p_v, f_v, t_v, d_v
from (
   select
      page_no, friendly_url, day, counter
    , lead(counter) over (
         partition by page_no order by day
      ) - counter as visits
   from web_page_counter_hist
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , prev(first(visits)) as p_v
    , first(visits) as f_v
    , final sum(visits) as t_v
    , round(final avg(visits)) as d_v
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as visits - prev(first(visits)) >= 50
)
order by page_no, from_day;

-- Listing 20-9. Daily visits at least 50% higher than previous day

select
   url, from_day, to_day, days, begin, p_v, f_v, t_v, d_pct
from (
   select
      page_no, friendly_url, day, counter
    , lead(counter) over (
         partition by page_no order by day
      ) - counter as visits
   from web_page_counter_hist
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , first(counter) as begin
    , prev(first(visits)) as p_v
    , first(visits) as f_v
    , final sum(visits) as t_v
    , round(
         (100*(final sum(visits) / prev(first(visits))) - 100)
            / final count(*)
       , 1
      ) as d_pct
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as visits / nullif(prev(first(visits)), 0) >= 1.5
)
order by page_no, from_day;

-- Listing 20-10. Daily visits at least 50% higher than average

select
   url, avg_v, from_day, to_day, days, t_v, d_v, d_pct
from (
   select
      page_no, friendly_url, day, counter, visits
    , avg(visits) over (
         partition by page_no
      ) as avg_visits
   from (
      select
         page_no, friendly_url, day, counter
       , lead(counter) over (
            partition by page_no order by day
         ) - counter as visits
      from web_page_counter_hist
   )
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , round(first(avg_visits), 1) as avg_v
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , final sum(visits) as t_v
    , round(final avg(visits), 1) as d_v
    , round(
         (100 * final avg(visits) / avg_visits) - 100
       , 1
      ) as d_pct
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as visits / avg_visits >= 1.5
)
order by page_no, from_day;

-- Daily visits at least 80% less than average

select
   url, avg_v, from_day, to_day, days, t_v, d_v, d_pct
from (
   select
      page_no, friendly_url, day, counter, visits
    , avg(visits) over (
         partition by page_no
      ) as avg_visits
   from (
      select
         page_no, friendly_url, day, counter
       , lead(counter) over (
            partition by page_no order by day
         ) - counter as visits
      from web_page_counter_hist
   )
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , round(first(avg_visits), 1) as avg_v
    , first(day) as from_day
    , final last(day) as to_day
    , final count(*) as days
    , final sum(visits) as t_v
    , round(final avg(visits), 1) as d_v
    , round(
         (100 * final avg(visits) / avg_visits) - 100
       , 1
      ) as d_pct
   one row per match
   after match skip past last row
   pattern ( peak+ )
   define
      peak as visits / avg_visits <= 0.2
)
order by page_no, from_day;

-- Listing 20-11. Finding multiple peak classifications simultaneously

select
   url, avg_v, from_day, days, class, t_v, d_v, d_pct
from (
   select
      page_no, friendly_url, day, counter, visits
    , avg(visits) over (
         partition by page_no
      ) as avg_visits
   from (
      select
         page_no, friendly_url, day, counter
       , lead(counter) over (
            partition by page_no order by day
         ) - counter as visits
      from web_page_counter_hist
   )
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , round(first(avg_visits), 1) as avg_v
    , first(day) as from_day
    , final count(*) as days
    , classifier() as class
    , final sum(visits) as t_v
    , round(final avg(visits), 1) as d_v
    , round(
         (100 * final avg(visits) / avg_visits) - 100
       , 1
      ) as d_pct
   one row per match
   after match skip past last row
   pattern ( high{1,} | medium{2,} | low{3,} )
   define
      high   as visits / avg_visits >= 4
    , medium as visits / avg_visits >= 2
    , low    as visits / avg_visits >= 1.1
)
order by page_no, from_day;

-- Listing 20-12. Finding peaks of a particular shape

select
   url, avg_v, from_day, days, hi, med, low, t_v, d_v, d_pct
from (
   select
      page_no, friendly_url, day, counter, visits
    , avg(visits) over (
         partition by page_no
      ) as avg_visits
   from (
      select
         page_no, friendly_url, day, counter
       , lead(counter) over (
            partition by page_no order by day
         ) - counter as visits
      from web_page_counter_hist
   )
)
match_recognize(
   partition by page_no
   order by day
   measures
      first(friendly_url) as url
    , round(first(avg_visits), 1) as avg_v
    , first(day) as from_day
    , final count(*) as days
    , final count(high.*) as hi
    , final count(medium.*) as med
    , final count(low.*) as low
    , final sum(visits) as t_v
    , round(final avg(visits), 1) as d_v
    , round(
         (100 * final avg(visits) / avg_visits) - 100
       , 1
      ) as d_pct
   one row per match
   after match skip past last row
   pattern ( high+ medium+ low+ )
   define
      high   as visits / avg_visits >= 2.5
    , medium as visits / avg_visits >= 1.5
    , low    as visits / avg_visits >= 1.1
)
order by page_no, from_day;

/* ***************************************************** */
