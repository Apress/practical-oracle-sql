/* ***************************************************** **
   ch19_merging_date_ranges.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 19
   Merging Date Ranges
   
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
   Chapter 19 example code
   ----------------------------------------------------- */

-- Listing 19-2. The hire periods data

select
   ehp.emp_id
 , ehp.name
 , ehp.start_date
 , ehp.end_date
 , ehp.title
from emp_hire_periods_with_name ehp
order by ehp.emp_id, ehp.start_date;

-- Listing 19-4. Querying hire periods table as of a specific date

select
   ehp.emp_id
 , e.name
 , ehp.start_date
 , ehp.end_date
 , ehp.title
from emp_hire_periods
        as of period for employed_in date '2010-07-01'
     ehp
join employees e
   on e.id = ehp.emp_id
order by ehp.emp_id, ehp.start_date;

-- Querying as of another date

select
   ehp.emp_id
 , e.name
 , ehp.start_date
 , ehp.end_date
 , ehp.title
from emp_hire_periods
        as of period for employed_in date '2016-07-01'
     ehp
join employees e
   on e.id = ehp.emp_id
order by ehp.emp_id, ehp.start_date;

-- Listing 19-5. Comparing start_date to end_date of the previous row

select
   emp_id
 , name
 , start_date
 , end_date
 , jobs
from emp_hire_periods_with_name
match_recognize (
   partition by emp_id
   order by start_date, end_date
   measures
      max(name)         as name
    , first(start_date) as start_date
    , last(end_date)    as end_date
    , count(*)          as jobs
   pattern (
      strt adjoin_or_overlap*
   )
   define
      adjoin_or_overlap as
         start_date <= prev(end_date)
)
order by emp_id, start_date;

-- Trying to order by end_date first instead of start_date

select
   emp_id
 , name
 , start_date
 , end_date
 , jobs
from emp_hire_periods_with_name
match_recognize (
   partition by emp_id
   order by end_date, start_date
   measures
      max(name)         as name
    , first(start_date) as start_date
    , last(end_date)    as end_date
    , count(*)          as jobs
   pattern (
      strt adjoin_or_overlap*
   )
   define
      adjoin_or_overlap as
         start_date <= prev(end_date)
)
order by emp_id, start_date;

-- Attempting to compare start_date with the highest end_date so far
-- This does not work and depending on which DB version and which client
-- you can risk that your session crashes with one of these errors:
--    ORA-03113: end-of-file on communication channel
--    java.lang.NullPointerException
-- Do not call this statement, it just illustrates a point
/*
select
   emp_id
 , name
 , start_date
 , end_date
 , jobs
from emp_hire_periods_with_name
match_recognize (
   partition by emp_id
   order by start_date, end_date
   measures
      max(name)         as name
    , first(start_date) as start_date
    , max(end_date)     as end_date
    , count(*)          as jobs
   pattern (
      strt adjoin_or_overlap*
   )
   define
      adjoin_or_overlap as
         start_date <= max(end_date)
)
order by emp_id, start_date;
*/

-- Listing 19-6. Comparing start_date of next row to highest end_date seen so far

select
   emp_id
 , name
 , start_date
 , end_date
 , jobs
from emp_hire_periods_with_name
match_recognize (
   partition by emp_id
   order by start_date, end_date
   measures
      max(name)         as name
    , first(start_date) as start_date
    , max(end_date)     as end_date
    , count(*)          as jobs
   pattern (
      adjoin_or_overlap* last_row
   )
   define
      adjoin_or_overlap as
         next(start_date) <= max(end_date)
)
order by emp_id, start_date;

-- Listing 19-7. Handling null=infinity for both start and end

select
   emp_id
 , name
 , start_date
 , end_date
 , jobs
from emp_hire_periods_with_name
match_recognize (
   partition by emp_id
   order by start_date nulls first, end_date nulls last
   measures
      max(name)         as name
    , first(start_date) as start_date
    , nullif(
         max(nvl(end_date, date '9999-12-31'))
       , date '9999-12-31'
      )                 as end_date
    , count(*)          as jobs
   pattern (
      adjoin_or_overlap* last_row
   )
   define
      adjoin_or_overlap as
         nvl(next(start_date), date '-4712-01-01')
            <= max(nvl(end_date, date '9999-12-31'))
)
order by emp_id, start_date;

/* ***************************************************** */
