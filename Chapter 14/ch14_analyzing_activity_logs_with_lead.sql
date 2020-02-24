/* ***************************************************** **
   ch14_analyzing_activity_logs_with_lead.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 14
   Analyzing Activity Logs with Lead
   
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
   Chapter 14 example code
   ----------------------------------------------------- */

-- Listing 14-1. Content of the activity log for picking lists

select
   list.picker_emp_id as emp
 , list.id            as list
 , log.log_time
 , log.activity       as act
 , log.location_id    as loc
 , log.pickline_no    as line
from picking_list list
join picking_log log
   on log.picklist_id = list.id
order by list.id, log.log_time;

-- Listing 14-2. Departures and arrivals with lead function calls

select
   list.picker_emp_id as emp
 , list.id            as list
 , log.log_time
 , log.activity       as act
 , log.location_id    as loc
 , to_char(
      lead(log_time) over (
         partition by list.id
         order by log.log_time
      )
    , 'HH24:MI:SS'
   ) as next_time
 , to_char(
      lead(log_time, 2) over (
         partition by list.id
         order by log.log_time
      )
    , 'HH24:MI:SS'
   ) as next2_time
from picking_list list
join picking_log log
   on log.picklist_id = list.id
where log.activity in ('D', 'A')
order by list.id, log.log_time;

-- Listing 14-3. Depart – Arrive – Depart cycles

select
   emp, list
 , log_time as depart
 , to_char(next_time , 'HH24:MI:SS') as arrive
 , to_char(next2_time, 'HH24:MI:SS') as next_depart
 , round((next_time  - log_time )*(24*60*60)) as drive
 , round((next2_time - next_time)*(24*60*60)) as work
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , log.log_time
    , log.activity       as act
    , lead(log_time) over (
         partition by list.id
         order by log.log_time
      ) as next_time
    , lead(log_time, 2) over (
         partition by list.id
         order by log.log_time
      ) as next2_time
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
   where log.activity in ('D', 'A')
)
where act = 'D'
order by list, log_time;

-- Listing 14-4. Statistics per picking list

select
   max(emp) as emp
 , list
 , min(log_time) as begin
 , to_char(max(next_time), 'HH24:MI:SS') as end
 , count(*) as drives
 , round(
      avg((next_time - log_time )*(24*60*60))
    , 1
   ) as avg_d
 , count(next2_time) as stops
 , round(
      avg((next2_time  - next_time)*(24*60*60))
    , 1
   ) as avg_w
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , log.log_time
    , log.activity       as act
    , lead(log_time) over (
         partition by list.id
         order by log.log_time
      ) as next_time
    , lead(log_time, 2) over (
         partition by list.id
         order by log.log_time
      ) as next2_time
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
   where log.activity in ('D', 'A')
)
where act = 'D'
group by list
order by list;

-- Listing 14-5. Including picking activity

select
   emp, list
 , to_char(depart, 'HH24:MI:SS') as depart
 , to_char(arrive, 'HH24:MI:SS') as arrive
 , to_char(pick1 , 'HH24:MI:SS') as pick1
 , to_char(
      case when pick2 < next_depart then pick2 end
    , 'HH24:MI:SS'
   ) as pick2
 , to_char(next_depart, 'HH24:MI:SS') as next_dep
 , round((arrive      - depart)*(24*60*60)) as drv
 , round((next_depart - arrive)*(24*60*60)) as wrk
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , log.activity       as act
    , log.log_time       as depart
    , lead(log_time) over (
         partition by list.id
         order by log.log_time
      ) as arrive
    , lead(
         case log.activity when 'P' then log_time end
      ) ignore nulls over (
         partition by list.id
         order by log.log_time
      ) as pick1
    , lead(
         case log.activity when 'P' then log_time end, 2
      ) ignore nulls over (
         partition by list.id
         order by log.log_time
      ) as pick2
    , lead(
         case log.activity when 'D' then log_time end
      ) ignore nulls over (
         partition by list.id
         order by log.log_time
      ) as next_depart
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
)
where act = 'D'
order by list, depart;

-- Listing 14-6. Identifying cycles

select
   list.picker_emp_id as emp
 , list.id            as list
 , last_value(
      case log.activity when 'D' then log_time end
   ) ignore nulls over (
      partition by list.id
      order by log.log_time
      rows between unbounded preceding and current row
   ) as begin_cycle
 , to_char(log_time, 'HH24:MI:SS') as act_time
 , log.activity as act
 , lead(activity) over (
      partition by list.id
      order by log.log_time
   ) as next_act
 , round((
      lead(log_time) over (
         partition by list.id
         order by log.log_time
      ) - log_time
   )*(24*60*60)) as secs
from picking_list list
join picking_log log
   on log.picklist_id = list.id
order by list.id, log.log_time;

-- Listing 14-7. Grouping cycles by pivoting

select *
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , last_value(
         case log.activity when 'D' then log_time end
      ) ignore nulls over (
         partition by list.id
         order by log.log_time
         rows between unbounded preceding and current row
      ) as begin_cycle
    , lead(activity) over (
         partition by list.id
         order by log.log_time
      ) as next_act
    , round((
         lead(log_time) over (
            partition by list.id
            order by log.log_time
         ) - log_time
      )*(24*60*60)) as secs
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
) pivot (
   sum(secs)
   for (next_act) in (
      'A' as drive   -- D->A
    , 'P' as pick    -- A->P or P->P
    , 'D' as pack    -- P->D
   )
)
order by list, begin_cycle;

-- Listing 14-8. Statistics per picking list on the pivoted cycles

select
   max(emp) as emp
 , list
 , min(begin_cycle) as begin
 , count(*) as drvs
 , round(avg(drive), 1) as avg_d
 , count(pick) as stops
 , round(avg(pick), 1) as avg_pick
 , round(avg(pack), 1) as avg_pack
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , last_value(
         case log.activity when 'D' then log_time end
      ) ignore nulls over (
         partition by list.id
         order by log.log_time
         rows between unbounded preceding and current row
      ) as begin_cycle
    , lead(activity) over (
         partition by list.id
         order by log.log_time
      ) as next_act
    , round((
         lead(log_time) over (
            partition by list.id
            order by log.log_time
         ) - log_time
      )*(24*60*60)) as secs
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
) pivot (
   sum(secs)
   for (next_act) in (
      'A' as drive   -- D->A
    , 'P' as pick    -- A->P or P->P
    , 'D' as pack    -- P->D
   )
)
group by list
order by list;

-- Listing 14-9. Identifying picking cycles with row pattern matching

select
   *
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , log.log_time
    , log.activity       as act
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
)
match_recognize (
   partition by list
   order by log_time
   measures
      max(emp) as emp
    , first(log_time) as begin_cycle
    , round(
         (arrive.log_time - first(depart.log_time))
       * (24*60*60)
      ) as drive
    , round(
         (last(pick.log_time) - arrive.log_time)
       * (24*60*60)
      ) as pick
    , round(
         (next(last(pick.log_time)) - last(pick.log_time))
       * (24*60*60)
      ) as pack
   one row per match
   after match skip to last arrive
   pattern (depart arrive pick* depart{0,1})
   define
      depart as act = 'D'
    , arrive as act = 'A'
    , pick   as act = 'P'
)
order by list;

-- Listing 14-10. Statistics per picking list with row pattern matching

select
   max(emp) as emp
 , list
 , min(begin_cycle) as begin
 , count(*) as drvs
 , round(avg(drive), 1) as avg_d
 , count(pick) as stops
 , round(avg(pick), 1) as avg_pick
 , round(avg(pack), 1) as avg_pack
from (
   select
      list.picker_emp_id as emp
    , list.id            as list
    , log.log_time
    , log.activity       as act
   from picking_list list
   join picking_log log
      on log.picklist_id = list.id
)
match_recognize (
   partition by list
   order by log_time
   measures
      max(emp) as emp
    , first(log_time) as begin_cycle
    , round(
         (arrive.log_time - first(depart.log_time))
       * (24*60*60)
      ) as drive
    , round(
         (last(pick.log_time) - arrive.log_time)
       * (24*60*60)
      ) as pick
    , round(
         (next(last(pick.log_time)) - last(pick.log_time))
       * (24*60*60)
      ) as pack
   one row per match
   after match skip to last arrive
   pattern (depart arrive pick* depart{0,1})
   define
      depart as act = 'D'
    , arrive as act = 'A'
    , pick   as act = 'P'
)
group by list
order by list;

/* ***************************************************** */
