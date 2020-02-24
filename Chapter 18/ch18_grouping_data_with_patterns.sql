/* ***************************************************** **
   ch18_grouping_data_with_patterns.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 18
   Grouping Data with Patterns
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';

/* -----------------------------------------------------
   Chapter 18 example code
   ----------------------------------------------------- */

-- Listing 18-1. Difference between value and row_number

with ints(i) as (
   select 1 from dual union all
   select 2 from dual union all
   select 3 from dual union all
   select 6 from dual union all
   select 8 from dual union all
   select 9 from dual
)
select
   i
 , row_number() over (order by i)     as rn
 , i - row_number() over (order by i) as diff
from ints
order by i;

-- Listing 18-2. Tabibitosan grouping

with ints(i) as (
   select 1 from dual union all
   select 2 from dual union all
   select 3 from dual union all
   select 6 from dual union all
   select 8 from dual union all
   select 9 from dual
)
select
   min(i)   as first_int
 , max(i)   as last_int
 , count(*) as ints_in_grp
from (
   select i, i - row_number() over (order by i) as diff
   from ints
)
group by diff
order by first_int;

-- Listing 18-3. Same grouping with match_recognize

with ints(i) as (
   select 1 from dual union all
   select 2 from dual union all
   select 3 from dual union all
   select 6 from dual union all
   select 8 from dual union all
   select 9 from dual
)
select first_int, last_int, ints_in_grp
from ints
match_recognize (
   order by i
   measures
      first(i) as first_int
    , last(i)  as last_int
    , count(*) as ints_in_grp
   one row per match
   pattern (strt one_higher*)
   define
      one_higher as i = prev(i) + 1
)
order by first_int;

-- Listing 18-4. Server heartbeat as example of something other than integers

select server, beat_time
from server_heartbeat
order by server, beat_time;

-- Listing 18-5. Tabibitosan adjusted to 5 minute intervals

select
   server
 , min(beat_time) as first_beat
 , max(beat_time) as last_beat
 , count(*)       as beats
from (
   select
      server
    , beat_time
    , beat_time - interval '5' minute
                * row_number() over (
                     partition by server
                     order by beat_time
                  ) as diff
   from server_heartbeat
)
group by server, diff
order by server, first_beat;

-- Listing 18-6. Same adjustment to match_recognize solution

select server, first_beat, last_beat, beats
from server_heartbeat
match_recognize (
   partition by server
   order by beat_time
   measures
      first(beat_time) as first_beat
    , last(beat_time)  as last_beat
    , count(*)         as beats
   one row per match
   pattern (strt five_mins_later*)
   define
      five_mins_later as
         beat_time = prev(beat_time) + interval '5' minute
)
order by server, first_beat;

-- Allowing for "fuzzy" intervals

select server, first_beat, last_beat, beats
from server_heartbeat
match_recognize (
   partition by server
   order by beat_time
   measures
      first(beat_time) as first_beat
    , last(beat_time)  as last_beat
    , count(*)         as beats
   one row per match
   pattern (strt five_mins_later*)
   define
      five_mins_later as
         beat_time between prev(beat_time) + interval '4' minute
                       and prev(beat_time) + interval '6' minute
)
order by server, first_beat;

-- Listing 18-7. Detecting gaps from consecutive grouping using lead function

select
   server, last_beat, next_beat
 , round((next_beat - last_beat) * (24*60)) as gap_minutes
from (
   select
      server
    , last_beat
    , lead(first_beat) over (
         partition by server order by first_beat
      ) as next_beat
   from (
      select server, first_beat, last_beat, beats
      from server_heartbeat
      match_recognize (
         partition by server
         order by beat_time
         measures
            first(beat_time) as first_beat
          , last(beat_time)  as last_beat
          , count(*)         as beats
         one row per match
         pattern (strt five_mins_later*)
         define
            five_mins_later as
               beat_time = prev(beat_time) + interval '5' minute
      )
   )
)
where next_beat is not null
order by server, last_beat;

-- Listing 18-8. Detecting gaps directly in match_recognize

select
   server, last_beat, next_beat
 , round((next_beat - last_beat) * (24*60)) as gap_minutes
from server_heartbeat
match_recognize (
   partition by server
   order by beat_time
   measures
      last(before_gap.beat_time) as last_beat
    , next_after_gap.beat_time   as next_beat
   one row per match
   after match skip to last next_after_gap
   pattern (strt five_mins_later* next_after_gap)
   subset before_gap = (strt, five_mins_later)
   define
      five_mins_later as
         beat_time = prev(beat_time) + interval '5' minute
    , next_after_gap as
         beat_time > prev(beat_time) + interval '5' minute
)
order by server, last_beat;

-- Listing 18-9. Web page visit data

select app_id, visit_time, client_ip, page_no
from web_page_visits
order by app_id, visit_time, client_ip;

-- Listing 18-10. Data belongs to same group (session) as long as max 15 minutes between page visits

select app_id, first_visit, last_visit, visits, client_ip
from web_page_visits
match_recognize (
   partition by app_id, client_ip
   order by visit_time
   measures
      first(visit_time) as first_visit
    , last(visit_time)  as last_visit
    , count(*)          as visits
   one row per match
   pattern (strt within_15_mins*)
   define
      within_15_mins as
         visit_time <= prev(visit_time) + interval '15' minute
)
order by app_id, first_visit, client_ip;

-- Reversing the logic to look ahead instead of looking behind

select app_id, first_visit, last_visit, visits, client_ip
from web_page_visits
match_recognize (
   partition by app_id, client_ip
   order by visit_time
   measures
      first(visit_time) as first_visit
    , last(visit_time)  as last_visit
    , count(*)          as visits
   one row per match
   pattern (has_15_mins_to_next* last_time)
   define
      has_15_mins_to_next as
         visit_time + interval '15' minute >= next(visit_time)
)
order by app_id, first_visit, client_ip;

-- Listing 18-11. Sessions max one hour long since first page visit

select app_id, first_visit, last_visit, visits, client_ip
from web_page_visits
match_recognize (
   partition by app_id, client_ip
   order by visit_time
   measures
      first(visit_time) as first_visit
    , last(visit_time)  as last_visit
    , count(*)          as visits
   one row per match
   pattern (same_hour+)
   define
      same_hour as
         visit_time <= first(visit_time) + interval '1' hour
)
order by app_id, first_visit, client_ip;

/* ***************************************************** */
