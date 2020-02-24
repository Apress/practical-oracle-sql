/* ***************************************************** **
   ch06_iterative_calculations_with_multidimensional_data.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 6
   Iterative Calculations with Multidimensional Data
   
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
column generation format 99
column x          format 99
column y          format 99
column alive      format 9999
column cells      format a10
column sum_alives format a10
column nb_alives  format a10

/* -----------------------------------------------------
   Chapter 6 example code
   ----------------------------------------------------- */

-- Listing 6-1. Creating a 10x10 generation zero population

truncate table conway_gen_zero;

insert into conway_gen_zero (x, y, alive)
select * from (
   with numbers as (
      select level as n from dual
      connect by level <= 10
   ), grid as (
      select
         x.n as x
       , y.n as y
      from numbers x
      cross join numbers y
   ), start_cells as (
      select  4 x,  4 y from dual union all
      select  5 x,  4 y from dual union all
      select  4 x,  5 y from dual union all
      select  6 x,  6 y from dual union all
      select  7 x,  6 y from dual union all
      select  4 x,  7 y from dual union all
      select  5 x,  7 y from dual union all
      select  6 x,  7 y from dual
   )
   select
      g.x
    , g.y
    , nvl2(sc.x, 1, 0) as alive
   from grid g
   left outer join start_cells sc
      on  sc.x = g.x
      and sc.y = g.y
);

commit;

-- Listing 6-2. Vizualising generation zero

select
   listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) as cells
from conway_gen_zero
group by y
order by y;

-- Listing 6-3. Live neighbour calculation with model clause

select *
from conway_gen_zero
model
dimension by (
   x, y
)
measures (
   alive
 , 0 as sum_alive
 , 0 as nb_alive
)
ignore nav
rules
(
   sum_alive[any, any] =
      sum(alive)[
         x between cv() - 1 and cv() + 1
       , y between cv() - 1 and cv() + 1
      ]
 , nb_alive[any, any] =
      sum_alive[cv(), cv()] - alive[cv(), cv()]
)
order by x, y;

-- Listing 6-4. Live neighbour calculation with scalar subquery

select
   x
 , y
 , alive
 , sum_alive
 , sum_alive - alive as nb_alive
from (
   select
      x
    , y
    , alive
    , (
         select sum(gz2.alive)
         from conway_gen_zero gz2
         where gz2.x between gz.x - 1 and gz.x + 1
         and   gz2.y between gz.y - 1 and gz.y + 1
      ) as sum_alive
   from conway_gen_zero gz
)
order by x, y;

-- Listing 6-5. Displaying the counts grid fashion

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      x, y
   )
   measures (
      alive
    , 0 as sum_alive
    , 0 as nb_alive
   )
   ignore nav
   rules
   (
      sum_alive[any, any] =
         sum(alive)[
            x between cv() - 1 and cv() + 1
          , y between cv() - 1 and cv() + 1
         ]
    , nb_alive[any, any] =
         sum_alive[cv(), cv()] - alive[cv(), cv()]
   )
)
select
   listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
 , listagg(sum_alive) within group (order by x) sum_alives
 , listagg(nb_alive ) within group (order by x) nb_alives
from conway
group by y
order by y;

-- Variant of Listing 6-5 based on 6-4 instead of 6-3

with conway as (
   select
      x
    , y
    , alive
    , sum_alive
    , sum_alive - alive as nb_alive
   from (
      select
         x
       , y
       , alive
       , (
            select sum(gz2.alive)
            from conway_gen_zero gz2
            where gz2.x between gz.x - 1 and gz.x + 1
            and   gz2.y between gz.y - 1 and gz.y + 1
         ) as sum_alive
      from conway_gen_zero gz
   )
)
select
   listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
 , listagg(sum_alive) within group (order by x) sum_alives
 , listagg(nb_alive ) within group (order by x) nb_alives
from conway
group by y
order by y;

-- Listing 6-6. Iterating 2 generations

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
    , 0 as sum_alive
    , 0 as nb_alive
   )
   ignore nav
   rules upsert all iterate (2)
   (
      sum_alive[iteration_number, any, any] =
         sum(alive)[
            generation = iteration_number
          , x between cv() - 1 and cv() + 1
          , y between cv() - 1 and cv() + 1
         ]
    , nb_alive[iteration_number, any, any] =
         sum_alive[iteration_number, cv(), cv()]
           - alive[iteration_number, cv(), cv()]
    , alive[iteration_number + 1, any, any] =
         case nb_alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
 , listagg(sum_alive) within group (order by x) sum_alives
 , listagg(nb_alive ) within group (order by x) nb_alives
from conway
group by generation, y
order by generation, y;

-- Listing 6-7. Reducing the query

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
   )
   ignore nav
   rules upsert all iterate (2)
   (
      alive[iteration_number + 1, any, any] =
         case sum(alive)[
                  generation = iteration_number,
                  x between cv() - 1 and cv() + 1,
                  y between cv() - 1 and cv() + 1
              ] - alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
from conway
group by generation, y
order by generation, y;

-- 25 generations

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
   )
   ignore nav
   rules upsert all iterate (25)
   (
      alive[iteration_number + 1, any, any] =
         case sum(alive)[
                  generation = iteration_number,
                  x between cv() - 1 and cv() + 1,
                  y between cv() - 1 and cv() + 1
              ] - alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
from conway
group by generation, y
order by generation, y;

-- 50 generations

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
   )
   ignore nav
   rules upsert all iterate (50)
   (
      alive[iteration_number + 1, any, any] =
         case sum(alive)[
                  generation = iteration_number,
                  x between cv() - 1 and cv() + 1,
                  y between cv() - 1 and cv() + 1
              ] - alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
from conway
group by generation, y
order by generation, y;

-- Listing 6-8. The Toad

truncate table conway_gen_zero;

insert into conway_gen_zero (x, y, alive)
select * from (
   with numbers as (
      select level as n from dual
      connect by level <= 6
   ), grid as (
      select
         x.n as x
       , y.n as y
      from numbers x
      cross join numbers y
   ), start_cells as (
      select  4 x,  2 y from dual union all
      select  2 x,  3 y from dual union all
      select  5 x,  3 y from dual union all
      select  2 x,  4 y from dual union all
      select  5 x,  4 y from dual union all
      select  3 x,  5 y from dual
   )
   select
      g.x
    , g.y
    , nvl2(sc.x, 1, 0) as alive
   from grid g
   left outer join start_cells sc
      on  sc.x = g.x
      and sc.y = g.y
);

commit;

-- 2 generations show generation zero and two are identical

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
   )
   ignore nav
   rules upsert all iterate (2)
   (
      alive[iteration_number + 1, any, any] =
         case sum(alive)[
                  generation = iteration_number,
                  x between cv() - 1 and cv() + 1,
                  y between cv() - 1 and cv() + 1
              ] - alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
from conway
group by generation, y
order by generation, y;

-- Oscillates between two states no matter how many generations

with conway as (
   select *
   from conway_gen_zero
   model
   dimension by (
      0 as generation
    , x, y
   )
   measures (
      alive
   )
   ignore nav
   rules upsert all iterate (20)
   (
      alive[iteration_number + 1, any, any] =
         case sum(alive)[
                  generation = iteration_number,
                  x between cv() - 1 and cv() + 1,
                  y between cv() - 1 and cv() + 1
              ] - alive[iteration_number, cv(), cv()]
            when 2 then alive[iteration_number, cv(), cv()]
            when 3 then 1
            else 0
         end
   )
)
select
   generation
 , listagg(
      case alive
         when 1 then 'X'
         when 0 then ' '
      end
   ) within group (
      order by x
   ) cells
from conway
group by generation, y
order by generation, y;

/* ***************************************************** */
