/* ***************************************************** **
   ch17_up_and_down_patterns.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 17
   Row pattern matching on stock ticker data
   
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
   Chapter 17 example code
   ----------------------------------------------------- */

-- Listing 17-1. Classifying the rows

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      down | up
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
)
order by symbol, day;

-- Changing to less-than-or-equal and greater-than-or-equal

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      down | up
   )
   define
      down as price <= prev(price)
    , up   as price >= prev(price)
)
order by symbol, day;

-- Using down, up and same

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      down | up | same
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, day;

-- Adding undefined STRT to the pattern

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      down | up | same | strt
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, day;

-- Here not good with STRT in front in the pattern

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      strt | down | up | same
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, day;

-- Listing 17-2. Searching for V shapes

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   pattern (
      (down | same)+ (up | same)+
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, day;

-- Listing 17-3. Output a single row for each match

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   pattern (
      (down | same)+ (up | same)+
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, first_day;

-- Adding STRT to the pattern

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   pattern (
      strt (down | same)+ (up | same)+
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, first_day;

-- Showing default AFTER MATCH SKIP PAST LAST ROW

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   after match skip past last row
   pattern (
      strt (down | same)+ (up | same)+
   )
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, first_day;

-- Using SKIP TO LAST together with SUBSET

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   after match skip to last up_or_same
   pattern (
      strt (down | same)+ (up | same)+
   )
   subset up_or_same = (up, same)
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, first_day;

-- Listing 17-4. Simplified query utilizing
-- how definitions are evaluated for patterns

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   after match skip to last up
   pattern (
      strt down+ up+
   )
   define
      down as price <= prev(price)
    , up   as price >= prev(price)
)
order by symbol, first_day;

-- Listing 17-5. Seeing all rows of the simplified query

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   after match skip to last up
   pattern (
      strt down+ up+
   )
   define
      down as price <= prev(price)
    , up   as price >= prev(price)
)
order by symbol, day;

-- Listing 17-6. First attempt at finding W shapes

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   after match skip to last up
   pattern (
      strt down+ up+ down+ up+
   )
   define
      down as price <= prev(price)
    , up   as price >= prev(price)
)
order by symbol, first_day;

-- Debugging with ALL ROWS PER MATCH

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   after match skip to last up
   pattern (
      strt down+ up+ down+ up+
   )
   define
      down as price <= prev(price)
    , up   as price >= prev(price)
)
order by symbol, day;

-- Attempt with DOWN, UP and SAME

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   after match skip to last up_or_same
   pattern (
      strt (down | same)+ (up | same)+ (down | same)+ (up | same)+
   )
   subset up_or_same = (up, same)
   define
      down as price < prev(price)
    , up   as price > prev(price)
    , same as price = prev(price)
)
order by symbol, day;

-- Listing 17-7. More intelligent definitions for W shape matching

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , classifier()   as class
    , prev(price)    as prev
   all rows per match
   after match skip to last up
   pattern (
      strt down+ up+ down+ up+
   )
   define
      down as price < prev(price)
           or (    price = prev(price)
               and price = last(down.price, 1)
              )
    , up   as price > prev(price)
           or (    price = prev(price)
               and price = last(up.price  , 1)
              )
)
order by symbol, day;

-- Listing 17-8. Finding overlapping W shapes

select *
from ticker
match_recognize (
   partition by symbol
   order by day
   measures
      match_number() as match
    , first(day)     as first_day
    , last(day)      as last_day
    , count(*)       as days
   one row per match
   after match skip to first up
   pattern (
      strt down+ up+ down+ up+
   )
   define
      down as price < prev(price)
           or (    price = prev(price)
               and price = last(down.price, 1)
              )
    , up   as price > prev(price)
           or (    price = prev(price)
               and price = last(up.price  , 1)
              )
)
order by symbol, first_day;

/* ***************************************************** */
