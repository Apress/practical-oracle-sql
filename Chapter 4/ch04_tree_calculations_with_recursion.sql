/* ***************************************************** **
   ch04_tree_calculations_with_recursion.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 4
   Tree Calculations with Recursion
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 4 example code
   ----------------------------------------------------- */

-- Listing 4-1. The hierarchical relations of the different packaging types

select
   p.id as p_id
 , lpad(' ', 2*(level-1)) || p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , pr.qty
from packaging_relations pr
join packaging p
   on p.id = pr.packaging_id
join packaging c
   on c.id = pr.contains_id
start with pr.packaging_id not in (
   select c.contains_id from packaging_relations c
)
connect by pr.packaging_id = prior pr.contains_id
order siblings by pr.contains_id;

-- Listing 4-2. First attempt at multiplication of quantities

select
   connect_by_root p.id as p_id
 , connect_by_root p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , ltrim(sys_connect_by_path(pr.qty, '*'), '*') as qty_expr
 , qty * prior qty as qty_mult
from packaging_relations pr
join packaging p
   on p.id = pr.packaging_id
join packaging c
   on c.id = pr.contains_id
where connect_by_isleaf = 1
start with pr.packaging_id not in (
   select c.contains_id from packaging_relations c
)
connect by pr.packaging_id = prior pr.contains_id
order siblings by pr.contains_id;

-- Listing 4-3. Multiplication of quantities with recursive subquery factoring

with recursive_pr (
   packaging_id, contains_id, qty, lvl
) as (
   select
      pr.packaging_id
    , pr.contains_id
    , pr.qty
    , 1 as lvl
   from packaging_relations pr
   where pr.packaging_id not in (
      select c.contains_id from packaging_relations c
   )
   union all
   select
      pr.packaging_id
    , pr.contains_id
    , rpr.qty * pr.qty as qty
    , rpr.lvl + 1      as lvl
   from recursive_pr rpr
   join packaging_relations pr
      on pr.packaging_id = rpr.contains_id
)
   search depth first by contains_id set rpr_order
select
   p.id as p_id
 , lpad(' ', 2*(rpr.lvl-1)) || p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , rpr.qty
from recursive_pr rpr
join packaging p
   on p.id = rpr.packaging_id
join packaging c
   on c.id = rpr.contains_id
order by rpr.rpr_order;

-- Listing 4-4. Finding leaves in recursive subquery factoring

with recursive_pr (
   root_id, packaging_id, contains_id, qty, lvl
) as (
   select
      pr.packaging_id as root_id
    , pr.packaging_id
    , pr.contains_id
    , pr.qty
    , 1 as lvl
   from packaging_relations pr
   where pr.packaging_id not in (
      select c.contains_id from packaging_relations c
   )
   union all
   select
      rpr.root_id
    , pr.packaging_id
    , pr.contains_id
    , rpr.qty * pr.qty as qty
    , rpr.lvl + 1      as lvl
   from recursive_pr rpr
   join packaging_relations pr
      on pr.packaging_id = rpr.contains_id
)
   search depth first by contains_id set rpr_order
select
   p.id as p_id
 , p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , leaf.qty
from (
   select
      rpr.*
    , case
         when nvl(
                 lead(rpr.lvl) over (order by rpr.rpr_order)
               , 0
              ) > rpr.lvl
         then 0
         else 1
      end as is_leaf
   from recursive_pr rpr
) leaf
join packaging p
   on p.id = leaf.root_id
join packaging c
   on c.id = leaf.contains_id
where leaf.is_leaf = 1
order by leaf.rpr_order;

-- Listing 4-5. Grouping totals for packaging combinations

with recursive_pr (
   root_id, packaging_id, contains_id, qty, lvl
) as (
   select
      pr.packaging_id as root_id
    , pr.packaging_id
    , pr.contains_id
    , pr.qty
    , 1 as lvl
   from packaging_relations pr
   where pr.packaging_id not in (
      select c.contains_id from packaging_relations c
   )
   union all
   select
      rpr.root_id
    , pr.packaging_id
    , pr.contains_id
    , rpr.qty * pr.qty as qty
    , rpr.lvl + 1      as lvl
   from recursive_pr rpr
   join packaging_relations pr
      on pr.packaging_id = rpr.contains_id
)
   search depth first by contains_id set rpr_order
select
   p.id as p_id
 , p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , leaf.qty
from (
   select
      root_id, contains_id, sum(qty) as qty
   from (
      select
         rpr.*
       , case
            when nvl(
                    lead(rpr.lvl) over (order by rpr.rpr_order)
                  , 0
                 ) > rpr.lvl
            then 0
            else 1
         end as is_leaf
      from recursive_pr rpr
   )
   where is_leaf = 1
   group by root_id, contains_id
) leaf
join packaging p
   on p.id = leaf.root_id
join packaging c
   on c.id = leaf.contains_id
order by p.id, c.id;

-- Listing 4-6. Alternative method using dynamic evaluation function

with
   function evaluate_expr(
      p_expr varchar2
   )
      return number
   is
      l_retval number;
   begin
      execute immediate
         'select ' || p_expr || ' from dual'
         into l_retval;
      return l_retval;
   end;
select
   connect_by_root p.id as p_id
 , connect_by_root p.name as p_name
 , c.id as c_id
 , c.name as c_name
 , ltrim(sys_connect_by_path(pr.qty, '*'), '*') as qty_expr
 , evaluate_expr(
      ltrim(sys_connect_by_path(pr.qty, '*'), '*')
   ) as qty_mult
from packaging_relations pr
join packaging p
   on p.id = pr.packaging_id
join packaging c
   on c.id = pr.contains_id
where connect_by_isleaf = 1
start with pr.packaging_id not in (
   select c.contains_id from packaging_relations c
)
connect by pr.packaging_id = prior pr.contains_id
order siblings by pr.contains_id;
/

/* ***************************************************** */
