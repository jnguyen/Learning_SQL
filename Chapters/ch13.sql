/* ************* LEARNING SQL CHAPTER 13 *************** */
/* ************   INDEXES AND CONSTRAINTS            *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Indexes                                 ****/
/* ******************************************** ****/
-- Since tables have no default ordering, SQL will query every row
--  Each row it finds is added to a result set, a process called a 'table scan'
SELECT dept_id, name
FROM department
WHERE name LIKE 'A%'

-- Indexes facilitate the retrieval of a subset without querying all rows

-- Index Creation
--  To ADD an INDEX, you must ALTER the TABLE
-- Note: MySQL treats indices as optional table components, while other servers
--  such as SQL Server and Oracle treat them as separate schema objects
ALTER TABLE department
ADD INDEX dept_name_idx (name);

-- To see available indexes in MySQL, use SHOW
SHOW INDEX FROM department \G

-- To remove indexes, you DROP them
ALTER TABLE department
DROP INDEX dept_name_idx;

-- Unique indexes
--  You can force a column to have distinct names with indexes
ALTER TABLE department
ADD UNIQUE dept_name_idx (name);

-- A unique index prevents addition of duplicate names
--  Ex. Adding a duplicate name in department table
-- Note: Primary key indexes are already checked for uniqueness
INSERT INTO department (dept_id, name)
VALUES (999, 'Operations');

-- Multicolumn indexes
--  You may build indexes that span multiple columns
-- Ex. An index for first and last names in the table employee
-- Note: You can build multiple indexes sharing same columns in different order
ALTER TABLE employee
ADD INDEX emp_names_idx(lname, fname);

-- Types of Indexes
--  B-tree indexes: balanced-tree indexes, the default index.
--   * server tries to keep nodes as balanced as possible, adding and removing
--      nodes as it sees fit to maintain performance
--  Bitmap indexes: best for low-cardinality data, included in Oracle
--   * makes a map for each column value and row, marking 1 if a value is 
--      present in the row. breaks down for high-cardinality data
--   * common in data warehousing where large data is stored on columns 
--      with relatively few values (e.g. products, sales quarters)
--  Text indexes: index text documents.
--   * Oracle has Oracle Text
--   * MySQL and SQL Server have full-text indexes
--   * MyISAM storage is needed for full-text indexes with MySQL

-- How Indexes Are Stored
--  Indexes are used to quickly locate rows. Consider this:
SELECT emp_id, fname, lname
FROM employee
WHERE emp_id IN (1, 3, 9, 15);
-- The server used the IDs to locate information in the table
-- If an index contains all needed to satisfy a query, then visiting the table
--  is unneeded. Consider this:
SELECT cust_id, SUM(avail_balance) tot_bal
FROM account
WHERE cust_id IN (1, 5, 9, 11)
GROUP BY cust_id;

-- You can ask MySQL to EXPLAIN its execution plan
EXPLAIN SELECT cust_id, SUM(avail_balance) tot_bal
FROM account
WHERE cust_id IN (1, 5, 9, 11)
GROUP BY cust_id;
-- SQL Server: set showplan_text
-- Oracle: explain plan

-- Add new index called acc_bal_idx on both cust_id and avail_balance
ALTER TABLE account
ADD INDEX acc_bal_idx (cust_id, avail_balance);

-- EXPLAIN how it will perform the search now
--  The optimizer now doesn't need to look at account, and will query 8 rows
EXPLAIN SELECT cust_id, SUM(avail_balance) tot_bal
FROM account
WHERE cust_id IN (1, 5, 9, 11)
GROUP BY cust_id \G

-- The Downside of Indexes
--  Recall that every index in reality is a table, so that whenever a row
--   is inserted or modified, all indexes are also modified.
--  It is practical to create indexes and drop them while they aren't needed
--  For example: create index during day for users, drop overnight 

-- One strategy:
--  * All primary key columns indexed. For multicolumn primary keys, consider
--     building additional indexes on a subset of them in different orders
--  * Build indexes on all columns referenced in foreign key constraints
--  * Build indexes on common access paths

/* ******************************************** ****/
/* ***  Constraints                             ****/
/* ******************************************** ****/
-- Constraints are restrictions on one or more columns.
--  Primary key: one or more columns that guarantee uniqueness in a table
--  Foreign key: one or more columns that contain another table's primary key
--  Unique: one or more columns with unique values in a table
--  Check: restrict allowable values 

-- Constraint Creation
--  Usually created along with table, ex:
CREATE TABLE product
 (product_cd VARCHAR(10) NOT NULL,
  name VARCHAR(50) NOT NULL
  product_type_cd VARCHAR (10) NOT NULL,
  date_offered DATE
  date_retired DATE,
      CONSTRAINT fk_product_type_cd FOREIGN KEY (product_type_cd)
	    REFERENCES product_type (product_type_cd),
	  CONSTRAINT pk_product PRIMARY KEY (product_cd)
 );
 
-- You can always add the constraints later with ALTER TABLE
ALTER TABLE product
ADD CONSTRAINT fk_product_type_cd FOREIGN KEY (product_type_cd)
  REFERENCES product_type (product_type_cd);

ALTER TABLE product  
ADD CONSTRAINT pk_product PRIMARY KEY (product_cd);

-- You can also DROP constraints
ALTER TABLE product
DROP PRIMARY KEY;

ALTER TABLE product
DROP FOREIGN KEY fk_product_type_cd;

-- You probably shouldn't drop primary keys, but foreign keys may be dropped
--  for maintenance purposes

-- Constraints and Indexes
--  Different DBMSs have unique ways of generating (or not) indexes at the 
--   time of constraint creation

-- Cascading Constraints
--  If a user inserts a new row or changes a row such that a foreign key 
--   column doesn't have a matching value, the server raises an error.
SELECT product_type_cd, name
FROM product_type;

SELECT product_type_cd, product_cd, name
FROM product
ORDER BY product_type_cd;

-- Ex. Change child product_type_cd in product to one that doesn't exist
UPDATE product
SET product_type_cd = 'XYZ'
WHERE product_type_cd = 'LOAN';

-- Ex. Change parent product_type in product_type
UPDATE product_type
SET product_type_cd = 'XYZ'
WHERE product_type_cd = 'LOAN';

-- Using a cascading update can update all child rows for you
-- Ex.
ALTER TABLE product
DROP FOREIGN KEY fk_product_type_cd;

ALTER TABLE product
ADD CONSTRAINT fk_product_type_cd FOREIGN KEY (product_type_cd)
  REFERENCES product_type (product_type_cd)
  ON UPDATE CASCADE;
  
UPDATE product_type
SET product_type_cd = 'XYZ'
WHERE product_type_cd = 'LOAN';
-- Ex. Check that the update worked
SELECT product_type_cd, name
FROM product_type;

SELECT product_type_cd, product_cd, name
FROM product
ORDER BY product_type_cd;

-- Note that you can also specify cascading DELETE as well:
ALTER TABLE product
ADD CONSTRAINT fk_product_type_cd FOREIGN KEY (product_type_cd)
  REFERENCES product_type (product_type_cd)
  ON UPDATE CASCADE
  ON DELETE CASCADE;
  
/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 13-1 
--  Modify the account table so that customers may not have more than one
--   account for each product.
ALTER TABLE account
ADD UNIQUE a_cust_prod_idx (cust_id, product_cd);

-- Book answer:
ALTER TABLE account
ADD CONSTRAINT account_unq1 UNIQUE (cust_id, product_cd);

-- Exercise 13-2
--  Generate a multicolumn index on the transaction table that could be used
--   by both of the following queries:
-- SELECT txn_date, account_id, txn_type_cd, amount
-- FROM transaction
-- WHERE txn_date > cast('2008-12-31 23:59:59' as datetime);

-- SELECt txn_date, account_id, txn_type_cd, amount
-- FROM transaction
-- WHERE txn_date > cast('2008-12-31 23:59:59' as datetime)
--   AND amount < 1000;
ALTER TABLE transaction
ADD INDEX txn_idx01 (txn_date, amount);