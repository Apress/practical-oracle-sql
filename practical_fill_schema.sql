/* ***************************************************** **
   practical_fill_schema.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Creation of objects in schema PRACTICAL
   Tables, data and other objects
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   Create tables
   ----------------------------------------------------- */

create table customers (
   id          integer constraint customer_pk primary key
 , name        varchar2(20 char) not null
);

create table conway_gen_zero (
   x           integer not null
 , y           integer not null
 , alive       integer not null check (alive in (0,1))
 , constraint conway_gen_zero_pk primary key (x, y)
);

create table web_devices (
   day         date constraint web_devices_pk primary key
 , pc          integer
 , tablet      integer
 , phone       integer
);

create table web_demographics (
   day         date constraint web_demographics_pk primary key
 , m_tw_cnt    integer
 , m_tw_qty    integer
 , m_fb_cnt    integer
 , m_fb_qty    integer
 , f_tw_cnt    integer
 , f_tw_qty    integer
 , f_fb_cnt    integer
 , f_fb_qty    integer
);

create table channels_dim (
   id          integer constraint channels_dim_pk primary key
 , name        varchar2(20 char) not null
 , shortcut    varchar2(2  char) not null
);

create table gender_dim (
   letter      char(1 char) constraint gender_dim_pk primary key
 , name        varchar2(10 char)
);

create table packaging (
   id          integer constraint packaging_pk primary key
 , name        varchar2(20 char) not null
);

create table packaging_relations (
   packaging_id   not null constraint packing_relations_parent_fk
                              references packaging
 , contains_id    not null constraint packing_relations_child_fk
                              references packaging
 , qty            integer not null
 , constraint packaging_relations_pk primary key (packaging_id, contains_id)
);

create index packing_relations_child_fk_ix on packaging_relations (contains_id);

create table product_groups (
   id          integer constraint product_groups_pk primary key
 , name        varchar2(20 char) not null
);

create table products (
   id          integer constraint products_pk primary key
 , name        varchar2(20 char) not null
 , group_id    not null constraint products_product_groups_fk
                           references product_groups
);

create index products_product_groups_fk_ix on products (group_id);

create table monthly_sales (
   product_id  not null constraint monthly_sales_product_fk
                           references products
 , mth         date     not null
 , qty         number   not null
 , constraint monthly_sales_pk primary key (product_id, mth)
 , constraint monthly_sales_mth_valid check (
      mth = trunc(mth, 'MM')
   )
);

create table breweries (
   id          integer constraint brewery_pk primary key
 , name        varchar2(20 char) not null
);

create table purchases (
   id          integer constraint purchases_pk primary key
 , purchased   date     not null
 , brewery_id  not null constraint purchases_brewery_fk
                           references breweries
 , product_id  not null constraint purchases_product_fk
                           references products
 , qty         number   not null
 , cost        number   not null
);

create index purchases_brewery_fk_ix on purchases (brewery_id);

create index purchases_product_fk_ix on purchases (product_id);

create table product_alcohol (
   product_id     not null constraint product_alcohol_pk primary key
                           constraint product_alcohol_product_fk
                              references products
 , sales_volume   number   not null
 , abv            number   not null
);

create table customer_favorites (
   customer_id    not null constraint customer_favorites_customer_fk
                              references customers
 , favorite_list  varchar2(4000 char)
 , constraint customer_favorites_pk primary key (customer_id)
);

create table customer_reviews (
   customer_id    not null constraint customer_reviews_customer_fk
                              references customers
 , review_list    varchar2(4000 char)
 , constraint customer_reviews_pk primary key (customer_id)
);

create table locations (
   id          integer constraint location_pk primary key
 , warehouse   integer     not null
 , aisle       varchar2(1) not null
 , position    integer     not null
 , constraint locations_uq unique (warehouse, aisle, position)
);

create table inventory (
   id          integer  constraint inventory_pk primary key
 , location_id not null constraint inventory_location_fk
                           references locations
 , product_id  not null constraint inventory_product_fk
                           references products
 , purchase_id not null constraint inventory_purchase_fk
                           references purchases
 , qty         number   not null
);

create index inventory_location_fk_ix on inventory (location_id);

create index inventory_product_fk_ix on inventory (product_id);

create index inventory_purchase_fk_ix on inventory (purchase_id);

create table orders (
   id          integer  constraint order_pk primary key
 , customer_id not null constraint order_customer_fk
                           references customers
 , ordered     date
 , delivery    date
);

create index order_customer_fk_ix on orders (customer_id);

create table orderlines (
   id          integer  constraint orderline_pk primary key
 , order_id    not null constraint orderline_order_fk
                           references orders
 , product_id  not null constraint orderline_product_fk
                           references products
 , qty         number   not null
 , amount      number   not null
);

create index orderline_order_fk_ix on orderlines (order_id);

create table monthly_budget (
   product_id  not null constraint monthly_budget_product_fk
                           references products
 , mth         date     not null
 , qty         number   not null
 , constraint monthly_budget_pk primary key (product_id, mth)
 , constraint monthly_budget_mth_valid check (
      mth = trunc(mth, 'MM')
   )
);

create table product_minimums (
   product_id     not null constraint product_minimums_pk primary key
                           constraint product_minimums_product_fk
                              references products
 , qty_minimum    number   not null
 , qty_purchase   number   not null
);

create table stock (
   symbol   varchar2(10) constraint stock_pk primary key
 , company  varchar2(40) not null
);

create table ticker (
   symbol   constraint ticker_symbol_fk references stock
 , day      date   not null
 , price    number not null
 , constraint ticker_pk primary key (symbol, day)
);

create table web_apps (
   id             integer constraint web_apps_pk primary key
 , name           varchar2(20 char) not null
);

create table web_pages (
   app_id         not null constraint web_pages_app_fk
                     references web_apps
 , page_no        integer not null
 , friendly_url   varchar2(20 char) not null
 , constraint web_pages_pk primary key (app_id, page_no)
);

create table web_counter_hist (
   app_id      integer not null
 , page_no     integer not null
 , day         date    not null
 , counter     integer not null
 , constraint web_counter_hist_pk primary key (app_id, page_no, day)
 , constraint web_counter_hist_page_fk foreign key (app_id, page_no)
      references web_pages (app_id, page_no)
);

create table server_heartbeat (
   server      varchar2(15 char) not null
 , beat_time   date              not null
 , constraint server_heartbeat_uq unique (
      server, beat_time
   )
);

create table web_page_visits (
   client_ip   varchar2(15 char) not null
 , visit_time  date              not null
 , app_id      integer           not null
 , page_no     integer           not null
 , constraint web_page_visits_page_fk foreign key (app_id, page_no)
      references web_pages (app_id, page_no)
);

create index web_page_visits_page_fk_ix on web_page_visits (app_id, page_no);

create table employees (
   id             integer constraint employees_pk primary key
 , name           varchar2(20 char) not null
 , title          varchar2(20 char) not null
 , supervisor_id  constraint employees_supervisor_fk
                     references employees
);

create index employees_supervisor_fk_ix on employees (supervisor_id);

create table emp_hire_periods (
   emp_id         not null constraint emp_hire_periods_emp_fk
                     references employees
 , start_date     date not null
 , end_date       date
 , title          varchar2(20 char) not null
 , constraint emp_hire_periods_pk primary key (emp_id, start_date)
 , period for employed_in (start_date, end_date)
);

create table picking_list (
   id             integer constraint picking_list_pk primary key
 , created        date not null
 , picker_emp_id  constraint picking_list_emp_fk
                     references employees
);

create index picking_list_emp_fk_ix on picking_list (picker_emp_id);

create table picking_line (
   picklist_id    not null constraint picking_line_picking_list_fk
                     references picking_list
 , line_no        integer not null
 , location_id    not null constraint picking_line_location_fk
                     references locations
 , order_id       not null constraint picking_line_order_fk
                     references orders
 , product_id     not null constraint picking_line_product_fk
                     references products
 , qty            number not null
 , constraint     picking_line_pk primary key (picklist_id, line_no)
);

create index picking_line_location_fk_ix on picking_line (location_id);

create index picking_line_order_fk_ix on picking_line (order_id);

create index picking_line_product_fk_ix on picking_line (product_id);

create table picking_log (
   picklist_id    not null constraint picking_log_picking_list_fk
                     references picking_list
 , log_time       date not null
 , activity       varchar2(1 char) not null
                     check (activity in ('A', 'P', 'D'))
 , location_id    constraint picking_log_location_fk
                     references locations
 , pickline_no    integer
 , constraint picking_log_picking_line_fk foreign key (picklist_id, pickline_no)
      references picking_line (picklist_id, line_no)
 , constraint picking_log_picking_line_ck
      check (not (activity = 'P' and pickline_no is null))
);

create index picking_log_picking_line_fk_ix on picking_log (picklist_id, pickline_no);

create index picking_log_location_fk on picking_log (location_id);

/* -----------------------------------------------------
   Create types and type bodies
   ----------------------------------------------------- */

create or replace type id_name_type as object (
   id     integer
 , name   varchar2(20 char)
);
/

create or replace type id_name_coll_type
   as table of id_name_type;
/

create type favorite_coll_type
   as table of integer;
/

/*
   ODCI implementation of delimited string parsing
   https://www.kibeha.dk/2015/06/supposing-youve-got-data-as-text-string.html
*/

create or replace type delimited_col_row as object (
 
   g_buffer          varchar2(32000)
 , g_type            anytype
 , g_numcols         integer
 , g_col_types       sys.odcinumberlist
 , g_col_delim       varchar2(1)
 , g_row_delim       varchar2(1)
 , g_pos1            integer
 , g_pos2            integer
 , g_col_num         integer
 , g_row_num         integer
 
 , static function parser(
      p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return anydataset pipelined
     using delimited_col_row
 
 , static function odcitabledescribe(
      p_tabtype   out   anytype
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
 
 , static function odcitableprepare(
      p_context   out   delimited_col_row
    , p_tabinfo   in    sys.odcitabfuncinfo
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
 
 , static function odcitablestart(
      p_context   in out delimited_col_row
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
 
 , member function odcitablefetch(
      self      in out delimited_col_row
    , p_numrows   in    number
    , p_tab       out   anydataset
   ) return number
 
 , member function odcitableclose(
      self      in    delimited_col_row
   ) return number
)
/

create or replace type body delimited_col_row as
 
   static function odcitabledescribe(
      p_tabtype   out   anytype
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
   is
      l_type      anytype;
      l_numcols   integer;
       
      l_pos1      pls_integer;
      l_pos2      pls_integer;
      l_pos3      pls_integer;
      l_colname   varchar2(1932);
      l_coltype   varchar2(1932);
   begin
      anytype.begincreate(dbms_types.typecode_object, l_type);
 
      l_pos1 := 0;
      loop
         l_pos2 := instr(p_cols, p_col_delim, l_pos1+1);
         l_pos3 := nvl(nullif(instr(p_cols, p_row_delim, l_pos1+1),0),length(p_cols)+1);
 
         l_colname := substr(p_cols, l_pos1+1, l_pos2-l_pos1-1);
         l_coltype := upper(substr(p_cols, l_pos2+1, l_pos3-l_pos2-1));
 
         if l_colname like '"%"' then
            l_colname := trim(both '"' from l_colname);
         else
            l_colname := upper(l_colname);
         end if;
          
         case
            when l_coltype like 'VARCHAR2(%)' then
               l_type.addattr(
                  l_colname
                , dbms_types.typecode_varchar2
                , null
                , null
                , to_number(trim(substr(l_coltype,10,length(l_coltype)-10)))
                , null
                , null
               );
 
            when l_coltype = 'NUMBER' then
               l_type.addattr(
                  l_colname
                , dbms_types.typecode_number
                , null
                , null
                , null
                , null
                , null
               );
 
            when l_coltype = 'DATE' then
               l_type.addattr(
                  l_colname
                , dbms_types.typecode_date
                , null
                , null
                , null
                , null
                , null
               );
 
            else
               raise dbms_types.invalid_parameters;
         end case;
          
         exit when l_pos3 > length(p_cols);
         l_pos1 := l_pos3;
      end loop;
       
      l_type.endcreate;
 
      anytype.begincreate(dbms_types.typecode_table, p_tabtype);
 
      p_tabtype.setinfo(
         null
       , null
       , null
       , null
       , null
       , l_type
       , dbms_types.typecode_object
       , 0
      );
 
      p_tabtype.endcreate();
 
      return odciconst.success;
 
   exception
      when others then
         return odciconst.error;
   end odcitabledescribe;

   static function odcitableprepare(
      p_context   out   delimited_col_row
    , p_tabinfo   in    sys.odcitabfuncinfo
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
   is
      l_type      anytype;
      l_numcols   integer;
      l_col_types sys.odcinumberlist := sys.odcinumberlist();
    
      l_typecode  pls_integer;
      l_prec      pls_integer;
      l_scale     pls_integer;
      l_len       pls_integer;
      l_csid      pls_integer;
      l_csfrm     pls_integer;
      l_aname     varchar2(30);
      l_schemaname varchar2(30);
      l_typename  varchar2(30);
      l_version   varchar2(30);
      l_dummytype anytype;
   begin
      l_typecode := p_tabinfo.rettype.getattreleminfo(
                 1
               , l_prec
               , l_scale
               , l_len
               , l_csid
               , l_csfrm
               , l_type
               , l_aname
              );
    
      l_typecode := l_type.getinfo(
                 l_prec
               , l_scale
               , l_len
               , l_csid
               , l_csfrm
               , l_schemaname
               , l_typename
               , l_version
               , l_numcols
              );
       
      l_col_types.extend(l_numcols);
        
      for idx in 1..l_numcols loop
         l_col_types(idx) := l_type.getattreleminfo(
                    idx
                  , l_prec
                  , l_scale
                  , l_len
                  , l_csid
                  , l_csfrm
                  , l_dummytype
                  , l_aname
                 );
      end loop;
       
      p_context := delimited_col_row(
                      p_text
                    , l_type
                    , l_numcols
                    , l_col_types
                    , p_col_delim
                    , p_row_delim
                    , 0
                    , 0
                    , 0
                    , 0
                   );
    
      return odciconst.success;
   end odcitableprepare;

   static function odcitablestart(
      p_context   in out delimited_col_row
    , p_text      in    varchar2
    , p_cols      in    varchar2
    , p_col_delim in    varchar2 default '|'
    , p_row_delim in    varchar2 default ';'
   ) return number
   is
   begin
      p_context.g_buffer := p_text;
       
      p_context.g_pos1    := 0;
      p_context.g_pos2    := 0;
      p_context.g_col_num := 0;
      p_context.g_row_num := 0;
    
      return odciconst.success;
   end odcitablestart;

   member function odcitablefetch(
      self        in out delimited_col_row
    , p_numrows   in    number
    , p_tab       out   anydataset
   ) return number
   is
      l_row_cnt   integer := 0;
   begin
      if self.g_pos2 < length(self.g_buffer) then
         anydataset.begincreate(dbms_types.typecode_object, self.g_type, p_tab);
          
         loop
            self.g_col_num := self.g_col_num + 1;
             
            if self.g_col_num = 1 then
               l_row_cnt      := l_row_cnt + 1;
               self.g_row_num := self.g_row_num + 1;
               p_tab.addinstance;
               p_tab.piecewise();
            end if;
    
            if self.g_col_num < self.g_numcols then
               self.g_pos2 := instr(self.g_buffer, self.g_col_delim, self.g_pos1+1);
            else
               self.g_pos2 := nvl(nullif(instr(self.g_buffer, self.g_row_delim, self.g_pos1+1),0),length(self.g_buffer)+1);
            end if;
             
            case self.g_col_types(self.g_col_num)
               when dbms_types.typecode_varchar2 then
                  p_tab.setvarchar2(substr(self.g_buffer, self.g_pos1+1, self.g_pos2-self.g_pos1-1));
                
               when dbms_types.typecode_number then
                  p_tab.setnumber(to_number(substr(self.g_buffer, self.g_pos1+1, self.g_pos2-self.g_pos1-1)));
                
               when dbms_types.typecode_date then
                  p_tab.setdate(to_date(substr(self.g_buffer, self.g_pos1+1, self.g_pos2-self.g_pos1-1)));
            end case;
             
            exit when self.g_pos2 > length(self.g_buffer);
            self.g_pos1 := self.g_pos2;
    
            if self.g_col_num = self.g_numcols then
               self.g_col_num := 0;
               exit when l_row_cnt >= p_numrows;
            end if;
         end loop;
    
         p_tab.endcreate;
      end if;
      return odciconst.success;
   end odcitablefetch;

   member function odcitableclose(
      self      in    delimited_col_row
   ) return number
   is
   begin
      return odciconst.success;
   end odcitableclose;
 
end;
/

/* Should really be:

create type name_coll_type
   as table of varchar2(20 char);

   But an Oracle bug requires workaround with 80 byte:
*/

create or replace type name_coll_type
   as table of varchar2(80 byte);
/

/*
   ODCI implementation of string aggregate function - based on example by Tom Kyte
   https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:2196162600402
*/

create or replace type stragg_expr_type as object (
   element    varchar2(4000 char)
 , delimiter  varchar2(4000 char)
 , map member function map_func return varchar2
);
/

create or replace type body stragg_expr_type
as
   map member function map_func return varchar2
   is
   begin
      return element || '|' || delimiter;
   end map_func;
end;
/

create or replace type stragg_type as object
(
   aggregated varchar2(4000)
 , delimiter  varchar2(4000)

 , static function ODCIAggregateInitialize(
      new_self    in out stragg_type
   ) return number

 , member function ODCIAggregateIterate(
      self        in out stragg_type
    , value       in     stragg_expr_type
   ) return number

 , member function ODCIAggregateTerminate(
      self        in     stragg_type
    , returnvalue out    varchar2
    , flags       in     number
   ) return number

 , member function ODCIAggregateMerge(
      self        in out stragg_type
    , other_self  in     stragg_type
   ) return number
);
/

create or replace type body stragg_type
is
   static function ODCIAggregateInitialize(
      new_self    in out stragg_type
   ) return number
   is
   begin
      new_self := stragg_type( null, null );
      return ODCIConst.Success;
   end ODCIAggregateInitialize;

   member function ODCIAggregateIterate(
      self        in out stragg_type
    , value       in     stragg_expr_type
   ) return number
   is
   begin
      if self.delimiter is null then
         self.delimiter := value.delimiter;
      end if;
      self.aggregated := self.aggregated
                      || self.delimiter
                      || value.element;
      return ODCIConst.Success;
   end ODCIAggregateIterate;

   member function ODCIAggregateTerminate(
      self        in     stragg_type
    , returnvalue out    varchar2
    , flags       in     number
   ) return number
   is
   begin
      returnvalue := substr(
                        self.aggregated
                      , nvl(length(self.delimiter),0) + 1
                     );
      return ODCIConst.Success;
   end ODCIAggregateTerminate;

   member function ODCIAggregateMerge(
      self        in out stragg_type
    , other_self  in     stragg_type
   ) return number
   is
   begin
      if self.delimiter is null then
         self.delimiter := other_self.delimiter;
      end if;
      self.aggregated := self.aggregated
                      || other_self.aggregated;
      return ODCIConst.Success;
   end ODCIAggregateMerge;
end;
/

/* -----------------------------------------------------
   Create packages, functions and procedures
   ----------------------------------------------------- */

create or replace package formulas
is
   function bac (
      p_volume in number
    , p_abv    in number
    , p_weight in number
    , p_gender in varchar2
   ) return number deterministic;
end formulas;
/

create or replace package body formulas
is
   function bac (
      p_volume in number
    , p_abv    in number
    , p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
      PRAGMA UDF;
   begin
      return round(
         100 * (p_volume * p_abv / 100 * 0.789)
          / (p_weight * 1000 * case p_gender
                                  when 'M' then 0.68
                                  when 'F' then 0.55
                               end)
       , 3
      );
   end bac;
end formulas;
/

create or replace function favorite_list_to_coll_type (
   p_favorite_list   in customer_favorites.favorite_list%type
)
   return favorite_coll_type pipelined
is
   v_from_pos  pls_integer;
   v_to_pos    pls_integer;
begin
   if p_favorite_list is not null then
      v_from_pos := 1;
      loop
         v_to_pos := instr(p_favorite_list, ',', v_from_pos);
         pipe row (to_number(
            substr(
               p_favorite_list
             , v_from_pos
             , case v_to_pos
                  when 0 then length(p_favorite_list) + 1
                         else v_to_pos
               end - v_from_pos
            )
         ));
         exit when v_to_pos = 0;
         v_from_pos := v_to_pos + 1;
      end loop;
   end if;
end favorite_list_to_coll_type;
/

create or replace function name_coll_type_to_varchar2 (
   p_name_coll    in name_coll_type
 , p_delimiter    in varchar2 default null
)
   return varchar2
is
   v_name_string  varchar2(4000 char);
begin
   for idx in p_name_coll.first..p_name_coll.last
   loop
      if idx = p_name_coll.first then
         v_name_string := p_name_coll(idx);
      else
         v_name_string := v_name_string
                       || p_delimiter
                       || p_name_coll(idx);
      end if;
   end loop;
   return v_name_string;
end name_coll_type_to_varchar2;
/

create or replace function stragg(input stragg_expr_type )
   return varchar2
   parallel_enable aggregate using stragg_type;
/

/* -----------------------------------------------------
   Create views
   ----------------------------------------------------- */

create or replace view customer_order_products
as
select
   c.id     as customer_id
 , c.name   as customer_name
 , o.ordered
 , p.id     as product_id
 , p.name   as product_name
 , ol.qty
from customers c
join orders o
   on o.customer_id = c.id
join orderlines ol
   on ol.order_id = o.id
join products p
   on p.id = ol.product_id;

create or replace view customer_order_products_obj
as
select
   customer_id
 , max(customer_name) as customer_name
 , cast(
      collect(
         id_name_type(product_id, product_name)
         order by product_id
      )
      as id_name_coll_type
   ) as product_coll
from customer_order_products
group by customer_id;

create view product_alcohol_bac
as
with
   function gram_alcohol (
      p_volume in number
    , p_abv    in number
   ) return number deterministic
   is
   begin
      return p_volume * p_abv / 100 * 0.789;
   end;
   function gram_body_fluid (
      p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
   begin
      return p_weight * 1000 * case p_gender
                                  when 'M' then 0.68
                                  when 'F' then 0.55
                               end;
   end;
   function bac (
      p_volume in number
    , p_abv    in number
    , p_weight in number
    , p_gender in varchar2
   ) return number deterministic
   is
   begin
      return round(
         100 * gram_alcohol(p_volume, p_abv)
          / gram_body_fluid(p_weight, p_gender)
       , 3
      );
   end;
select
   pa.product_id
 , pa.sales_volume
 , pa.abv
 , bac(pa.sales_volume, pa.abv, 80, 'M') bac_m
 , bac(pa.sales_volume, pa.abv, 60, 'F') bac_f
from product_alcohol pa
/

create or replace view purchases_with_dims
as
select
   pu.id
 , pu.purchased
 , pu.brewery_id
 , b.name as brewery_name
 , pu.product_id
 , p.name as product_name
 , p.group_id
 , pg.name as group_name
 , pu.qty
 , pu.cost
from purchases pu
join breweries b
   on b.id = pu.brewery_id
join products p
   on p.id = pu.product_id
join product_groups pg
   on pg.id = p.group_id;

create or replace view brewery_products
as
select
   b.id   as brewery_id
 , b.name as brewery_name
 , p.id   as product_id
 , p.name as product_name
from breweries b
cross join products p
where exists (
   select null
   from purchases pu
   where pu.brewery_id = b.id
   and   pu.product_id = p.id
);

create or replace view total_sales
as
select
   ms.product_id
 , max(p.name) as product_name
 , sum(ms.qty) as total_qty
from products p
join monthly_sales ms
   on ms.product_id = p.id
group by
   ms.product_id;

create or replace view yearly_sales
as
select
   extract(year from ms.mth) as yr
 , ms.product_id
 , max(p.name) as product_name
 , sum(ms.qty) as yr_qty
from products p
join monthly_sales ms
   on ms.product_id = p.id
group by
   extract(year from ms.mth), ms.product_id;

create or replace view inventory_with_dims
as
select
   i.id
 , i.product_id
 , p.name as product_name
 , i.purchase_id
 , pu.purchased
 , i.location_id
 , l.warehouse
 , l.aisle
 , l.position
 , i.qty
from inventory i
join purchases pu
   on pu.id = i.purchase_id
join products p
   on p.id = i.product_id
join locations l
   on l.id = i.location_id;

create or replace view inventory_totals
as
select
   i.product_id
 , sum(i.qty) as qty
from inventory i
group by i.product_id;

create or replace view monthly_orders
as
select
   ol.product_id
 , trunc(o.ordered, 'MM') as mth
 , sum(ol.qty) as qty
from orders o
join orderlines ol
   on ol.order_id = o.id
group by ol.product_id, trunc(o.ordered, 'MM');

create or replace view emp_hire_periods_with_name
as
select
   ehp.emp_id
 , e.name
 , ehp.start_date
 , ehp.end_date
 , ehp.title
from emp_hire_periods ehp
join employees e
   on e.id = ehp.emp_id;

create or replace view web_page_counter_hist
as
select
   ch.app_id
 , a.name as app_name
 , ch.page_no
 , p.friendly_url
 , ch.day
 , ch.counter
from web_apps a
join web_pages p
   on p.app_id = a.id
join web_counter_hist ch
   on ch.app_id = p.app_id
   and ch.page_no = p.page_no;

/* -----------------------------------------------------
   Insert data
   ----------------------------------------------------- */

insert into web_devices values (date '2019-05-01', 1042,  812, 1610);
insert into web_devices values (date '2019-05-02',  967, 1102, 2159);

insert into web_demographics values (date '2019-05-01', 1232,  86, 1017, 64, 651, 76, 564, 68);
insert into web_demographics values (date '2019-05-02', 1438, 142, 1198, 70, 840, 92, 752, 78);

insert into channels_dim values (42, 'Twitter' , 'tw');
insert into channels_dim values (44, 'Facebook', 'fb');

insert into gender_dim values ('F', 'Female');
insert into gender_dim values ('M', 'Male');

insert into packaging values (501, 'Bottle 330cl');
insert into packaging values (502, 'Bottle 500cl');
insert into packaging values (511, 'Gift Carton');
insert into packaging values (521, 'Box Large');
insert into packaging values (522, 'Box Medium');
insert into packaging values (523, 'Box Small');
insert into packaging values (524, 'Gift Box');
insert into packaging values (531, 'Pallet of L');
insert into packaging values (532, 'Pallet of M');
insert into packaging values (533, 'Pallet Mix MS');
insert into packaging values (534, 'Pallet Mix SG');

insert into packaging_relations values (511, 501,  3);
insert into packaging_relations values (511, 502,  2);
insert into packaging_relations values (521, 502, 72);
insert into packaging_relations values (522, 501, 36);
insert into packaging_relations values (523, 502, 30);
insert into packaging_relations values (524, 511,  8);
insert into packaging_relations values (531, 521, 12);
insert into packaging_relations values (532, 522, 20);
insert into packaging_relations values (533, 522, 10);
insert into packaging_relations values (533, 523, 20);
insert into packaging_relations values (534, 523, 20);
insert into packaging_relations values (534, 524, 16);

insert into product_groups values (142, 'Stout');
insert into product_groups values (152, 'Belgian');
insert into product_groups values (202, 'Wheat');
insert into product_groups values (232, 'IPA');

insert into products values (4040, 'Coalminers Sweat', 142);
insert into products values (4160, 'Reindeer Fuel'   , 142);
insert into products values (4280, 'Hoppy Crude Oil' , 142);
insert into products values (5310, 'Monks and Nuns'  , 152);
insert into products values (5430, 'Hercule Trippel' , 152);
insert into products values (6520, 'Der Helle Kumpel', 202);
insert into products values (6600, 'Hazy Pink Cloud' , 202);
insert into products values (7790, 'Summer in India' , 232);
insert into products values (7870, 'Ghost of Hops'   , 232);
insert into products values (7950, 'Pale Rider Rides', 232);

--4040, 'Coalminers Sweat'
insert into monthly_sales values (4040, date '2016-01-01',   42);
insert into monthly_sales values (4040, date '2016-02-01',   37);
insert into monthly_sales values (4040, date '2016-03-01',   39);
insert into monthly_sales values (4040, date '2016-04-01',   22);
insert into monthly_sales values (4040, date '2016-05-01',   11);
insert into monthly_sales values (4040, date '2016-06-01',    6);
insert into monthly_sales values (4040, date '2016-07-01',    7);
insert into monthly_sales values (4040, date '2016-08-01',   14);
insert into monthly_sales values (4040, date '2016-09-01',   25);
insert into monthly_sales values (4040, date '2016-10-01',   12);
insert into monthly_sales values (4040, date '2016-11-01',   27);
insert into monthly_sales values (4040, date '2016-12-01',   44);
insert into monthly_sales values (4040, date '2017-01-01',   33);
insert into monthly_sales values (4040, date '2017-02-01',   34);
insert into monthly_sales values (4040, date '2017-03-01',   18);
insert into monthly_sales values (4040, date '2017-04-01',   19);
insert into monthly_sales values (4040, date '2017-05-01',    2);
insert into monthly_sales values (4040, date '2017-06-01',   12);
insert into monthly_sales values (4040, date '2017-07-01',   21);
insert into monthly_sales values (4040, date '2017-08-01',    8);
insert into monthly_sales values (4040, date '2017-09-01',    9);
insert into monthly_sales values (4040, date '2017-10-01',   18);
insert into monthly_sales values (4040, date '2017-11-01',   22);
insert into monthly_sales values (4040, date '2017-12-01',   31);
insert into monthly_sales values (4040, date '2018-01-01',   50);
insert into monthly_sales values (4040, date '2018-02-01',   55);
insert into monthly_sales values (4040, date '2018-03-01',   11);
insert into monthly_sales values (4040, date '2018-04-01',   43);
insert into monthly_sales values (4040, date '2018-05-01',   24);
insert into monthly_sales values (4040, date '2018-06-01',   16);
insert into monthly_sales values (4040, date '2018-07-01',    6);
insert into monthly_sales values (4040, date '2018-08-01',    5);
insert into monthly_sales values (4040, date '2018-09-01',   17);
insert into monthly_sales values (4040, date '2018-10-01',   17);
insert into monthly_sales values (4040, date '2018-11-01',   29);
insert into monthly_sales values (4040, date '2018-12-01',   27);
--4160, 'Reindeer Fuel'
insert into monthly_sales values (4160, date '2016-01-01',   79);
insert into monthly_sales values (4160, date '2016-02-01',  133);
insert into monthly_sales values (4160, date '2016-03-01',   24);
insert into monthly_sales values (4160, date '2016-04-01',    1);
insert into monthly_sales values (4160, date '2016-05-01',    0);
insert into monthly_sales values (4160, date '2016-06-01',    0);
insert into monthly_sales values (4160, date '2016-07-01',    0);
insert into monthly_sales values (4160, date '2016-08-01',    0);
insert into monthly_sales values (4160, date '2016-09-01',    1);
insert into monthly_sales values (4160, date '2016-10-01',    4);
insert into monthly_sales values (4160, date '2016-11-01',   15);
insert into monthly_sales values (4160, date '2016-12-01',   74);
insert into monthly_sales values (4160, date '2017-01-01',  148);
insert into monthly_sales values (4160, date '2017-02-01',  209);
insert into monthly_sales values (4160, date '2017-03-01',   30);
insert into monthly_sales values (4160, date '2017-04-01',    2);
insert into monthly_sales values (4160, date '2017-05-01',    0);
insert into monthly_sales values (4160, date '2017-06-01',    0);
insert into monthly_sales values (4160, date '2017-07-01',    0);
insert into monthly_sales values (4160, date '2017-08-01',    1);
insert into monthly_sales values (4160, date '2017-09-01',    0);
insert into monthly_sales values (4160, date '2017-10-01',    3);
insert into monthly_sales values (4160, date '2017-11-01',   17);
insert into monthly_sales values (4160, date '2017-12-01',  172);
insert into monthly_sales values (4160, date '2018-01-01',  167);
insert into monthly_sales values (4160, date '2018-02-01',  247);
insert into monthly_sales values (4160, date '2018-03-01',   42);
insert into monthly_sales values (4160, date '2018-04-01',    0);
insert into monthly_sales values (4160, date '2018-05-01',    0);
insert into monthly_sales values (4160, date '2018-06-01',    0);
insert into monthly_sales values (4160, date '2018-07-01',    0);
insert into monthly_sales values (4160, date '2018-08-01',    1);
insert into monthly_sales values (4160, date '2018-09-01',    0);
insert into monthly_sales values (4160, date '2018-10-01',    1);
insert into monthly_sales values (4160, date '2018-11-01',   73);
insert into monthly_sales values (4160, date '2018-12-01',  160);
--4280, 'Hoppy Crude Oil'
insert into monthly_sales values (4280, date '2016-01-01',   15);
insert into monthly_sales values (4280, date '2016-02-01',    9);
insert into monthly_sales values (4280, date '2016-03-01',    3);
insert into monthly_sales values (4280, date '2016-04-01',    6);
insert into monthly_sales values (4280, date '2016-05-01',    8);
insert into monthly_sales values (4280, date '2016-06-01',    2);
insert into monthly_sales values (4280, date '2016-07-01',    0);
insert into monthly_sales values (4280, date '2016-08-01',    3);
insert into monthly_sales values (4280, date '2016-09-01',   11);
insert into monthly_sales values (4280, date '2016-10-01',    9);
insert into monthly_sales values (4280, date '2016-11-01',   15);
insert into monthly_sales values (4280, date '2016-12-01',   18);
insert into monthly_sales values (4280, date '2017-01-01',    9);
insert into monthly_sales values (4280, date '2017-02-01',    9);
insert into monthly_sales values (4280, date '2017-03-01',    5);
insert into monthly_sales values (4280, date '2017-04-01',    0);
insert into monthly_sales values (4280, date '2017-05-01',    6);
insert into monthly_sales values (4280, date '2017-06-01',    2);
insert into monthly_sales values (4280, date '2017-07-01',    0);
insert into monthly_sales values (4280, date '2017-08-01',    1);
insert into monthly_sales values (4280, date '2017-09-01',    8);
insert into monthly_sales values (4280, date '2017-10-01',   12);
insert into monthly_sales values (4280, date '2017-11-01',    6);
insert into monthly_sales values (4280, date '2017-12-01',   14);
insert into monthly_sales values (4280, date '2018-01-01',    9);
insert into monthly_sales values (4280, date '2018-02-01',   13);
insert into monthly_sales values (4280, date '2018-03-01',   16);
insert into monthly_sales values (4280, date '2018-04-01',    7);
insert into monthly_sales values (4280, date '2018-05-01',    5);
insert into monthly_sales values (4280, date '2018-06-01',    4);
insert into monthly_sales values (4280, date '2018-07-01',    5);
insert into monthly_sales values (4280, date '2018-08-01',    9);
insert into monthly_sales values (4280, date '2018-09-01',    8);
insert into monthly_sales values (4280, date '2018-10-01',   17);
insert into monthly_sales values (4280, date '2018-11-01',   18);
insert into monthly_sales values (4280, date '2018-12-01',   21);
--5310, 'Monks and Nuns'
insert into monthly_sales values (5310, date '2016-01-01',   35);
insert into monthly_sales values (5310, date '2016-02-01',   46);
insert into monthly_sales values (5310, date '2016-03-01',   47);
insert into monthly_sales values (5310, date '2016-04-01',   34);
insert into monthly_sales values (5310, date '2016-05-01',   32);
insert into monthly_sales values (5310, date '2016-06-01',   48);
insert into monthly_sales values (5310, date '2016-07-01',   37);
insert into monthly_sales values (5310, date '2016-08-01',   43);
insert into monthly_sales values (5310, date '2016-09-01',   44);
insert into monthly_sales values (5310, date '2016-10-01',   31);
insert into monthly_sales values (5310, date '2016-11-01',   49);
insert into monthly_sales values (5310, date '2016-12-01',   32);
insert into monthly_sales values (5310, date '2017-01-01',   39);
insert into monthly_sales values (5310, date '2017-02-01',   37);
insert into monthly_sales values (5310, date '2017-03-01',   46);
insert into monthly_sales values (5310, date '2017-04-01',   43);
insert into monthly_sales values (5310, date '2017-05-01',   52);
insert into monthly_sales values (5310, date '2017-06-01',   54);
insert into monthly_sales values (5310, date '2017-07-01',   58);
insert into monthly_sales values (5310, date '2017-08-01',   53);
insert into monthly_sales values (5310, date '2017-09-01',   59);
insert into monthly_sales values (5310, date '2017-10-01',   49);
insert into monthly_sales values (5310, date '2017-11-01',   45);
insert into monthly_sales values (5310, date '2017-12-01',   47);
insert into monthly_sales values (5310, date '2018-01-01',   45);
insert into monthly_sales values (5310, date '2018-02-01',   50);
insert into monthly_sales values (5310, date '2018-03-01',   43);
insert into monthly_sales values (5310, date '2018-04-01',   46);
insert into monthly_sales values (5310, date '2018-05-01',   31);
insert into monthly_sales values (5310, date '2018-06-01',   33);
insert into monthly_sales values (5310, date '2018-07-01',   35);
insert into monthly_sales values (5310, date '2018-08-01',   34);
insert into monthly_sales values (5310, date '2018-09-01',   26);
insert into monthly_sales values (5310, date '2018-10-01',   25);
insert into monthly_sales values (5310, date '2018-11-01',   24);
insert into monthly_sales values (5310, date '2018-12-01',   33);
--5430, 'Hercule Trippel' 
insert into monthly_sales values (5430, date '2016-01-01',   25);
insert into monthly_sales values (5430, date '2016-02-01',   20);
insert into monthly_sales values (5430, date '2016-03-01',   23);
insert into monthly_sales values (5430, date '2016-04-01',   23);
insert into monthly_sales values (5430, date '2016-05-01',   15);
insert into monthly_sales values (5430, date '2016-06-01',   16);
insert into monthly_sales values (5430, date '2016-07-01',   14);
insert into monthly_sales values (5430, date '2016-08-01',   16);
insert into monthly_sales values (5430, date '2016-09-01',   27);
insert into monthly_sales values (5430, date '2016-10-01',   30);
insert into monthly_sales values (5430, date '2016-11-01',   28);
insert into monthly_sales values (5430, date '2016-12-01',   24);
insert into monthly_sales values (5430, date '2017-01-01',   31);
insert into monthly_sales values (5430, date '2017-02-01',   30);
insert into monthly_sales values (5430, date '2017-03-01',   34);
insert into monthly_sales values (5430, date '2017-04-01',   29);
insert into monthly_sales values (5430, date '2017-05-01',   26);
insert into monthly_sales values (5430, date '2017-06-01',   25);
insert into monthly_sales values (5430, date '2017-07-01',   27);
insert into monthly_sales values (5430, date '2017-08-01',   19);
insert into monthly_sales values (5430, date '2017-09-01',   26);
insert into monthly_sales values (5430, date '2017-10-01',   34);
insert into monthly_sales values (5430, date '2017-11-01',   32);
insert into monthly_sales values (5430, date '2017-12-01',   31);
insert into monthly_sales values (5430, date '2018-01-01',   36);
insert into monthly_sales values (5430, date '2018-02-01',   40);
insert into monthly_sales values (5430, date '2018-03-01',   41);
insert into monthly_sales values (5430, date '2018-04-01',   34);
insert into monthly_sales values (5430, date '2018-05-01',   31);
insert into monthly_sales values (5430, date '2018-06-01',   32);
insert into monthly_sales values (5430, date '2018-07-01',   33);
insert into monthly_sales values (5430, date '2018-08-01',   37);
insert into monthly_sales values (5430, date '2018-09-01',   45);
insert into monthly_sales values (5430, date '2018-10-01',   42);
insert into monthly_sales values (5430, date '2018-11-01',   41);
insert into monthly_sales values (5430, date '2018-12-01',   39);
--6520, 'Der Helle Kumpel'
insert into monthly_sales values (6520, date '2016-01-01',   13);
insert into monthly_sales values (6520, date '2016-02-01',   16);
insert into monthly_sales values (6520, date '2016-03-01',    9);
insert into monthly_sales values (6520, date '2016-04-01',    8);
insert into monthly_sales values (6520, date '2016-05-01',   41);
insert into monthly_sales values (6520, date '2016-06-01',   61);
insert into monthly_sales values (6520, date '2016-07-01',   66);
insert into monthly_sales values (6520, date '2016-08-01',   57);
insert into monthly_sales values (6520, date '2016-09-01',   53);
insert into monthly_sales values (6520, date '2016-10-01',   48);
insert into monthly_sales values (6520, date '2016-11-01',   22);
insert into monthly_sales values (6520, date '2016-12-01',   21);
insert into monthly_sales values (6520, date '2017-01-01',   19);
insert into monthly_sales values (6520, date '2017-02-01',   18);
insert into monthly_sales values (6520, date '2017-03-01',   21);
insert into monthly_sales values (6520, date '2017-04-01',   24);
insert into monthly_sales values (6520, date '2017-05-01',   38);
insert into monthly_sales values (6520, date '2017-06-01',   52);
insert into monthly_sales values (6520, date '2017-07-01',   71);
insert into monthly_sales values (6520, date '2017-08-01',   69);
insert into monthly_sales values (6520, date '2017-09-01',   70);
insert into monthly_sales values (6520, date '2017-10-01',   37);
insert into monthly_sales values (6520, date '2017-11-01',   24);
insert into monthly_sales values (6520, date '2017-12-01',   15);
insert into monthly_sales values (6520, date '2018-01-01',    8);
insert into monthly_sales values (6520, date '2018-02-01',   17);
insert into monthly_sales values (6520, date '2018-03-01',   19);
insert into monthly_sales values (6520, date '2018-04-01',   18);
insert into monthly_sales values (6520, date '2018-05-01',   36);
insert into monthly_sales values (6520, date '2018-06-01',   39);
insert into monthly_sales values (6520, date '2018-07-01',   66);
insert into monthly_sales values (6520, date '2018-08-01',   58);
insert into monthly_sales values (6520, date '2018-09-01',   44);
insert into monthly_sales values (6520, date '2018-10-01',   21);
insert into monthly_sales values (6520, date '2018-11-01',   17);
insert into monthly_sales values (6520, date '2018-12-01',   14);
--6600, 'Hazy Pink Cloud' 
insert into monthly_sales values (6600, date '2016-01-01',    7);
insert into monthly_sales values (6600, date '2016-02-01',    6);
insert into monthly_sales values (6600, date '2016-03-01',    7);
insert into monthly_sales values (6600, date '2016-04-01',    5);
insert into monthly_sales values (6600, date '2016-05-01',   12);
insert into monthly_sales values (6600, date '2016-06-01',   17);
insert into monthly_sales values (6600, date '2016-07-01',   18);
insert into monthly_sales values (6600, date '2016-08-01',   17);
insert into monthly_sales values (6600, date '2016-09-01',   19);
insert into monthly_sales values (6600, date '2016-10-01',    3);
insert into monthly_sales values (6600, date '2016-11-01',    9);
insert into monthly_sales values (6600, date '2016-12-01',    1);
insert into monthly_sales values (6600, date '2017-01-01',    4);
insert into monthly_sales values (6600, date '2017-02-01',    0);
insert into monthly_sales values (6600, date '2017-03-01',    2);
insert into monthly_sales values (6600, date '2017-04-01',   11);
insert into monthly_sales values (6600, date '2017-05-01',   12);
insert into monthly_sales values (6600, date '2017-06-01',   18);
insert into monthly_sales values (6600, date '2017-07-01',   12);
insert into monthly_sales values (6600, date '2017-08-01',   21);
insert into monthly_sales values (6600, date '2017-09-01',   12);
insert into monthly_sales values (6600, date '2017-10-01',    4);
insert into monthly_sales values (6600, date '2017-11-01',    6);
insert into monthly_sales values (6600, date '2017-12-01',    3);
insert into monthly_sales values (6600, date '2018-01-01',    8);
insert into monthly_sales values (6600, date '2018-02-01',    2);
insert into monthly_sales values (6600, date '2018-03-01',    1);
insert into monthly_sales values (6600, date '2018-04-01',   19);
insert into monthly_sales values (6600, date '2018-05-01',    6);
insert into monthly_sales values (6600, date '2018-06-01',   11);
insert into monthly_sales values (6600, date '2018-07-01',   12);
insert into monthly_sales values (6600, date '2018-08-01',   22);
insert into monthly_sales values (6600, date '2018-09-01',    8);
insert into monthly_sales values (6600, date '2018-10-01',    3);
insert into monthly_sales values (6600, date '2018-11-01',    5);
insert into monthly_sales values (6600, date '2018-12-01',    1);
--7790, 'Summer in India' 
insert into monthly_sales values (7790, date '2016-01-01',    4);
insert into monthly_sales values (7790, date '2016-02-01',    6);
insert into monthly_sales values (7790, date '2016-03-01',   32);
insert into monthly_sales values (7790, date '2016-04-01',   45);
insert into monthly_sales values (7790, date '2016-05-01',   62);
insert into monthly_sales values (7790, date '2016-06-01',   58);
insert into monthly_sales values (7790, date '2016-07-01',   85);
insert into monthly_sales values (7790, date '2016-08-01',   28);
insert into monthly_sales values (7790, date '2016-09-01',   24);
insert into monthly_sales values (7790, date '2016-10-01',   19);
insert into monthly_sales values (7790, date '2016-11-01',    6);
insert into monthly_sales values (7790, date '2016-12-01',    8);
insert into monthly_sales values (7790, date '2017-01-01',    2);
insert into monthly_sales values (7790, date '2017-02-01',   13);
insert into monthly_sales values (7790, date '2017-03-01',   29);
insert into monthly_sales values (7790, date '2017-04-01',   60);
insert into monthly_sales values (7790, date '2017-05-01',   29);
insert into monthly_sales values (7790, date '2017-06-01',   78);
insert into monthly_sales values (7790, date '2017-07-01',   56);
insert into monthly_sales values (7790, date '2017-08-01',   22);
insert into monthly_sales values (7790, date '2017-09-01',   11);
insert into monthly_sales values (7790, date '2017-10-01',   13);
insert into monthly_sales values (7790, date '2017-11-01',    5);
insert into monthly_sales values (7790, date '2017-12-01',    3);
insert into monthly_sales values (7790, date '2018-01-01',    2);
insert into monthly_sales values (7790, date '2018-02-01',    8);
insert into monthly_sales values (7790, date '2018-03-01',   28);
insert into monthly_sales values (7790, date '2018-04-01',   26);
insert into monthly_sales values (7790, date '2018-05-01',   23);
insert into monthly_sales values (7790, date '2018-06-01',   46);
insert into monthly_sales values (7790, date '2018-07-01',   73);
insert into monthly_sales values (7790, date '2018-08-01',   25);
insert into monthly_sales values (7790, date '2018-09-01',   13);
insert into monthly_sales values (7790, date '2018-10-01',   11);
insert into monthly_sales values (7790, date '2018-11-01',    3);
insert into monthly_sales values (7790, date '2018-12-01',    5);
--7870, 'Ghost of Hops'   
insert into monthly_sales values (7870, date '2016-01-01',   20);
insert into monthly_sales values (7870, date '2016-02-01',   12);
insert into monthly_sales values (7870, date '2016-03-01',   26);
insert into monthly_sales values (7870, date '2016-04-01',   23);
insert into monthly_sales values (7870, date '2016-05-01',   47);
insert into monthly_sales values (7870, date '2016-06-01',   82);
insert into monthly_sales values (7870, date '2016-07-01',  101);
insert into monthly_sales values (7870, date '2016-08-01',   87);
insert into monthly_sales values (7870, date '2016-09-01',   52);
insert into monthly_sales values (7870, date '2016-10-01',   43);
insert into monthly_sales values (7870, date '2016-11-01',   41);
insert into monthly_sales values (7870, date '2016-12-01',   18);
insert into monthly_sales values (7870, date '2017-01-01',   15);
insert into monthly_sales values (7870, date '2017-02-01',   29);
insert into monthly_sales values (7870, date '2017-03-01',   36);
insert into monthly_sales values (7870, date '2017-04-01',   36);
insert into monthly_sales values (7870, date '2017-05-01',   30);
insert into monthly_sales values (7870, date '2017-06-01',   52);
insert into monthly_sales values (7870, date '2017-07-01',   60);
insert into monthly_sales values (7870, date '2017-08-01',   82);
insert into monthly_sales values (7870, date '2017-09-01',   57);
insert into monthly_sales values (7870, date '2017-10-01',   38);
insert into monthly_sales values (7870, date '2017-11-01',   30);
insert into monthly_sales values (7870, date '2017-12-01',   17);
insert into monthly_sales values (7870, date '2018-01-01',    9);
insert into monthly_sales values (7870, date '2018-02-01',   18);
insert into monthly_sales values (7870, date '2018-03-01',   20);
insert into monthly_sales values (7870, date '2018-04-01',   37);
insert into monthly_sales values (7870, date '2018-05-01',   22);
insert into monthly_sales values (7870, date '2018-06-01',   49);
insert into monthly_sales values (7870, date '2018-07-01',   60);
insert into monthly_sales values (7870, date '2018-08-01',   79);
insert into monthly_sales values (7870, date '2018-09-01',   55);
insert into monthly_sales values (7870, date '2018-10-01',   44);
insert into monthly_sales values (7870, date '2018-11-01',   45);
insert into monthly_sales values (7870, date '2018-12-01',   13);
--7950, 'Pale Rider Rides'
insert into monthly_sales values (7950, date '2016-01-01',   13);
insert into monthly_sales values (7950, date '2016-02-01',   16);
insert into monthly_sales values (7950, date '2016-03-01',   17);
insert into monthly_sales values (7950, date '2016-04-01',   12);
insert into monthly_sales values (7950, date '2016-05-01',   18);
insert into monthly_sales values (7950, date '2016-06-01',   14);
insert into monthly_sales values (7950, date '2016-07-01',   14);
insert into monthly_sales values (7950, date '2016-08-01',   18);
insert into monthly_sales values (7950, date '2016-09-01',   13);
insert into monthly_sales values (7950, date '2016-10-01',   20);
insert into monthly_sales values (7950, date '2016-11-01',   11);
insert into monthly_sales values (7950, date '2016-12-01',   16);
insert into monthly_sales values (7950, date '2017-01-01',   15);
insert into monthly_sales values (7950, date '2017-02-01',   18);
insert into monthly_sales values (7950, date '2017-03-01',   19);
insert into monthly_sales values (7950, date '2017-04-01',   14);
insert into monthly_sales values (7950, date '2017-05-01',   16);
insert into monthly_sales values (7950, date '2017-06-01',   15);
insert into monthly_sales values (7950, date '2017-07-01',   19);
insert into monthly_sales values (7950, date '2017-08-01',   14);
insert into monthly_sales values (7950, date '2017-09-01',   21);
insert into monthly_sales values (7950, date '2017-10-01',   12);
insert into monthly_sales values (7950, date '2017-11-01',   17);
insert into monthly_sales values (7950, date '2017-12-01',   30);
insert into monthly_sales values (7950, date '2018-01-01',   41);
insert into monthly_sales values (7950, date '2018-02-01',   44);
insert into monthly_sales values (7950, date '2018-03-01',   49);
insert into monthly_sales values (7950, date '2018-04-01',   33);
insert into monthly_sales values (7950, date '2018-05-01',   43);
insert into monthly_sales values (7950, date '2018-06-01',   38);
insert into monthly_sales values (7950, date '2018-07-01',   41);
insert into monthly_sales values (7950, date '2018-08-01',   42);
insert into monthly_sales values (7950, date '2018-09-01',   31);
insert into monthly_sales values (7950, date '2018-10-01',   45);
insert into monthly_sales values (7950, date '2018-11-01',   34);
insert into monthly_sales values (7950, date '2018-12-01',   50);

insert into breweries values (518, 'Balthazar Brauerei');
insert into breweries values (523, 'Happy Hoppy Hippo' );
insert into breweries values (536, 'Brewing Barbarian' );

insert into purchases values (601, date '2016-01-01', 536, 4040,  52,  388);
insert into purchases values (611, date '2016-03-01', 536, 4040,  54,  403);
insert into purchases values (621, date '2016-05-01', 536, 4040,  51,  380);
insert into purchases values (631, date '2016-07-01', 536, 4040,  49,  365);
insert into purchases values (641, date '2016-09-01', 536, 4040,  53,  395);
insert into purchases values (651, date '2016-11-01', 536, 4040,  41,  309);
insert into purchases values (666, date '2017-02-11', 536, 4040,  53,  310);
insert into purchases values (676, date '2017-04-11', 536, 4040,  55,  322);
insert into purchases values (686, date '2017-06-11', 536, 4040,  52,  305);
insert into purchases values (696, date '2017-08-11', 536, 4040,  50,  293);
insert into purchases values (706, date '2017-10-11', 536, 4040,  54,  316);
insert into purchases values (716, date '2017-12-11', 536, 4040,  36,  214);
insert into purchases values (721, date '2018-01-21', 536, 4040,  54,  432);
insert into purchases values (731, date '2018-03-21', 536, 4040,  56,  448);
insert into purchases values (741, date '2018-05-21', 536, 4040,  53,  424);
insert into purchases values (751, date '2018-07-21', 536, 4040,  51,  408);
insert into purchases values (761, date '2018-09-21', 536, 4040,  55,  440);
insert into purchases values (771, date '2018-11-21', 536, 4040,  31,  248);
insert into purchases values (606, date '2016-02-02', 536, 4160,  70,  462);
insert into purchases values (616, date '2016-04-02', 536, 4160,  72,  475);
insert into purchases values (626, date '2016-06-02', 536, 4160,  68,  448);
insert into purchases values (636, date '2016-08-02', 536, 4160,  67,  442);
insert into purchases values (646, date '2016-10-02', 536, 4160,  70,  462);
insert into purchases values (656, date '2016-12-02', 536, 4160,  53,  351);
insert into purchases values (661, date '2017-01-12', 536, 4160, 106,  819);
insert into purchases values (671, date '2017-03-12', 536, 4160, 108,  835);
insert into purchases values (681, date '2017-05-12', 536, 4160, 105,  812);
insert into purchases values (691, date '2017-07-12', 536, 4160, 103,  796);
insert into purchases values (701, date '2017-09-12', 536, 4160, 107,  827);
insert into purchases values (711, date '2017-11-12', 536, 4160,  71,  551);
insert into purchases values (726, date '2018-02-22', 536, 4160, 125,  985);
insert into purchases values (736, date '2018-04-22', 536, 4160, 127, 1001);
insert into purchases values (746, date '2018-06-22', 536, 4160, 123,  969);
insert into purchases values (756, date '2018-08-22', 536, 4160, 122,  962);
insert into purchases values (766, date '2018-10-22', 536, 4160, 125,  985);
insert into purchases values (776, date '2018-12-22', 536, 4160,  78,  618);
insert into purchases values (602, date '2016-01-03', 536, 4280,  17,  122);
insert into purchases values (612, date '2016-03-03', 536, 4280,  19,  136);
insert into purchases values (622, date '2016-05-03', 536, 4280,  15,  108);
insert into purchases values (632, date '2016-07-03', 536, 4280,  14,  100);
insert into purchases values (642, date '2016-09-03', 536, 4280,  17,  122);
insert into purchases values (652, date '2016-11-03', 536, 4280,  18,  132);
insert into purchases values (667, date '2017-02-13', 536, 4280,  18,  100);
insert into purchases values (677, date '2017-04-13', 536, 4280,  20,  112);
insert into purchases values (687, date '2017-06-13', 536, 4280,  16,   89);
insert into purchases values (697, date '2017-08-13', 536, 4280,  15,   84);
insert into purchases values (707, date '2017-10-13', 536, 4280,  18,  100);
insert into purchases values (717, date '2017-12-13', 536, 4280,  13,   75);
insert into purchases values (727, date '2018-02-23', 536, 4280,  36,  187);
insert into purchases values (737, date '2018-04-23', 536, 4280,  39,  202);
insert into purchases values (747, date '2018-06-23', 536, 4280,  35,  182);
insert into purchases values (757, date '2018-08-23', 536, 4280,  34,  176);
insert into purchases values (767, date '2018-10-23', 536, 4280,  37,  192);
insert into purchases values (777, date '2018-12-23', 536, 4280,  19,  101);
insert into purchases values (607, date '2016-02-04', 518, 5310,  87,  654);
insert into purchases values (617, date '2016-04-04', 518, 5310,  90,  676);
insert into purchases values (627, date '2016-06-04', 518, 5310,  86,  646);
insert into purchases values (637, date '2016-08-04', 518, 5310,  85,  639);
insert into purchases values (647, date '2016-10-04', 518, 5310,  88,  661);
insert into purchases values (657, date '2016-12-04', 518, 5310,  64,  484);
insert into purchases values (662, date '2017-01-14', 518, 5310, 106,  819);
insert into purchases values (672, date '2017-03-14', 518, 5310, 108,  835);
insert into purchases values (682, date '2017-05-14', 518, 5310, 105,  812);
insert into purchases values (692, date '2017-07-14', 518, 5310, 103,  796);
insert into purchases values (702, date '2017-09-14', 518, 5310, 107,  827);
insert into purchases values (712, date '2017-11-14', 518, 5310,  71,  551);
insert into purchases values (722, date '2018-01-24', 518, 5310,  89,  598);
insert into purchases values (732, date '2018-03-24', 518, 5310,  92,  618);
insert into purchases values (742, date '2018-05-24', 518, 5310,  88,  591);
insert into purchases values (752, date '2018-07-24', 518, 5310,  87,  584);
insert into purchases values (762, date '2018-09-24', 518, 5310,  90,  604);
insert into purchases values (772, date '2018-11-24', 518, 5310,  54,  365);
insert into purchases values (608, date '2016-02-05', 518, 5430,  52,  360);
insert into purchases values (618, date '2016-04-05', 518, 5430,  54,  374);
insert into purchases values (628, date '2016-06-05', 518, 5430,  51,  353);
insert into purchases values (638, date '2016-08-05', 518, 5430,  49,  339);
insert into purchases values (648, date '2016-10-05', 518, 5430,  53,  367);
insert into purchases values (658, date '2016-12-05', 518, 5430,  41,  287);
insert into purchases values (668, date '2017-02-15', 518, 5430,  71,  482);
insert into purchases values (678, date '2017-04-15', 518, 5430,  73,  496);
insert into purchases values (688, date '2017-06-15', 518, 5430,  69,  469);
insert into purchases values (698, date '2017-08-15', 518, 5430,  68,  462);
insert into purchases values (708, date '2017-10-15', 518, 5430,  71,  482);
insert into purchases values (718, date '2017-12-15', 518, 5430,  48,  329);
insert into purchases values (728, date '2018-02-25', 518, 5430,  89,  640);
insert into purchases values (738, date '2018-04-25', 518, 5430,  92,  662);
insert into purchases values (748, date '2018-06-25', 518, 5430,  88,  633);
insert into purchases values (758, date '2018-08-25', 518, 5430,  87,  626);
insert into purchases values (768, date '2018-10-25', 518, 5430,  90,  648);
insert into purchases values (778, date '2018-12-25', 518, 5430,  54,  391);
insert into purchases values (609, date '2016-02-06', 518, 6520,  87,  570);
insert into purchases values (619, date '2016-04-06', 518, 6520,  90,  590);
insert into purchases values (629, date '2016-06-06', 518, 6520,  86,  564);
insert into purchases values (639, date '2016-08-06', 518, 6520,  85,  557);
insert into purchases values (649, date '2016-10-06', 518, 6520,  88,  577);
insert into purchases values (659, date '2016-12-06', 518, 6520,  64,  422);
insert into purchases values (663, date '2017-01-16', 518, 6520,  88,  633);
insert into purchases values (673, date '2017-03-16', 518, 6520,  91,  655);
insert into purchases values (683, date '2017-05-16', 518, 6520,  87,  626);
insert into purchases values (693, date '2017-07-16', 518, 6520,  86,  619);
insert into purchases values (703, date '2017-09-16', 518, 6520,  89,  640);
insert into purchases values (713, date '2017-11-16', 518, 6520,  59,  427);
insert into purchases values (729, date '2018-02-26', 518, 6520,  72,  504);
insert into purchases values (739, date '2018-04-26', 518, 6520,  74,  518);
insert into purchases values (749, date '2018-06-26', 518, 6520,  70,  490);
insert into purchases values (759, date '2018-08-26', 518, 6520,  69,  483);
insert into purchases values (769, date '2018-10-26', 518, 6520,  72,  504);
insert into purchases values (779, date '2018-12-26', 518, 6520,  43,  301);
insert into purchases values (603, date '2016-01-07', 523, 6600,  34,  163);
insert into purchases values (613, date '2016-03-07', 523, 6600,  37,  177);
insert into purchases values (623, date '2016-05-07', 523, 6600,  33,  158);
insert into purchases values (633, date '2016-07-07', 523, 6600,  32,  153);
insert into purchases values (643, date '2016-09-07', 523, 6600,  35,  168);
insert into purchases values (653, date '2016-11-07', 523, 6600,  29,  141);
insert into purchases values (664, date '2017-01-17', 523, 6600,  18,  144);
insert into purchases values (674, date '2017-03-17', 523, 6600,  20,  160);
insert into purchases values (684, date '2017-05-17', 523, 6600,  16,  128);
insert into purchases values (694, date '2017-07-17', 523, 6600,  15,  120);
insert into purchases values (704, date '2017-09-17', 523, 6600,  18,  144);
insert into purchases values (714, date '2017-11-17', 523, 6600,  13,  104);
insert into purchases values (723, date '2018-01-27', 523, 6600,  19,  136);
insert into purchases values (733, date '2018-03-27', 523, 6600,  21,  151);
insert into purchases values (743, date '2018-05-27', 523, 6600,  17,  122);
insert into purchases values (753, date '2018-07-27', 523, 6600,  16,  115);
insert into purchases values (763, date '2018-09-27', 523, 6600,  19,  136);
insert into purchases values (773, date '2018-11-27', 523, 6600,   8,   60);
insert into purchases values (604, date '2016-01-08', 523, 7790,  70,  518);
insert into purchases values (614, date '2016-03-08', 523, 7790,  72,  532);
insert into purchases values (624, date '2016-05-08', 523, 7790,  68,  503);
insert into purchases values (634, date '2016-07-08', 523, 7790,  67,  495);
insert into purchases values (644, date '2016-09-08', 523, 7790,  70,  518);
insert into purchases values (654, date '2016-11-08', 523, 7790,  53,  394);
insert into purchases values (665, date '2017-01-18', 523, 7790,  71,  454);
insert into purchases values (675, date '2017-03-18', 523, 7790,  73,  467);
insert into purchases values (685, date '2017-05-18', 523, 7790,  69,  441);
insert into purchases values (695, date '2017-07-18', 523, 7790,  68,  435);
insert into purchases values (705, date '2017-09-18', 523, 7790,  71,  454);
insert into purchases values (715, date '2017-11-18', 523, 7790,  48,  309);
insert into purchases values (724, date '2018-01-28', 523, 7790,  54,  374);
insert into purchases values (734, date '2018-03-28', 523, 7790,  56,  388);
insert into purchases values (744, date '2018-05-28', 523, 7790,  53,  367);
insert into purchases values (754, date '2018-07-28', 523, 7790,  51,  353);
insert into purchases values (764, date '2018-09-28', 523, 7790,  55,  381);
insert into purchases values (774, date '2018-11-28', 523, 7790,  31,  217);
insert into purchases values (605, date '2016-01-09', 523, 7870, 105,  770);
insert into purchases values (615, date '2016-03-09', 523, 7870, 107,  784);
insert into purchases values (625, date '2016-05-09', 523, 7870, 104,  762);
insert into purchases values (635, date '2016-07-09', 523, 7870, 102,  748);
insert into purchases values (645, date '2016-09-09', 523, 7870, 106,  777);
insert into purchases values (655, date '2016-11-09', 523, 7870,  76,  559);
insert into purchases values (669, date '2017-02-19', 523, 7870,  88,  675);
insert into purchases values (679, date '2017-04-19', 523, 7870,  91,  698);
insert into purchases values (689, date '2017-06-19', 523, 7870,  87,  668);
insert into purchases values (699, date '2017-08-19', 523, 7870,  86,  660);
insert into purchases values (709, date '2017-10-19', 523, 7870,  89,  683);
insert into purchases values (719, date '2017-12-19', 523, 7870,  59,  456);
insert into purchases values (730, date '2018-02-28', 523, 7870,  89,  640);
insert into purchases values (740, date '2018-04-29', 523, 7870,  92,  662);
insert into purchases values (750, date '2018-06-29', 523, 7870,  88,  633);
insert into purchases values (760, date '2018-08-29', 523, 7870,  87,  626);
insert into purchases values (770, date '2018-10-29', 523, 7870,  90,  648);
insert into purchases values (780, date '2018-12-29', 523, 7870,  54,  391);
insert into purchases values (610, date '2016-02-10', 536, 7950,  34,  244);
insert into purchases values (620, date '2016-04-10', 536, 7950,  37,  266);
insert into purchases values (630, date '2016-06-10', 536, 7950,  33,  237);
insert into purchases values (640, date '2016-08-10', 536, 7950,  32,  230);
insert into purchases values (650, date '2016-10-10', 536, 7950,  35,  252);
insert into purchases values (660, date '2016-12-10', 536, 7950,  29,  211);
insert into purchases values (670, date '2017-02-20', 536, 7950,  53,  296);
insert into purchases values (680, date '2017-04-20', 536, 7950,  55,  308);
insert into purchases values (690, date '2017-06-20', 536, 7950,  52,  291);
insert into purchases values (700, date '2017-08-20', 536, 7950,  50,  280);
insert into purchases values (710, date '2017-10-20', 536, 7950,  54,  302);
insert into purchases values (720, date '2017-12-20', 536, 7950,  36,  203);
insert into purchases values (725, date '2018-01-31', 536, 7950,  89,  697);
insert into purchases values (735, date '2018-03-31', 536, 7950,  92,  721);
insert into purchases values (745, date '2018-05-31', 536, 7950,  88,  689);
insert into purchases values (755, date '2018-07-31', 536, 7950,  87,  682);
insert into purchases values (765, date '2018-09-30', 536, 7950,  90,  705);
insert into purchases values (775, date '2018-11-30', 536, 7950,  54,  426);

insert into locations
with warehouses as (
   select level as warehouse
   from dual
   connect by level <= 2
), aisles as (
   select 'A' as aisle from dual union all
   select 'B' as aisle from dual union all
   select 'C' as aisle from dual union all
   select 'D' as aisle from dual
), positions as (
   select level as position
   from dual
   connect by level <= 32
)
select
   row_number() over (
      order by
      w.warehouse
    , a.aisle
    , p.position
   ) as id
 , w.warehouse
 , a.aisle
 , p.position
from warehouses w
cross join aisles a
cross join positions p;

insert into inventory values (1442, 172, 4040, 771, 31);
insert into inventory values (1385, 123, 4040, 761,  7);
insert into inventory values (1388, 160, 4040, 761, 48);
insert into inventory values (1331, 112, 4040, 751, 48);
insert into inventory values (1328,  74, 4040, 751,  3);
insert into inventory values (1271,  25, 4040, 741,  5);
insert into inventory values (1274,  62, 4040, 741, 48);
insert into inventory values (1214, 232, 4040, 731,  8);
insert into inventory values (1217,  13, 4040, 731, 48);
insert into inventory values (1160, 220, 4040, 721, 48);
insert into inventory values (1157, 183, 4040, 721,  6);

insert into inventory values (1466,   3, 4160, 776, 48);
insert into inventory values (1463, 224, 4160, 776, 30);
insert into inventory values (1415,  30, 4160, 766, 48);
insert into inventory values (1412, 249, 4160, 766, 29);
insert into inventory values (1418,  67, 4160, 766, 48);
insert into inventory values (1355, 200, 4160, 756, 26);
insert into inventory values (1361,  18, 4160, 756, 48);
insert into inventory values (1358, 237, 4160, 756, 48);
insert into inventory values (1301, 188, 4160, 746, 48);
insert into inventory values (1298, 151, 4160, 746, 27);
insert into inventory values (1304, 225, 4160, 746, 48);
insert into inventory values (1244, 139, 4160, 736, 48);
insert into inventory values (1241, 102, 4160, 736, 31);
insert into inventory values (1247, 176, 4160, 736, 48);
insert into inventory values (1190, 127, 4160, 726, 48);
insert into inventory values (1187,  90, 4160, 726, 48);
insert into inventory values (1184,  53, 4160, 726, 29);

insert into inventory values (1469, 199, 4280, 777, 19);
insert into inventory values (1421,   4, 4280, 767, 37);
insert into inventory values (1364, 212, 4280, 757, 34);
insert into inventory values (1307, 163, 4280, 747, 35);
insert into inventory values (1250, 114, 4280, 737, 39);
insert into inventory values (1193,  65, 4280, 727, 36);

insert into inventory values (1445, 236, 5310, 772,  6);
insert into inventory values (1448,  17, 5310, 772, 48);
insert into inventory values (1394,   5, 5310, 762, 48);
insert into inventory values (1391, 227, 5310, 762, 42);
insert into inventory values (1334, 175, 5310, 752, 39);
insert into inventory values (1337, 215, 5310, 752, 48);
insert into inventory values (1277, 126, 5310, 742, 40);
insert into inventory values (1280, 164, 5310, 742, 48);
insert into inventory values (1220,  82, 5310, 732, 44);
insert into inventory values (1223, 116, 5310, 732, 48);
insert into inventory values (1166,  71, 5310, 722, 48);
insert into inventory values (1163,  28, 5310, 722, 41);

insert into inventory values (1472, 143, 5430, 778,  6);
insert into inventory values (1475, 180, 5430, 778, 48);
insert into inventory values (1427, 242, 5430, 768, 48);
insert into inventory values (1424, 205, 5430, 768, 42);
insert into inventory values (1367, 156, 5430, 758, 39);
insert into inventory values (1370, 193, 5430, 758, 48);
insert into inventory values (1310, 107, 5430, 748, 40);
insert into inventory values (1313, 144, 5430, 748, 48);
insert into inventory values (1253,  58, 5430, 738, 44);
insert into inventory values (1256,  95, 5430, 738, 48);
insert into inventory values (1199,  46, 5430, 728, 48);
insert into inventory values (1196,   9, 5430, 728, 41);

insert into inventory values (1478,  64, 6520, 779, 43);
insert into inventory values (1430, 129, 6520, 769, 72);
insert into inventory values (1376, 115, 6520, 759, 48);
insert into inventory values (1373, 223, 6520, 759, 21);
insert into inventory values (1319,  69, 6520, 749, 70);
insert into inventory values (1259, 233, 6520, 739, 26);
insert into inventory values (1262,  16, 6520, 739, 48);
insert into inventory values (1205,  77, 6520, 729, 20);
insert into inventory values (1316,  29, 6520, 729, 14);
insert into inventory values (1433, 165, 6520, 729, 14);
insert into inventory values (1202, 186, 6520, 729, 24);

insert into inventory values (1451, 101, 6600, 773,  8);
insert into inventory values (1397,  89, 6600, 763, 19);
insert into inventory values (1340,  40, 6600, 753, 16);
insert into inventory values (1283, 247, 6600, 743, 17);
insert into inventory values (1226, 198, 6600, 733, 21);
insert into inventory values (1169, 149, 6600, 723, 19);

insert into inventory values (1454,  85, 7790, 774, 31);
insert into inventory values (1400,  73, 7790, 764,  7);
insert into inventory values (1403, 110, 7790, 764, 48);
insert into inventory values (1346,  61, 7790, 754, 48);
insert into inventory values (1343,  24, 7790, 754,  3);
insert into inventory values (1286, 231, 7790, 744,  5);
insert into inventory values (1289,  12, 7790, 744, 48);
insert into inventory values (1229, 182, 7790, 734,  8);
insert into inventory values (1232, 219, 7790, 734, 48);
insert into inventory values (1175, 170, 7790, 724, 48);
insert into inventory values (1172, 133, 7790, 724,  6);

insert into inventory values (1481, 208, 7870, 780,  6);
insert into inventory values (1484, 245, 7870, 780, 48);
insert into inventory values (1439,  87, 7870, 770, 48);
insert into inventory values (1436,  51, 7870, 770, 42);
insert into inventory values (1382,  39, 7870, 760, 48);
insert into inventory values (1379,   2, 7870, 760, 39);
insert into inventory values (1322, 209, 7870, 750, 40);
insert into inventory values (1325, 246, 7870, 750, 48);
insert into inventory values (1265, 158, 7870, 740, 44);
insert into inventory values (1268, 196, 7870, 740, 48);
insert into inventory values (1208, 111, 7870, 730, 41);
insert into inventory values (1211, 147, 7870, 730, 48);
insert into inventory values (1151,  23, 7870, 719, 48);
insert into inventory values (1148, 244, 7870, 719, 11);

insert into inventory values (1457,  63, 7950, 775,  6);
insert into inventory values (1460, 100, 7950, 775, 48);
insert into inventory values (1406,  88, 7950, 765, 42);
insert into inventory values (1409, 125, 7950, 765, 48);
insert into inventory values (1349,  34, 7950, 755, 39);
insert into inventory values (1352,  76, 7950, 755, 48);
insert into inventory values (1292, 252, 7950, 745, 40);
insert into inventory values (1295,  27, 7950, 745, 48);
insert into inventory values (1238, 234, 7950, 735, 48);
insert into inventory values (1235, 197, 7950, 735, 44);
insert into inventory values (1178, 148, 7950, 725, 41);
insert into inventory values (1181, 185, 7950, 725, 48);
insert into inventory values (1154, 179, 7950, 720, 36);

insert into customers values (50042, 'The White Hart');
insert into customers values (51069, 'Der Wichtelmann');
insert into customers values (50741, 'Hygge og Humle');
insert into customers values (51007, 'Boom Beer Bar');

insert into orders values (421, 50042, date '2019-01-15', null);
insert into orders values (422, 51069, date '2019-01-17', null);
insert into orders values (423, 50741, date '2019-01-18', null);
insert into orders values (424, 51069, date '2019-01-28', null);
insert into orders values (425, 51069, date '2019-02-17', null);
insert into orders values (426, 50741, date '2019-02-26', null);
insert into orders values (427, 50042, date '2019-03-02', null);
insert into orders values (428, 50741, date '2019-03-12', null);
insert into orders values (429, 50042, date '2019-03-22', null);
insert into orders values (430, 50741, date '2019-03-29', null);


insert into orderlines values (9120, 421, 4280, 110, 2400);
insert into orderlines values (9122, 421, 6520, 140, 2250);
insert into orderlines values (9233, 422, 4280,  80, 1750);
insert into orderlines values (9234, 422, 6520,  80, 1275);
insert into orderlines values (9269, 423, 4280,  60, 1300);
insert into orderlines values (9272, 423, 6520,  40,  650);

insert into orderlines values (9276, 424, 6600,  16,  320);
insert into orderlines values (9279, 425, 5310,  40,  750);
insert into orderlines values (9280, 425, 5430,  60, 1150);
insert into orderlines values (9282, 425, 6600,  24,  480);
insert into orderlines values (9286, 426, 6520,  40,  680);
insert into orderlines values (9287, 426, 6600,  16,  320);

insert into orderlines values (9292, 427, 4280,  60, 1480);
insert into orderlines values (9295, 428, 4280,  90, 1925);
insert into orderlines values (9296, 428, 7950, 100,  960);
insert into orderlines values (9297, 429, 4280,  80, 1750);
insert into orderlines values (9298, 429, 5430,  40,  875);
insert into orderlines values (9299, 430, 7950,  50,  480);

insert into product_alcohol values (4040, 330, 8.5);
insert into product_alcohol values (4160, 500, 6.0);
insert into product_alcohol values (4280, 330, 7.0);
insert into product_alcohol values (5310, 330, 5.0);
insert into product_alcohol values (5430, 330, 6.5);
insert into product_alcohol values (6520, 500, 4.5);
insert into product_alcohol values (6600, 500, 4.0);
insert into product_alcohol values (7790, 500, 5.5);
insert into product_alcohol values (7870, 330, 4.5);
insert into product_alcohol values (7950, 330, 5.0);

insert into customer_favorites values (50042, '4040,5310');
insert into customer_favorites values (51069, '6520');
insert into customer_favorites values (50741, '5430,7790,7870');
insert into customer_favorites values (51007, null);

insert into customer_reviews values (50042, '4040:A,6600:C,7950:B');
insert into customer_reviews values (51069, '4280:B,7790:B');
insert into customer_reviews values (50741, '4160:A');
insert into customer_reviews values (51007, null);

--6520, 'Der Helle Kumpel'
insert into monthly_budget values (6520, date '2018-01-01',   30);
insert into monthly_budget values (6520, date '2018-02-01',   30);
insert into monthly_budget values (6520, date '2018-03-01',   30);
insert into monthly_budget values (6520, date '2018-04-01',   30);
insert into monthly_budget values (6520, date '2018-05-01',   40);
insert into monthly_budget values (6520, date '2018-06-01',   50);
insert into monthly_budget values (6520, date '2018-07-01',   50);
insert into monthly_budget values (6520, date '2018-08-01',   40);
insert into monthly_budget values (6520, date '2018-09-01',   30);
insert into monthly_budget values (6520, date '2018-10-01',   30);
insert into monthly_budget values (6520, date '2018-11-01',   30);
insert into monthly_budget values (6520, date '2018-12-01',   30);
insert into monthly_budget values (6520, date '2019-01-01',   45);
insert into monthly_budget values (6520, date '2019-02-01',   45);
insert into monthly_budget values (6520, date '2019-03-01',   50);
insert into monthly_budget values (6520, date '2019-04-01',   50);
insert into monthly_budget values (6520, date '2019-05-01',   55);
insert into monthly_budget values (6520, date '2019-06-01',   55);
insert into monthly_budget values (6520, date '2019-07-01',   60);
insert into monthly_budget values (6520, date '2019-08-01',   60);
insert into monthly_budget values (6520, date '2019-09-01',   50);
insert into monthly_budget values (6520, date '2019-10-01',   50);
insert into monthly_budget values (6520, date '2019-11-01',   40);
insert into monthly_budget values (6520, date '2019-12-01',   40);
--6600, 'Hazy Pink Cloud' 
insert into monthly_budget values (6600, date '2018-01-01',    6);
insert into monthly_budget values (6600, date '2018-02-01',    6);
insert into monthly_budget values (6600, date '2018-03-01',    6);
insert into monthly_budget values (6600, date '2018-04-01',    6);
insert into monthly_budget values (6600, date '2018-05-01',    6);
insert into monthly_budget values (6600, date '2018-06-01',    6);
insert into monthly_budget values (6600, date '2018-07-01',    6);
insert into monthly_budget values (6600, date '2018-08-01',    6);
insert into monthly_budget values (6600, date '2018-09-01',    6);
insert into monthly_budget values (6600, date '2018-10-01',    6);
insert into monthly_budget values (6600, date '2018-11-01',    6);
insert into monthly_budget values (6600, date '2018-12-01',    6);
insert into monthly_budget values (6600, date '2019-01-01',   20);
insert into monthly_budget values (6600, date '2019-02-01',   20);
insert into monthly_budget values (6600, date '2019-03-01',   20);
insert into monthly_budget values (6600, date '2019-04-01',   20);
insert into monthly_budget values (6600, date '2019-05-01',   20);
insert into monthly_budget values (6600, date '2019-06-01',   20);
insert into monthly_budget values (6600, date '2019-07-01',   20);
insert into monthly_budget values (6600, date '2019-08-01',   20);
insert into monthly_budget values (6600, date '2019-09-01',   20);
insert into monthly_budget values (6600, date '2019-10-01',   20);
insert into monthly_budget values (6600, date '2019-11-01',   20);
insert into monthly_budget values (6600, date '2019-12-01',   20);

insert into product_minimums values (6520, 100, 400);
insert into product_minimums values (6600,  30, 100);

insert into stock values ('BEER', 'Good Beer Trading Co');

insert into ticker values ('BEER', date '2019-04-01', 14.9);
insert into ticker values ('BEER', date '2019-04-02', 14.2);
insert into ticker values ('BEER', date '2019-04-03', 14.2);
insert into ticker values ('BEER', date '2019-04-04', 15.7);
insert into ticker values ('BEER', date '2019-04-05', 15.6);
insert into ticker values ('BEER', date '2019-04-08', 14.8);
insert into ticker values ('BEER', date '2019-04-09', 14.8);
insert into ticker values ('BEER', date '2019-04-10', 14.0);
insert into ticker values ('BEER', date '2019-04-11', 14.4);
insert into ticker values ('BEER', date '2019-04-12', 15.2);
insert into ticker values ('BEER', date '2019-04-15', 15.0);
insert into ticker values ('BEER', date '2019-04-16', 13.7);
insert into ticker values ('BEER', date '2019-04-17', 14.3);
insert into ticker values ('BEER', date '2019-04-18', 14.3);
insert into ticker values ('BEER', date '2019-04-19', 15.5);

insert into web_apps values (542, 'Webshop');

insert into web_pages values (542, 1, '/Shop');
insert into web_pages values (542, 2, '/Categories');
insert into web_pages values (542, 3, '/Breweries');
insert into web_pages values (542, 4, '/About');

insert into web_counter_hist values (542, 1, date '2019-04-01', 5010);
insert into web_counter_hist values (542, 1, date '2019-04-02', 5088);
insert into web_counter_hist values (542, 1, date '2019-04-03', 5160);
insert into web_counter_hist values (542, 1, date '2019-04-04', 5237);
insert into web_counter_hist values (542, 1, date '2019-04-05', 5311);
insert into web_counter_hist values (542, 1, date '2019-04-06', 5390);
insert into web_counter_hist values (542, 1, date '2019-04-07', 5458);
insert into web_counter_hist values (542, 1, date '2019-04-08', 5517);
insert into web_counter_hist values (542, 1, date '2019-04-09', 5580);
insert into web_counter_hist values (542, 1, date '2019-04-10', 5659);
insert into web_counter_hist values (542, 1, date '2019-04-11', 5733);
insert into web_counter_hist values (542, 1, date '2019-04-12', 5800);
insert into web_counter_hist values (542, 1, date '2019-04-13', 6079);
insert into web_counter_hist values (542, 1, date '2019-04-14', 6350);
insert into web_counter_hist values (542, 1, date '2019-04-15', 6612);
insert into web_counter_hist values (542, 1, date '2019-04-16', 6839);
insert into web_counter_hist values (542, 1, date '2019-04-17', 7032);
insert into web_counter_hist values (542, 1, date '2019-04-18', 7186);
insert into web_counter_hist values (542, 1, date '2019-04-19', 7260);
insert into web_counter_hist values (542, 1, date '2019-04-20', 7328);
insert into web_counter_hist values (542, 1, date '2019-04-21', 7401);
insert into web_counter_hist values (542, 1, date '2019-04-22', 7480);
insert into web_counter_hist values (542, 1, date '2019-04-23', 7542);
insert into web_counter_hist values (542, 1, date '2019-04-24', 7599);
insert into web_counter_hist values (542, 1, date '2019-04-25', 7621);
insert into web_counter_hist values (542, 1, date '2019-04-26', 7639);
insert into web_counter_hist values (542, 1, date '2019-04-27', 7660);
insert into web_counter_hist values (542, 1, date '2019-04-28', 7683);
insert into web_counter_hist values (542, 1, date '2019-04-29', 7755);
insert into web_counter_hist values (542, 1, date '2019-04-30', 7833);

insert into web_counter_hist values (542, 2, date '2019-04-01', 3397);
insert into web_counter_hist values (542, 2, date '2019-04-02', 3454);
insert into web_counter_hist values (542, 2, date '2019-04-03', 3510);
insert into web_counter_hist values (542, 2, date '2019-04-04', 3569);
insert into web_counter_hist values (542, 2, date '2019-04-05', 3612);
insert into web_counter_hist values (542, 2, date '2019-04-06', 3622);
insert into web_counter_hist values (542, 2, date '2019-04-07', 3630);
insert into web_counter_hist values (542, 2, date '2019-04-08', 3637);
insert into web_counter_hist values (542, 2, date '2019-04-09', 3691);
insert into web_counter_hist values (542, 2, date '2019-04-10', 3740);
insert into web_counter_hist values (542, 2, date '2019-04-11', 3801);
insert into web_counter_hist values (542, 2, date '2019-04-12', 3848);
insert into web_counter_hist values (542, 2, date '2019-04-13', 3895);
insert into web_counter_hist values (542, 2, date '2019-04-14', 3950);
insert into web_counter_hist values (542, 2, date '2019-04-15', 3999);
insert into web_counter_hist values (542, 2, date '2019-04-16', 4051);
insert into web_counter_hist values (542, 2, date '2019-04-17', 4089);
insert into web_counter_hist values (542, 2, date '2019-04-18', 4142);
insert into web_counter_hist values (542, 2, date '2019-04-19', 4188);
insert into web_counter_hist values (542, 2, date '2019-04-20', 4230);
insert into web_counter_hist values (542, 2, date '2019-04-21', 4280);
insert into web_counter_hist values (542, 2, date '2019-04-22', 4341);
insert into web_counter_hist values (542, 2, date '2019-04-23', 4396);
insert into web_counter_hist values (542, 2, date '2019-04-24', 4442);
insert into web_counter_hist values (542, 2, date '2019-04-25', 4487);
insert into web_counter_hist values (542, 2, date '2019-04-26', 4531);
insert into web_counter_hist values (542, 2, date '2019-04-27', 4588);
insert into web_counter_hist values (542, 2, date '2019-04-28', 4625);
insert into web_counter_hist values (542, 2, date '2019-04-29', 4985);
insert into web_counter_hist values (542, 2, date '2019-04-30', 5033);

insert into web_counter_hist values (542, 3, date '2019-04-01', 1866);
insert into web_counter_hist values (542, 3, date '2019-04-02', 1887);
insert into web_counter_hist values (542, 3, date '2019-04-03', 1914);
insert into web_counter_hist values (542, 3, date '2019-04-04', 1938);
insert into web_counter_hist values (542, 3, date '2019-04-05', 1955);
insert into web_counter_hist values (542, 3, date '2019-04-06', 2006);
insert into web_counter_hist values (542, 3, date '2019-04-07', 2063);
insert into web_counter_hist values (542, 3, date '2019-04-08', 2114);
insert into web_counter_hist values (542, 3, date '2019-04-09', 2172);
insert into web_counter_hist values (542, 3, date '2019-04-10', 2213);
insert into web_counter_hist values (542, 3, date '2019-04-11', 2249);
insert into web_counter_hist values (542, 3, date '2019-04-12', 2287);
insert into web_counter_hist values (542, 3, date '2019-04-13', 2331);
insert into web_counter_hist values (542, 3, date '2019-04-14', 2374);
insert into web_counter_hist values (542, 3, date '2019-04-15', 2409);
insert into web_counter_hist values (542, 3, date '2019-04-16', 2442);
insert into web_counter_hist values (542, 3, date '2019-04-17', 2484);
insert into web_counter_hist values (542, 3, date '2019-04-18', 2647);
insert into web_counter_hist values (542, 3, date '2019-04-19', 2692);
insert into web_counter_hist values (542, 3, date '2019-04-20', 2735);
insert into web_counter_hist values (542, 3, date '2019-04-21', 2794);
insert into web_counter_hist values (542, 3, date '2019-04-22', 2826);
insert into web_counter_hist values (542, 3, date '2019-04-23', 2864);
insert into web_counter_hist values (542, 3, date '2019-04-24', 2901);
insert into web_counter_hist values (542, 3, date '2019-04-25', 2929);
insert into web_counter_hist values (542, 3, date '2019-04-26', 2973);
insert into web_counter_hist values (542, 3, date '2019-04-27', 3008);
insert into web_counter_hist values (542, 3, date '2019-04-28', 3041);
insert into web_counter_hist values (542, 3, date '2019-04-29', 3077);
insert into web_counter_hist values (542, 3, date '2019-04-30', 3115);

insert into web_counter_hist values (542, 4, date '2019-04-01',  455);
insert into web_counter_hist values (542, 4, date '2019-04-02',  459);
insert into web_counter_hist values (542, 4, date '2019-04-03',  462);
insert into web_counter_hist values (542, 4, date '2019-04-04',  463);
insert into web_counter_hist values (542, 4, date '2019-04-05',  468);
insert into web_counter_hist values (542, 4, date '2019-04-06',  491);
insert into web_counter_hist values (542, 4, date '2019-04-07',  499);
insert into web_counter_hist values (542, 4, date '2019-04-08',  501);
insert into web_counter_hist values (542, 4, date '2019-04-09',  501);
insert into web_counter_hist values (542, 4, date '2019-04-10',  505);
insert into web_counter_hist values (542, 4, date '2019-04-11',  508);
insert into web_counter_hist values (542, 4, date '2019-04-12',  513);
insert into web_counter_hist values (542, 4, date '2019-04-13',  514);
insert into web_counter_hist values (542, 4, date '2019-04-14',  516);
insert into web_counter_hist values (542, 4, date '2019-04-15',  524);
insert into web_counter_hist values (542, 4, date '2019-04-16',  524);
insert into web_counter_hist values (542, 4, date '2019-04-17',  524);
insert into web_counter_hist values (542, 4, date '2019-04-18',  524);
insert into web_counter_hist values (542, 4, date '2019-04-19',  524);
insert into web_counter_hist values (542, 4, date '2019-04-20',  524);
insert into web_counter_hist values (542, 4, date '2019-04-21',  524);
insert into web_counter_hist values (542, 4, date '2019-04-22',  527);
insert into web_counter_hist values (542, 4, date '2019-04-23',  531);
insert into web_counter_hist values (542, 4, date '2019-04-24',  539);
insert into web_counter_hist values (542, 4, date '2019-04-25',  552);
insert into web_counter_hist values (542, 4, date '2019-04-26',  555);
insert into web_counter_hist values (542, 4, date '2019-04-27',  555);
insert into web_counter_hist values (542, 4, date '2019-04-28',  563);
insert into web_counter_hist values (542, 4, date '2019-04-29',  581);
insert into web_counter_hist values (542, 4, date '2019-04-30',  586);

insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:00', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:05', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:10', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:15', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:20', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:35', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:40', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:45', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.100', to_date('2019-04-10 13:55', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.142', to_date('2019-04-10 13:00', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.142', to_date('2019-04-10 13:20', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.142', to_date('2019-04-10 13:25', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.142', to_date('2019-04-10 13:50', 'YYYY-MM-DD HH24:MI'));
insert into server_heartbeat values ('10.0.0.142', to_date('2019-04-10 13:55', 'YYYY-MM-DD HH24:MI'));

insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:15:42', 'YYYY-MM-DD HH24:MI:SS'), 542, 1);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:16:31', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:28:55', 'YYYY-MM-DD HH24:MI:SS'), 542, 4);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:41:12', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:42:37', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 08:55:02', 'YYYY-MM-DD HH24:MI:SS'), 542, 4);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:03:34', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:17:50', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:28:32', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:34:29', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:43:46', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:47:08', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 09:49:12', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);
insert into web_page_visits values ('85.237.86.200', to_date('2019-04-20 11:57:26', 'YYYY-MM-DD HH24:MI:SS'), 542, 1);
insert into web_page_visits values ('85.237.86.200', to_date('2019-04-20 11:58:09', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('85.237.86.200', to_date('2019-04-20 11:58:39', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('85.237.86.200', to_date('2019-04-20 12:02:02', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 14:45:10', 'YYYY-MM-DD HH24:MI:SS'), 542, 1);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 15:02:22', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 15:02:44', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 15:04:01', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 15:05:11', 'YYYY-MM-DD HH24:MI:SS'), 542, 2);
insert into web_page_visits values ('104.130.89.12', to_date('2019-04-20 15:05:48', 'YYYY-MM-DD HH24:MI:SS'), 542, 3);

insert into employees values (142, 'Harold King'  , 'Managing Director', null);
insert into employees values (147, 'Ursula Mwbesi', 'Operations Chief' , 142);
insert into employees values (143, 'Mogens Juel'  , 'IT Manager'       , 147);
insert into employees values (153, 'Dan Hoeffler' , 'IT Supporter'     , 143);
insert into employees values (145, 'Zoe Thorston' , 'IT Developer'     , 143);
insert into employees values (146, 'Lim Tok Lo'   , 'Warehouse Manager', 147);
insert into employees values (149, 'Kurt Zollman' , 'Forklift Operator', 146);
insert into employees values (152, 'Evelyn Smith' , 'Forklift Operator', 146);
insert into employees values (155, 'Susanne Hoff' , 'Janitor'          , 146);
insert into employees values (144, 'Axel de Proef', 'Product Director' , 142);
insert into employees values (148, 'Maria Juarez' , 'Purchaser'        , 144);
insert into employees values (151, 'Jim Kronzki'  , 'Sales Manager'    , 144);
insert into employees values (150, 'Laura Jensen' , 'Bulk Salesman'    , 151);
insert into employees values (154, 'Simon Chang'  , 'Retail Salesman'  , 151);

insert into emp_hire_periods values (142, date '2010-07-01', date '2012-04-01', 'Product Director' );
insert into emp_hire_periods values (142, date '2012-04-01', null             , 'Managing Director');
insert into emp_hire_periods values (143, date '2010-07-01', date '2014-01-01', 'IT Technician'    );
insert into emp_hire_periods values (143, date '2014-01-01', date '2016-06-01', 'Sys Admin'        );
insert into emp_hire_periods values (143, date '2014-04-01', date '2015-10-01', 'Code Tester'      );
insert into emp_hire_periods values (143, date '2016-06-01', null             , 'IT Manager'       );
insert into emp_hire_periods values (144, date '2010-07-01', date '2013-07-01', 'Sales Manager'    );
insert into emp_hire_periods values (144, date '2012-04-01', null             , 'Product Director' );
insert into emp_hire_periods values (145, date '2014-02-01', null             , 'IT Developer'     );
insert into emp_hire_periods values (145, date '2019-02-01', null             , 'Scrum Master'     );
insert into emp_hire_periods values (146, date '2014-10-01', date '2016-02-01', 'Forklift Operator');
insert into emp_hire_periods values (146, date '2017-03-01', null             , 'Warehouse Manager');
insert into emp_hire_periods values (147, date '2014-10-01', date '2015-05-01', 'Delivery Manager' );
insert into emp_hire_periods values (147, date '2016-05-01', date '2017-03-01', 'Warehouse Manager');
insert into emp_hire_periods values (147, date '2016-11-01', null             , 'Operations Chief' );

insert into picking_list values (841, to_date('2019-01-16 14:03:41', 'YYYY-MM-DD HH24:MI:SS'), 149);
insert into picking_list values (842, to_date('2019-01-19 15:57:42', 'YYYY-MM-DD HH24:MI:SS'), 152);

insert into picking_line values (841,  1,  16, 421, 6520, 42);
insert into picking_line values (841,  2,  29, 421, 6520, 14);
insert into picking_line values (841,  3,  77, 421, 6520, 20);
insert into picking_line values (841,  4,  65, 421, 4280, 36);
insert into picking_line values (841,  5, 114, 421, 4280, 39);
insert into picking_line values (841,  6, 186, 421, 6520, 24);
insert into picking_line values (841,  7, 165, 421, 6520, 14);
insert into picking_line values (841,  8, 163, 421, 4280, 35);
insert into picking_line values (841,  9, 233, 421, 6520, 26);

insert into picking_line values (842,  1,  16, 423, 6520, 22);
insert into picking_line values (842,  2,  29, 422, 6520, 14);
insert into picking_line values (842,  3,  77, 422, 6520, 20);
insert into picking_line values (842,  4,  65, 422, 4280, 36);
insert into picking_line values (842,  5, 114, 422, 4280, 39);
insert into picking_line values (842,  6, 186, 422, 6520, 24);
insert into picking_line values (842,  7, 165, 422, 6520, 14);
insert into picking_line values (842,  8, 163, 422, 4280,  5);
insert into picking_line values (842,  9, 163, 423, 4280, 30);
insert into picking_line values (842, 10, 212, 423, 4280, 30);
insert into picking_line values (842, 11, 233, 422, 6520,  8);
insert into picking_line values (842, 12, 233, 423, 6520, 18);

insert into picking_log values (841, to_date('2019-01-16 14:05:11', 'YYYY-MM-DD HH24:MI:SS'), 'D', null, null);
insert into picking_log values (841, to_date('2019-01-16 14:05:44', 'YYYY-MM-DD HH24:MI:SS'), 'A',   16, null);
insert into picking_log values (841, to_date('2019-01-16 14:05:52', 'YYYY-MM-DD HH24:MI:SS'), 'P',   16,    1);
insert into picking_log values (841, to_date('2019-01-16 14:06:01', 'YYYY-MM-DD HH24:MI:SS'), 'D',   16, null);
insert into picking_log values (841, to_date('2019-01-16 14:06:20', 'YYYY-MM-DD HH24:MI:SS'), 'A',   29, null);
insert into picking_log values (841, to_date('2019-01-16 14:06:27', 'YYYY-MM-DD HH24:MI:SS'), 'P',   29,    2);
insert into picking_log values (841, to_date('2019-01-16 14:06:35', 'YYYY-MM-DD HH24:MI:SS'), 'D',   29, null);
insert into picking_log values (841, to_date('2019-01-16 14:07:16', 'YYYY-MM-DD HH24:MI:SS'), 'A',   77, null);
insert into picking_log values (841, to_date('2019-01-16 14:07:20', 'YYYY-MM-DD HH24:MI:SS'), 'P',   77,    3);
insert into picking_log values (841, to_date('2019-01-16 14:07:31', 'YYYY-MM-DD HH24:MI:SS'), 'D',   77, null);
insert into picking_log values (841, to_date('2019-01-16 14:07:44', 'YYYY-MM-DD HH24:MI:SS'), 'A',   65, null);
insert into picking_log values (841, to_date('2019-01-16 14:07:50', 'YYYY-MM-DD HH24:MI:SS'), 'P',   65,    4);
insert into picking_log values (841, to_date('2019-01-16 14:07:56', 'YYYY-MM-DD HH24:MI:SS'), 'D',   65, null);
insert into picking_log values (841, to_date('2019-01-16 14:08:52', 'YYYY-MM-DD HH24:MI:SS'), 'A',  114, null);
insert into picking_log values (841, to_date('2019-01-16 14:09:02', 'YYYY-MM-DD HH24:MI:SS'), 'P',  114,    5);
insert into picking_log values (841, to_date('2019-01-16 14:09:14', 'YYYY-MM-DD HH24:MI:SS'), 'D',  114, null);
insert into picking_log values (841, to_date('2019-01-16 14:10:13', 'YYYY-MM-DD HH24:MI:SS'), 'A',  186, null);
insert into picking_log values (841, to_date('2019-01-16 14:10:18', 'YYYY-MM-DD HH24:MI:SS'), 'P',  186,    6);
insert into picking_log values (841, to_date('2019-01-16 14:10:26', 'YYYY-MM-DD HH24:MI:SS'), 'D',  186, null);
insert into picking_log values (841, to_date('2019-01-16 14:10:48', 'YYYY-MM-DD HH24:MI:SS'), 'A',  165, null);
insert into picking_log values (841, to_date('2019-01-16 14:10:57', 'YYYY-MM-DD HH24:MI:SS'), 'P',  165,    7);
insert into picking_log values (841, to_date('2019-01-16 14:11:02', 'YYYY-MM-DD HH24:MI:SS'), 'D',  165, null);
insert into picking_log values (841, to_date('2019-01-16 14:11:11', 'YYYY-MM-DD HH24:MI:SS'), 'A',  163, null);
insert into picking_log values (841, to_date('2019-01-16 14:11:15', 'YYYY-MM-DD HH24:MI:SS'), 'P',  163,    8);
insert into picking_log values (841, to_date('2019-01-16 14:11:26', 'YYYY-MM-DD HH24:MI:SS'), 'D',  163, null);
insert into picking_log values (841, to_date('2019-01-16 14:12:42', 'YYYY-MM-DD HH24:MI:SS'), 'A',  233, null);
insert into picking_log values (841, to_date('2019-01-16 14:12:53', 'YYYY-MM-DD HH24:MI:SS'), 'P',  233,    9);
insert into picking_log values (841, to_date('2019-01-16 14:13:00', 'YYYY-MM-DD HH24:MI:SS'), 'D',  233, null);
insert into picking_log values (841, to_date('2019-01-16 14:14:41', 'YYYY-MM-DD HH24:MI:SS'), 'A', null, null);

insert into picking_log values (842, to_date('2019-01-19 16:01:12', 'YYYY-MM-DD HH24:MI:SS'), 'D', null, null);
insert into picking_log values (842, to_date('2019-01-19 16:01:48', 'YYYY-MM-DD HH24:MI:SS'), 'A',   16, null);
insert into picking_log values (842, to_date('2019-01-19 16:01:53', 'YYYY-MM-DD HH24:MI:SS'), 'P',   16,    1);
insert into picking_log values (842, to_date('2019-01-19 16:02:04', 'YYYY-MM-DD HH24:MI:SS'), 'D',   16, null);
insert into picking_log values (842, to_date('2019-01-19 16:02:19', 'YYYY-MM-DD HH24:MI:SS'), 'A',   29, null);
insert into picking_log values (842, to_date('2019-01-19 16:02:26', 'YYYY-MM-DD HH24:MI:SS'), 'P',   29,    2);
insert into picking_log values (842, to_date('2019-01-19 16:02:37', 'YYYY-MM-DD HH24:MI:SS'), 'D',   29, null);
insert into picking_log values (842, to_date('2019-01-19 16:03:02', 'YYYY-MM-DD HH24:MI:SS'), 'A',   77, null);
insert into picking_log values (842, to_date('2019-01-19 16:03:12', 'YYYY-MM-DD HH24:MI:SS'), 'P',   77,    3);
insert into picking_log values (842, to_date('2019-01-19 16:03:20', 'YYYY-MM-DD HH24:MI:SS'), 'D',   77, null);
insert into picking_log values (842, to_date('2019-01-19 16:03:46', 'YYYY-MM-DD HH24:MI:SS'), 'A',   65, null);
insert into picking_log values (842, to_date('2019-01-19 16:03:52', 'YYYY-MM-DD HH24:MI:SS'), 'P',   65,    4);
insert into picking_log values (842, to_date('2019-01-19 16:04:00', 'YYYY-MM-DD HH24:MI:SS'), 'D',   65, null);
insert into picking_log values (842, to_date('2019-01-19 16:04:57', 'YYYY-MM-DD HH24:MI:SS'), 'A',  114, null);
insert into picking_log values (842, to_date('2019-01-19 16:05:03', 'YYYY-MM-DD HH24:MI:SS'), 'P',  114,    5);
insert into picking_log values (842, to_date('2019-01-19 16:05:12', 'YYYY-MM-DD HH24:MI:SS'), 'D',  114, null);
insert into picking_log values (842, to_date('2019-01-19 16:06:05', 'YYYY-MM-DD HH24:MI:SS'), 'A',  186, null);
insert into picking_log values (842, to_date('2019-01-19 16:06:09', 'YYYY-MM-DD HH24:MI:SS'), 'P',  186,    6);
insert into picking_log values (842, to_date('2019-01-19 16:06:20', 'YYYY-MM-DD HH24:MI:SS'), 'D',  186, null);
insert into picking_log values (842, to_date('2019-01-19 16:06:51', 'YYYY-MM-DD HH24:MI:SS'), 'A',  165, null);
insert into picking_log values (842, to_date('2019-01-19 16:06:57', 'YYYY-MM-DD HH24:MI:SS'), 'P',  165,    7);
insert into picking_log values (842, to_date('2019-01-19 16:07:03', 'YYYY-MM-DD HH24:MI:SS'), 'D',  165, null);
insert into picking_log values (842, to_date('2019-01-19 16:07:12', 'YYYY-MM-DD HH24:MI:SS'), 'A',  163, null);
insert into picking_log values (842, to_date('2019-01-19 16:07:16', 'YYYY-MM-DD HH24:MI:SS'), 'P',  163,    8);
insert into picking_log values (842, to_date('2019-01-19 16:07:22', 'YYYY-MM-DD HH24:MI:SS'), 'P',  163,    9);
insert into picking_log values (842, to_date('2019-01-19 16:07:34', 'YYYY-MM-DD HH24:MI:SS'), 'D',  163, null);
insert into picking_log values (842, to_date('2019-01-19 16:08:44', 'YYYY-MM-DD HH24:MI:SS'), 'A',  212, null);
insert into picking_log values (842, to_date('2019-01-19 16:08:49', 'YYYY-MM-DD HH24:MI:SS'), 'P',  212,   10);
insert into picking_log values (842, to_date('2019-01-19 16:08:58', 'YYYY-MM-DD HH24:MI:SS'), 'D',  212, null);
insert into picking_log values (842, to_date('2019-01-19 16:09:23', 'YYYY-MM-DD HH24:MI:SS'), 'A',  233, null);
insert into picking_log values (842, to_date('2019-01-19 16:09:34', 'YYYY-MM-DD HH24:MI:SS'), 'P',  233,   11);
insert into picking_log values (842, to_date('2019-01-19 16:09:42', 'YYYY-MM-DD HH24:MI:SS'), 'P',  233,   12);
insert into picking_log values (842, to_date('2019-01-19 16:09:53', 'YYYY-MM-DD HH24:MI:SS'), 'D',  233, null);
insert into picking_log values (842, to_date('2019-01-19 16:11:42', 'YYYY-MM-DD HH24:MI:SS'), 'A', null, null);

-- Done inserting

commit;

/* -----------------------------------------------------
   Gather statistics
   ----------------------------------------------------- */

call dbms_stats.gather_schema_stats(USER);

/* ***************************************************** */
