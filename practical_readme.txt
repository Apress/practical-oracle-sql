/* ***************************************************** **
   practical_readme.txt
   
   README for scripts for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use the scripts at your own risk

** ***************************************************** */

These scripts are companions to the book Practical Oracle SQL.
Detailed explanations of the scripts are found in the book.

Everything is placed in a schema called PRACTICAL
(somewhat like Oracle sample schemas SCOTT and HR.)

There are four scripts for managing this schema:

 - practical_create_schema.sql

   To be run as a DBA user.
   This creates the schema/user PRACTICAL
   and grants the necessary privileges to it.

 - practical_fill_schema.sql

   To be run as user PRACTICAL.
   This creates all tables, objects and sample data.

 - practical_clean_schema.sql

   To be run as user PRACTICAL.
   This drops all tables, objects and sample data.

 - practical_drop_schema.sql

   To be run as a DBA user.
   This drops the schema PRACTICAL with all content.


And then each chapter has a script ch_{chaptername}.sql.

To get going, run practical_create_schema.sql
followed by practical_fill_schema.sql.

Then you can try out all the chapter scripts
as you read the chapters in the book.

If you get the data mangled in the tables along the way,
you can a clean sheet by practical_clean_schema.sql
followed by practical_fill_schema.sql.

When you don't want the schema anymore,
run practical_drop_schema.sql.


Enjoy the book and play with the code.
Above all, have fun.

/Kim Berg Hansen

/* ***************************************************** */
