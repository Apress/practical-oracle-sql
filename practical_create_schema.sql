/* ***************************************************** **
   practical_create_schema.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Creation of the user/schema PRACTICAL
   Granting the necessary privileges to this schema
   
   To be executed as a DBA user
** ***************************************************** */

create user practical
   identified by practical
   default tablespace users
   temporary tablespace temp;

alter user practical quota unlimited on users;

grant create session    to practical;
grant create table      to practical;
grant create view       to practical;
grant create type       to practical;
grant create procedure  to practical;

/* ***************************************************** */
