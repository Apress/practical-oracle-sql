/* ***************************************************** **
   ch22_counting_children_in_trees.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 22
   Counting Children in Trees
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 22 example code
   ----------------------------------------------------- */

-- Listing 22-1. A classic hierarchical query of employees

select
   e.id
 , lpad(' ', 2*(level-1)) || e.name as name
 , e.title as title
 , e.supervisor_id as super
from employees e
start with e.supervisor_id is null
connect by e.supervisor_id = prior e.id
order siblings by e.name;

-- Listing 22-2. Counting the number of subordinates

select
   e.id
 , lpad(' ', 2*(level-1)) || e.name as name
 , (
      select count(*)
      from employees sub
      start with sub.supervisor_id = e.id
      connect by sub.supervisor_id = prior sub.id
   ) as subs
from employees e
start with e.supervisor_id is null
connect by e.supervisor_id = prior e.id
order siblings by e.name;

-- Listing 22-3. Counting subordinates with match_recognize

with hierarchy as (
   select
      lvl, id, name, rownum as rn
   from (
      select
         level as lvl, e.id, e.name
      from employees e
      start with e.supervisor_id is null
      connect by e.supervisor_id = prior e.id
      order siblings by e.name
   )
)
select
   id
 , lpad(' ', (lvl-1)*2) || name as name
 , subs
from hierarchy
match_recognize (
   order by rn
   measures
      strt.rn           as rn
    , strt.lvl          as lvl
    , strt.id           as id
    , strt.name         as name
    , count(higher.lvl) as subs
   one row per match
   after match skip to next row
   pattern (
      strt higher*
   )
   define
      higher as higher.lvl > strt.lvl
)
order by rn;

-- Listing 22-4. Inspecting the details with all rows per match

with hierarchy as (
   select
      lvl, id, name, rownum as rn
   from (
      select
         level as lvl, e.id, e.name
      from employees e
      start with e.supervisor_id is null
      connect by e.supervisor_id = prior e.id
      order siblings by e.name
   )
)
select
   mn
 , rn
 , lvl
 , lpad(' ', (lvl-1)*2)
    || substr(name, 1, instr(name, ' ') - 1) as name
 , roll
 , subs
 , cls
 , substr(stname, 1, instr(stname, ' ') - 1) as stname
 , substr(hiname, 1, instr(hiname, ' ') - 1) as hiname
from hierarchy
match_recognize (
   order by rn
   measures
      match_number()    as mn
    , classifier()      as cls
    , strt.name         as stname
    , higher.name       as hiname
    , count(higher.lvl) as roll
    , final count(higher.lvl) as subs
   all rows per match
   after match skip to next row
   pattern (
      strt higher*
   )
   define
      higher as higher.lvl > strt.lvl
)
order by mn, rn;

-- Listing 22-5. Pivoting to show which rows are in which match

with hierarchy as (
   select
      lvl, id, name, rownum as rn
   from (
      select
         level as lvl, e.id, e.name
      from employees e
      start with e.supervisor_id is null
      connect by e.supervisor_id = prior e.id
      order siblings by e.name
   )
)
select
   name
 , "1", "2", "3", "4", "5", "6", "7"
 , "8", "9", "10", "11", "12", "13", "14"
from (
   select
      mn
    , rn
    , lpad(' ', (lvl-1)*2)
       || substr(name, 1, instr(name, ' ') - 1) as name
   from hierarchy
   match_recognize (
      order by rn
      measures
         match_number()    as mn
      all rows per match
      after match skip to next row
      pattern (
         strt higher*
      )
      define
         higher as higher.lvl > strt.lvl
   )
) pivot (
   max('X')
   for mn in (
      1,2,3,4,5,6,7,8,9,10,11,12,13,14
   )
)
order by rn;

-- Listing 22-6. Adding multiple measures when doing one row per match

with hierarchy as (
   select
      lvl, id, name, rownum as rn
   from (
      select
         level as lvl, e.id, e.name
      from employees e
      start with e.supervisor_id is null
      connect by e.supervisor_id = prior e.id
      order siblings by e.name
   )
)
select
   lpad(' ', (lvl-1)*2) || name as name
 , subs
 , hifrom
 , hito
 , himax
from hierarchy
match_recognize (
   order by rn
   measures
      strt.rn            as rn
    , strt.lvl           as lvl
    , strt.name          as name
    , count(higher.lvl)  as subs
    , first(higher.name) as hifrom
    , last(higher.name)  as hito
    , max(higher.lvl)    as himax
   one row per match
   after match skip to next row
   pattern (
      strt higher*
   )
   define
      higher as higher.lvl > strt.lvl
)
order by rn;

-- Listing 22-7. Filteríng matches with the pattern definition

with hierarchy as (
   select
      lvl, id, name, rownum as rn
   from (
      select
         level as lvl, e.id, e.name
      from employees e
      start with e.supervisor_id is null
      connect by e.supervisor_id = prior e.id
      order siblings by e.name
   )
)
select
   id
 , lpad(' ', (lvl-1)*2) || name as name
 , subs
from hierarchy
match_recognize (
   order by rn
   measures
      strt.rn           as rn
    , strt.lvl          as lvl
    , strt.id           as id
    , strt.name         as name
    , count(higher.lvl) as subs
   one row per match
   after match skip to next row
   pattern (
      strt higher+
   )
   define
      higher as higher.lvl > strt.lvl
)
order by rn;

/* ***************************************************** */
