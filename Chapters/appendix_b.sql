/* ************* LEARNING SQL APPENDIX B *************** */
/* ************ MYSQL EXTENSIONS TO THE SQL LANGUAGE *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Extensions to the select Statement      ****/
/* ******************************************** ****/
-- MySQL includes two extra clauses

/* ******** The LIMIT clause      ********* */
--  LIMIT allows us to restrict the number of rows returned by a query
-- Here's the number of accounts opened by each bank teller
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id;

-- Ex. LIMIT the previous query to 3 results only
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
LIMIT 3;

-- Combining the LIMIT clause with the ORDER BY clause
-- Ex. Limit to top 3 tellers with most accounts opened
-- Note: LIMIT clauses are applied after all other SQL clauses
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
ORDER BY how_many DESC
LIMIT 3;

-- The LIMIT clause's optional second parameter
--  With two parameters: (start [inclusive], how_many)
-- Ex. Get the third record from above
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
ORDER BY how_many DESC
LIMIT 2, 1;

-- Ex. Start at 2nd record (counting from 0), include all else
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
ORDER BY how_many DESC
LIMIT 2, 999999999; /* just make the second arg obnoxiously large */

-- Ranking queries
--  When combined with an ORDER BY clause, LIMIT clauses can rank data
-- Ex. Two worst performers among tellers
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
ORDER BY how_many ASC
LIMIT 2; 

/* ******** The INTO OUTFILE clause ******* */
-- Use INTO OUTFILE to output results into a file
-- Note: Disable --secure-file-priv from config; disable before startup only
SELECT emp_id, fname, lname, start_date
INTO OUTFILE 'C:\\TEMP\\emp_list_delim.txt'
FROM employee;

-- By default, INTO OUTFILE uses ('\t') between columns and ('\n') between rows
-- Ex. Change delimiter to pipe '|'
-- Warning: INTO OUTFILE does not allow you to replace a file!
SELECT emp_id, fname, lname, start_date
INTO OUTFILE 'C:\\TEMP\\emp_list.txt'
  FIELDS TERMINATED BY '|'
FROM employee;

-- Luckily, MySQL handles commas in strings by auto-placing an escape '\' 
-- Ex. Export results to a comma-delimited format (i.e. csv)
SELECT data.num, data.str1, data.str2
INTO OUTFILE 'C:\\TEMP\\emp_list_delim.txt'
  FIELDS TERMINATED BY ','
FROM 
 (SELECT 1 num, 'This string has no commas' str1,
    'This string, however, has two commas' str2) data;

-- Ex. You can use a different escape character, if you want
SELECT data.num, data.str1, data.str2
INTO OUTFILE 'C:\\TEMP\\comma1.txt'
  FIELDS TERMINATED BY ','
  FIELDS ESCAPED BY '/'
FROM 
 (SELECT 1 num, 'This string has no commas' str1,
    'This string, however, has two commas' str2) data;
	
-- Ex. You can use a different newline character, e.g. '@'
SELECT emp_id, fname, lname, start_date
INTO OUTFILE 'C:\\TEMP\\emp_lsit_atsign.txt'
  FIELDS TERMINATED BY '|'
  LINES TERMINATED BY '@'
FROM employee;

/* ******************************************** ****/
/* ***  Combination Insert/Update Statements    ****/
/* ******************************************** ****/
-- Suppose you want info about when a customer visits a bank branch. Then 
--  a new visit adds a new row, but subsequent visits should just update
--  the datetime column (i.e. last visit)
-- Ex. branch_usage table, with (branch_id, cust_id, last_visited_on)
CREATE TABLE branch_usage
 (branch_id SMALLINT UNSIGNED NOT NULL,
  cust_id INTEGER UNSIGNED NOT NULL,
  last_visited_on DATETIME,
  CONSTRAINT pk_branch_usage PRIMARY KEY (branch_id, cust_id)
 );

-- Suppose customer ID 5 visits the main branch (ID 1) three times in week 1.
-- Ex. After visit 1, create a new row
INSERT INTO branch_usage (branch_id, cust_id, last_visited_on)
VALUES (1, 5, CURRENT_TIMESTAMP());

-- MySQL includes a DUPLICATE KEY UPDATE in case you want to just update 
--  the row given that it exists, and insert a new row if not, called an upsert
-- Ex. Insert row for visit, or update last_visited_on if it already exists
INSERT INTO branch_usage (branch_id, cust_id, last_visited_on)
VALUES (1, 5, CURRENT_TIMESTAMP())
ON DUPLICATE KEY UPDATE last_visited_on = CURRENT_TIMESTAMP();

-- Discussion: REPLACE achieves the same thing, but involves a DELETE, which
--  can have a ripple effect with foreign keys using CASCADE updates with 
--  InnoDB. DUPLICATE KEY is thus regarded as safer.

/* ******************************************** ****/
/* ***  Ordered Updates and Deletes             ****/
/* ******************************************** ****/
-- Suppose you had a table of customer logins
CREATE TABLE login_history
 (cust_id INTEGER UNSIGNED NOT NULL,
  login_date DATETIME,
  CONSTRAINT pk_login_history PRIMARY KEY (cust_id, login_date)
 );
 
-- Let's create fake logins using a cross join between account and customer
INSERT INTO login_history (cust_id, login_date)
SELECT c.cust_id,
  ADDDATE(a.open_date, INTERVAL a.account_id * c.cust_id HOUR)
FROM customer c CROSS JOIN account a;

-- We need to look at login_history once a month to see who's using the site,
--  and then keep the 50 most recent records.
-- Ex. Approach 1: use ORDER BY and LIMIT to find 50th most recent login
SELECT login_date
FROM login_history
ORDER BY login_date DESC
LIMIT 49, 1;
/* delete everything before that date */
DELETE FROM login_history
WHERE login_date < '2004-07-02 09:00:00';

-- Ex. Approach 2: use ORDER BY and LIMIT to delete all but 50 recent records
DELETE FROM login_history
ORDER BY login_date ASC
LIMIT 262;

-- Ex. Approach 3: same as 2, except we don't need to know the # of records
-- Warning: MySQL doesn't allow two parameter LIMIT clauses when using DELETE
DELETE FROM login_history
ORDER BY login_date DESC
LIMIT 49, 999999999;

-- You can use LIMIT and ORDER BY to modify data
-- Ex. Add $100 to oldest 10 accounts
UPDATE account
SET avail_balance = avail_balance + 100
WHERE product_cd IN ('CHK', 'SAV', 'MM')
ORDER BY open_date ASC
LIMIT 10;

/* ******************************************** ****/
/* ***  Multitable Updates and Deletes          ****/
/* ******************************************** ****/
-- For this section, we create duplicate tables to preserve the bank schema
CREATE TABLE individual2 AS
SELECT * FROM individual;
CREATE TABLE customer2 AS
SELECT * FROM customer;
CREATE TABLE account2 AS
SELECT * FROM account;

-- Ex. Delete customer ID 1 from all tables
DELETE FROM account2
WHERE cust_id = 1;
DELETE FROM customer2
WHERE cust_id = 1;
DELETE FROM individual2
WHERE cust_id = 1;

-- MySQL allows us to accomplish the above with a multitable DELETE
-- Ex. Delete information for customer ID 1
DELETE account2, customer2, individual2    /* specify table names */
FROM account2 INNER JOIN customer2         /* tables used to identify rows */
  ON account2.cust_id= customer2.cust_id
  INNER JOIN individual2
  ON customer2.cust_id= individual2.cust_id
WHERE individual2.cust_id= 1;              /* filter conditions for deletion */

-- Note that the syntax is basically the SELECT syntax
SELECT account2.account_id
FROM account2 INNER JOIN customer2         
  ON account2.cust_id= customer2.cust_id
  INNER JOIN individual2
  ON customer2.cust_id= individual2.cust_id
WHERE individual2.fname = 'John'
  AND individual2.lname = 'Hayward';  

-- Ex. Same as SELECT statement above replaced with DELETE clause; we delete
--  all of John Hayward's accounts
DELETE account2
FROM account2 INNER JOIN customer2         
  ON account2.cust_id= customer2.cust_id
  INNER JOIN individual2
  ON customer2.cust_id= individual2.cust_id
WHERE individual2.fname = 'John'
  AND individual2.lname = 'Hayward'; 

-- Ex. Subquery version of the DELETE statement above
DELETE FROM account2
WHERE cust_id = 
 (SELECT cust_id
  FROM individual2
  WHERE fname = 'John' AND lname = 'Hayward');
  
-- Discussion: Real power of multidelete is that we can delete from multiple
--  tables at a time. Otherwise, the subquery format is probably OK

-- We can also perform a multitable UPDATE
-- Ex. Increment customer ID 3 by 10,000 to migrate customers due to merger
UPDATE individual2 INNER JOIN customer2     /* UPDATE clause contains JOINS */
  ON individual2.cust_id = customer2.cust_id
  INNER JOIN account2
  ON customer2.cust_id = account2.cust_id
SET individual2.cust_id = individual2.cust_id + 10000,
  customer2.cust_id = customer2.cust_id + 10000,
  account2.cust_id = account2.cust_id + 10000
WHERE individual2.cust_id = 3;

-- Note: If using InnoDB, multitable DELETE and UPDATE statements do not 
--  ensure that foreign key constraints are met. The safest thing to do is
--  to update one table at a time. 

-- Drop all the duplicate tables for this section
DROP TABLE account2;
DROP TABLE individual2;
DROP TABLE customer2;