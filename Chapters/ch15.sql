/* ************* LEARNING SQL CHAPTER 15 *************** */
/* ************        METADATA                      *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Data About Data                         ****/
/* ******************************************** ****/
-- Metadata is just data about data. Everytime an object is created, the DBMS
--  will store relevant data about the data, like all tables contained,
--  column names, column data types, etc.
-- Metadata is collectively known as the data dictionary, or system catalog
-- Each database server uses a different mechanism to publish metadata
--  * Set of views: user_tables and all_constraints (Oracle)
--  * Set of system-stored procedures: sp_tables (SQL Server) and 
--     dbms_metadata (Oracle)
--  * Special database: information_schema (MySQL, SQL Server)

/* ******************************************** ****/
/* ***  Information Schema                      ****/
/* ******************************************** ****/
-- All objects in information_schema are views, which can be queried
-- Ex. Retrieve names of all tables in the bank database
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'bank'
ORDER BY 1;

-- Ex. We can exclude views by adding restricting to 'BASE TABLE' types
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'bank' AND table_type = 'BASE TABLE'
ORDER BY 1;

-- Ex. To retrieve info in views, query information_schema.views
SELECT table_name, is_updatable
FROM information_schema.views
WHERE table_schema = 'bank'
ORDER BY 1;

-- Ex. You can also retrieve the view's underlying query with view_definition
SELECT table_name, view_definition
FROM information_schema.views
WHERE table_schema = 'bank'
ORDER BY 1;

-- Ex. Find column info on both tables and views
SELECT column_name, data_type, character_maximum_length char_max_len,
  numeric_precision num_prcsn, numeric_scale num_scale
FROM information_schema.columns
WHERE table_schema = 'bank' AND table_name = 'account'
ORDER BY ordinal_position; /* order by when added to table */

-- Ex. Retrieve info about table's indexes
SELECT index_name, non_unique, seq_in_index, column_name
FROM information_schema.statistics
WHERE table_schema = 'bank' AND table_name = 'account'
ORDER BY 1, 3;

-- Ex. Retrieve all table constraints
SELECT constraint_name, table_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'bank'
ORDER BY 3,1;

-- Consult a reference for all information_schema views

/* ******************************************** ****/
/* ***  Working with Metadata                   ****/
/* ******************************************** ****/
-- Schema Generation Scripts
--  Ex. Build a script to create bank.customer table
create table customer
 (cust_id integer unsigned not null auto_increment,
  fed_id varchar(12) not null,
  cust_type_cd enum('I','B') not null,
  address varchar(30),
  city varchar(20),
  state varchar(20),
  postal_code varchar(10),
  constraint pk_customer primary key (cust_id)
 );

-- It's generally easier to generate the script with a procedural language,
--  but let's do it with SQL anyway.
-- Ex. Step 1: query information_schema.columns to retrieve info on columns
SELECT 'CREATE TABLE customer (' create_table_statement
UNION ALL
SELECT cols.txt
FROM 
 (SELECT concat('  ', column_name, ' ', column_type,
   CASE
     WHEN is_nullable = 'NO' THEN ' not null'
	 ELSE ''
   END,
   CASE
     WHEN extra IS NOT NULL THEN concat(' ', extra)
	 ELSE ''
   END,
   ',') txt
  FROM information_schema.columns
  WHERE table_schema = 'bank' AND table_name = 'customer'
  ORDER BY ordinal_position
 ) cols
UNION ALL
SELECT ')';

-- Ex. Step 2: add queries against table_constraints and key_column_usage to
--  add info about the primary key constraint
SELECT 'CREATE TABLE customer (' create_table_statement
UNION ALL
SELECT cols.txt
FROM 
 (SELECT concat('  ', column_name, ' ', column_type,
   CASE
     WHEN is_nullable = 'NO' THEN ' not null'
	 ELSE ''
   END,
   CASE
     WHEN extra IS NOT NULL THEN concat(' ', extra)
	 ELSE ''
   END,
   ',') txt
  FROM information_schema.columns
  WHERE table_schema = 'bank' AND table_name = 'customer'
  ORDER BY ordinal_position
 ) cols
UNION ALL
SELECT concat('  constraint primary key (')
FROM information_schema.table_constraints
WHERE table_schema = 'bank' AND table_name = 'customer'
  AND constraint_type = 'PRIMARY KEY'
UNION ALL
SELECT cols.txt
FROM
 (SELECT concat(CASE WHEN ordinal_position > 1 THEN '   ,'
    ELSE '    ' END, column_name) txt
  FROM information_schema.key_column_usage
  WHERE table_schema = 'bank' AND table_name = 'customer'
    AND constraint_name = 'PRIMARY'
  ORDER BY ordinal_position
 ) cols
UNION ALL
SELECT '  )'
UNION ALL
SELECT ')';

-- Ex. The above statement produces this (modified to customer2 to avoid dups)
CREATE TABLE customer2 (                            
  address varchar(30) ,                            
  city varchar(20) ,                               
  cust_id int(10) unsigned not null auto_increment,
  cust_type_cd enum('I','B') not null ,            
  fed_id varchar(12) not null ,                    
  postal_code varchar(10) ,                        
  state varchar(20) ,                              
  constraint primary key (                         
    cust_id                                        
  )                                                
);

-- Deployment Verification
--  Many orgs have a database maintenance window. It's good to use a script
--   to verify new schema objects are in place.
-- Ex: Return # of columns, # of indexes, and # primary key constraints in bank
SELECT tbl.table_name,
 (SELECT count(*) FROM information_schema.columns clm
  WHERE clm.table_schema = tbl.table_schema
    AND clm.table_name = tbl.table_name) num_columns,
 (SELECT count(*) FROM information_schema.statistics sta
  WHERE sta.table_schema = tbl.table_schema
    AND sta.table_name = tbl.table_name) num_indexes,
 (SELECT count(*) FROM information_schema.table_constraints tc
  WHERE tc.table_schema = tbl.table_schema
    AND tc.table_name = tbl.table_name
	AND tc.constraint_type = 'PRIMARY KEY') num_primary_keys
FROM information_schema.tables tbl
WHERE tbl.table_schema = 'bank' AND tbl.table_type = 'BASE TABLE'
ORDER BY 1;

-- Dynamic SQL Generation
--  Many languages that connect to SQL DBMSs submit SQL queries in strings; so,
--   many DBMSs allow SQL queries to be submitted as strings
--  This is known as dynamic SQL execution.
--   * Oracle: execute_immediate
--   * SQL Server: sp_executesql

-- Ex. MySQL has PREPARE, EXECUTE, and DEALLOCATE to allow dynamic SQL
--  Flow: Set -> Prepare -> Execute -> Deallocate Prepare
SET @qry = 'SELECT cust_id, cust_type_cd, fed_id FROM customer';
PREPARE dynsql1 FROM @qry;
EXECUTE dynsql1;
DEALLOCATE PREPARE dynsql1;

-- Ex. A query including placeholders for conditions at runtime
SET @qry = 'SELECT product_cd, name, product_type_cd, date_offered, date_retired FROM product WHERE product_cd = ?';
PREPARE dynsql2 FROM @qry;

SET @prodcd = 'CHK';
EXECUTE dynsql2 USING @prodcd;

SET @prodcd = 'SAV';
EXECUTE dynsql2 USING @prodcd;

DEALLOCATE PREPARE dynsql2;

-- You can use metadata to build query strings
-- Ex. Query information_schema.columns view to generate dynamic SQL above
SELECT concat('SELECT ',
  concat_ws(',', cols.col1, cols.col2, cols.col3, cols.col4,
    cols.col5, cols.col6, cols.col7, cols.col8, cols.col9),
  ' FROM product WHERE product_cd = ?')
INTO @qry
FROM
 (SELECT
    max(CASE WHEN ordinal_position = 1 THEN column_name
	  ELSE NULL END) col1,
	max(CASE WHEN ordinal_position = 2 THEN column_name
	  ELSE NULL END) col2,
	max(CASE WHEN ordinal_position = 3 THEN column_name
	  ELSE NULL END) col3,
	max(CASE WHEN ordinal_position = 4 THEN column_name
	  ELSE NULL END) col4,
	max(CASE WHEN ordinal_position = 5 THEN column_name
	  ELSE NULL END) col5,
	max(CASE WHEN ordinal_position = 6 THEN column_name
	  ELSE NULL END) col6,
	max(CASE WHEN ordinal_position = 7 THEN column_name
	  ELSE NULL END) col7,
	max(CASE WHEN ordinal_position = 8 THEN column_name
	  ELSE NULL END) col8,
	max(CASE WHEN ordinal_position = 9 THEN column_name
	  ELSE NULL END) col9
  FROM information_schema.columns
  WHERE table_schema = 'bank' AND table_name = 'product'
  GROUP BY table_name
 ) cols;
 
SELECT @qry;

PREPARE dynsql3 FROM @qry;
SET @prodcd = 'MM';
EXECUTE dynsql3 USING @prodcd;
DEALLOCATE PREPARE dynsql3;

-- Again, it's generally better to use a procedural language for the above.

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 15-1
--  Write a query that lists all of the indexes in the bank.schema. 
--  Include the table names.
SELECT table_name, index_name
FROM information_schema.statistics
WHERE table_schema = 'bank'
ORDER BY 1,2;

-- Book Answer:
--  Note: without DISTINCT, multicolumn indices appear once for each column
--   they span.
SELECT DISTINCT table_name, index_name
FROM information_schema.statistics
WHERE table_schema = 'bank';

-- Exercise 15-2
--  Write a query that generates output that can be used to create all of the 
--  indexes on the bank.employee table. Output should be of the form:
--    "ALTER TABLE <table_name> ADD INDEX <index_name> (<column_list>)"
SELECT concat(
  CASE
    WHEN st.seq_in_index = 1 THEN -- if it's an index, start string
	  concat('ALTER TABLE ', st.table_name, ' ADD',
	    CASE
		  WHEN st.non_unique = 0 THEN ' UNIQUE ' -- if UNIQUE, write it
		  ELSE ' '
		END,
		'INDEX ', -- ADD (UNIQUE) INDEX 
		st.index_name, ' (', st.column_name) -- open '(' for first column
	ELSE concat(', ', st.column_name)        -- append multicolumns if exist
  END,
  CASE -- if the seq_in_index is the maximum, close ');'
    WHEN st.seq_in_index =
	 (SELECT max(st2.seq_in_index)
	  FROM information_schema.statistics st2
	  WHERE st2.table_schema = st.table_schema
	    AND st2.table_name = st.table_name
		AND st2.index_name = st.index_name)
	  THEN ');'
	ELSE ''
  END
 ) index_creation_statement
FROM information_schema.statistics st
WHERE st.table_schema = 'bank'
  AND st.table_name = 'employee'
ORDER BY st.index_name, st.seq_in_index;