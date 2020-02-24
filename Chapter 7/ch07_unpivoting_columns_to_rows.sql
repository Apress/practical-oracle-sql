/* ***************************************************** **
   ch07_unpivoting_columns_to_rows.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 7
   Unpivoting Columns to Rows
   
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
   Chapter 7 example code
   ----------------------------------------------------- */

-- Listing 7-1. Daily web visits per device

select day, pc, tablet, phone
from web_devices
order by day;

-- Listing 7-2. Using unpivot to get dimension and measure

select day, device, cnt
from web_devices
unpivot (
   cnt
   for device
   in (
      pc     as 'PC'
    , tablet as 'Tablet'
    , phone  as 'Phone'
   )
)
order by day, device;

-- Listing 7-3. Manual unpivot using numbered row generator

select
   wd.day
 , case r.rn
      when 1 then 'PC'
      when 2 then 'Tablet'
      when 3 then 'Phone'
   end as device
 , case r.rn
      when 1 then wd.pc
      when 2 then wd.tablet
      when 3 then wd.phone
   end as cnt
from web_devices wd
cross join (
   select level as rn from dual connect by level <= 3
) r
order by day, device;

-- Listing 7-4. Manual unpivot using dimension style row generator

with devices( device ) as (
   select 'PC'     from dual union all
   select 'Tablet' from dual union all
   select 'Phone'  from dual
)
select
   wd.day
 , d.device
 , case d.device
      when 'PC'     then wd.pc
      when 'Tablet' then wd.tablet
      when 'Phone'  then wd.phone
   end as cnt
from web_devices wd
cross join devices d
order by day, device;

-- Listing 7-5. Daily web visits and purchases per gender and channel

select
   day
 , m_tw_cnt
 , m_tw_qty
 , m_fb_cnt
 , m_fb_qty
 , f_tw_cnt
 , f_tw_qty
 , f_fb_cnt
 , f_fb_qty
from web_demographics
order by day;

-- Listing 7-6. Using unpivot with two dimensions and two measures

select day, gender, channel, cnt, qty
from web_demographics
unpivot (
   ( cnt, qty )
   for ( gender, channel )
   in (
      (m_tw_cnt, m_tw_qty) as ('Male'  , 'Twitter' )
    , (m_fb_cnt, m_fb_qty) as ('Male'  , 'Facebook')
    , (f_tw_cnt, f_tw_qty) as ('Female', 'Twitter' )
    , (f_fb_cnt, f_fb_qty) as ('Female', 'Facebook')
   )
)
order by day, gender, channel;

-- Listing 7-7. Using unpivot with one composite dimension and two measures

select day, gender_and_channel, cnt, qty
from web_demographics
unpivot (
   ( cnt, qty )
   for gender_and_channel
   in (
      (m_tw_cnt, m_tw_qty) as 'Male on Twitter'
    , (m_fb_cnt, m_fb_qty) as 'Male on Facebook'
    , (f_tw_cnt, f_tw_qty) as 'Female on Twitter'
    , (f_fb_cnt, f_fb_qty) as 'Female on Facebook'
   )
)
order by day, gender_and_channel;

-- Listing 7-8. Using unpivot with one single dimension and two measures

select day, gender, cnt, qty
from web_demographics
unpivot (
   ( cnt, qty )
   for gender
   in (
      (m_tw_cnt, m_tw_qty) as 'Male'
    , (m_fb_cnt, m_fb_qty) as 'Male'
    , (f_tw_cnt, f_tw_qty) as 'Female'
    , (f_fb_cnt, f_fb_qty) as 'Female'
   )
)
order by day, gender;

-- Listing 7-9. Using unpivot with one aggregated dimension and two measures

select day
     , gender
     , sum(cnt) as cnt
     , sum(qty) as qty
from web_demographics
unpivot (
   ( cnt, qty )
   for gender
   in (
      (m_tw_cnt, m_tw_qty) as 'Male'
    , (m_fb_cnt, m_fb_qty) as 'Male'
    , (f_tw_cnt, f_tw_qty) as 'Female'
    , (f_fb_cnt, f_fb_qty) as 'Female'
   )
)
group by day, gender
order by day, gender;

-- Listing 7-10. Using unpivot with two dimensions and one measure

select day, gender, channel, cnt
from web_demographics
unpivot (
   cnt
   for ( gender, channel )
   in (
      m_tw_cnt as ('Male'  , 'Twitter' )
    , m_fb_cnt as ('Male'  , 'Facebook')
    , f_tw_cnt as ('Female', 'Twitter' )
    , f_fb_cnt as ('Female', 'Facebook')
   )
)
order by day, gender, channel;

-- Listing 7-11. Dimension table for gender

select letter, name
from gender_dim
order by letter;

-- Listing 7-12. Dimension table for channels

select id, name, shortcut
from channels_dim
order by id;

-- Listing 7-13. Manual unpivot using dimension tables

select
   d.day
 , g.letter as g_id
 , c.id as ch_id
 , case g.letter
      when 'M' then
         case c.shortcut
            when 'tw' then d.m_tw_cnt
            when 'fb' then d.m_fb_cnt
         end
      when 'F' then
         case c.shortcut
            when 'tw' then d.f_tw_cnt
            when 'fb' then d.f_fb_cnt
         end
   end as cnt
 , case g.letter
      when 'M' then
         case c.shortcut
            when 'tw' then d.m_tw_qty
            when 'fb' then d.m_fb_qty
         end
      when 'F' then
         case c.shortcut
            when 'tw' then d.f_tw_qty
            when 'fb' then d.f_fb_qty
         end
   end as qty
from web_demographics d
cross join gender_dim g
cross join channels_dim c
order by day, g_id, ch_id;

-- Listing 7-14. Preparing column names mapped to dimension values

select
   s.cnt_col, s.qty_col
 , s.g_id, s.gender
 , s.ch_id, s.channel
from (
   select
      lower(
         g.letter || '_' || c.shortcut || '_cnt'
      ) as cnt_col
    , lower(
         g.letter || '_' || c.shortcut || '_qty'
      )as qty_col
    , g.letter as g_id
    , g.name as gender
    , c.id as ch_id
    , c.name as channel
   from gender_dim g
   cross join channels_dim c
) s
join user_tab_columns cnt_c
   on cnt_c.column_name = upper(s.cnt_col)
join user_tab_columns qty_c
   on qty_c.column_name = upper(s.cnt_col)
where cnt_c.table_name = 'WEB_DEMOGRAPHICS'
and   qty_c.table_name = 'WEB_DEMOGRAPHICS'
order by gender, channel;

-- Listing 7-15. Dynamically building unpivot query

set serveroutput on

variable unpivoted refcursor

declare
   v_unpivot_sql  varchar2(4000);
begin
   for c in (
      select
         s.cnt_col, s.qty_col
       , s.g_id, s.gender
       , s.ch_id, s.channel
      from (
         select
            lower(
               g.letter || '_' || c.shortcut || '_cnt'
            ) as cnt_col
          , lower(
               g.letter || '_' || c.shortcut || '_qty'
            )as qty_col
          , g.letter as g_id
          , g.name as gender
          , c.id as ch_id
          , c.name as channel
         from gender_dim g
         cross join channels_dim c
      ) s
      join user_tab_columns cnt_c
         on cnt_c.column_name = upper(s.cnt_col)
      join user_tab_columns qty_c
         on qty_c.column_name = upper(s.cnt_col)
      where cnt_c.table_name = 'WEB_DEMOGRAPHICS'
      and   qty_c.table_name = 'WEB_DEMOGRAPHICS'
      order by gender, channel
   ) loop

      if v_unpivot_sql is null then
         v_unpivot_sql := q'[
            select day, g_id, ch_id, cnt, qty
            from web_demographics
            unpivot (
               ( cnt, qty )
               for ( g_id, ch_id )
               in (
                  ]';
      else
         v_unpivot_sql := v_unpivot_sql || q'[
                , ]';
      end if;

      v_unpivot_sql := v_unpivot_sql
                    || '(' || c.cnt_col
                    || ', ' || c.qty_col
                    || ') as (''' || c.g_id
                    || ''', ' || c.ch_id
                    || ')';

   end loop;
   
   v_unpivot_sql := v_unpivot_sql || q'[
               )
            )
            order by day, g_id, ch_id]';

   dbms_output.put_line(v_unpivot_sql);
   
   open :unpivoted for v_unpivot_sql;
end;
/

print unpivoted

/* ***************************************************** */
