/* ************* LEARNING SQL CHAPTER 8 **************** */
/* ************ GROUPING AND AGGREGATES              *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Grouping Concepts                       ****/
/* ******************************************** ****/
-- Suppose you needed to find how many accounts were opened by each teller
--  You could start by looking at a list of all IDs
SELECT open_emp_id
FROM account;

-- What if you couldn't see the full list because of duplicates? GROUP BY!
SELECT open_emp_id
FROM account
GROUP BY open_emp_id; /* arranges by unique IDs */

-- We can use aggregate functions with GROUP BY, such as COUNT(*)
--  Ex. Get the number of accounts opened by each employee ID.
SELECT open_emp_id, COUNT(*) how_many /* (*) says count everything */
FROM account
GROUP BY open_emp_id;

-- GROUP BY runs after the WHERE clause, so you can't filter groups in WHERE
--  Ex. Trying to filter COUNT(*) in the WHERE statement throws an error
SELECT open_emp_id, COUNT(*) how_many
FROM account
WHERE COUNT(*) > 4
GROUP BY open_emp_id;

-- Filter groups generated by GROUP BY with the keyword HAVING
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
HAVING COUNT(*) > 4; /* employee 13 opened 3 accounts, and is thus excluded */

/* ******************************************** ****/
/* ***  Aggregate Functions                     ****/
/* ******************************************** ****/
-- Aggregate functions perform an operation on all rows in a group
--  Ex. MAX(), MIN(), AVG(), SUM(), COUNT() can generate summary statistics
SELECT MAX(avail_balance) max_balance,
  MIN(avail_balance) min_balance,
  AVG(avail_balance) avg_balance,
  SUM(avail_balance) tot_balance,
  COUNT(*) num_accounts
FROM account
WHERE product_cd = 'CHK';

-- Implicit Versus Explicit Groups
--  The previous query implicitly selected all WHERE filtered rows as a group
--  What if you wanted aggregates for every product type? A naive query:
SELECT MAX(avail_balance) max_balance,
  MIN(avail_balance) min_balance,
  AVG(avail_balance) avg_balance,
  SUM(avail_balance) tot_balance,
  COUNT(*) num_accounts
FROM account; /* MySQL 8.0: results among all accounts */

-- Explicitly grouping with GROUP BY will allow us to see by product type
SELECT product_cd,
  MAX(avail_balance) max_balance,
  MIN(avail_balance) min_balance,
  AVG(avail_balance) avg_balance,
  SUM(avail_balance) tot_balance,
  COUNT(*) num_accounts
FROM account
GROUP BY product_cd;

-- Counting Distinct Values
--  COUNT() can count all rows or distinct values only.
-- Get employee ID responsible for opening each account ID
SELECT account_id, open_emp_id
FROM account
ORDER BY open_emp_id;

-- What if we wanted to count the number of employees that opened accounts?
--  The following would simply count the number of rows of employee IDs
SELECT COUNT(open_emp_id) /* same as COUNT(*) */
FROM account;

-- If we specify DISTINCT, we can count unique IDs only 
SELECT COUNT(DISTINCT open_emp_id)
FROM account;

-- Using Expressions
--  Expressions can be passed as arguments
--  Ex. Find the maximum uncleared balance as pending - available
SELECT MAX(pending_balance - avail_balance) max_uncleared
FROM account;

-- How Nulls Are Handled
--  Nulls may mess things up if not handled properly: always consider them
-- Create example table
CREATE TABLE number_tbl
  (val SMALLINT);
INSERT INTO number_tbl VALUES(1);
INSERT INTO number_tbl VALUES(3);
INSERT INTO number_tbl VALUES(5);

-- Let's perform five aggregate functions on the set of numbers we just made
SELECT COUNT(*) num_rows, /* 3 */
  COUNT(val) num_vals,    /* 3 */
  SUM(val) total,
  MAX(val) max_val,
  AVG(val) avg_val
FROM number_tbl;

-- Let's add a NULL value and rerun the aggregate query 
INSERT INTO number_tbl VALUES (NULL);

-- COUNT(*) includes NULL values, while all others ignore them
SELECT COUNT(*) num_rows, /* 4: includes the NULL row */
  COUNT(val) num_vals,    /* 3: excludes the NULL row */
  SUM(val) total,
  MAX(val) max_val,
  AVG(val) avg_val
FROM number_tbl;

/* ******************************************** ****/
/* ***  Generating Groups                       ****/
/* ******************************************** ****/
-- We typically want to work with groups of data in practice

-- Single-Column Grouping
-- Ex. Find the total balances for each product
SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
GROUP BY product_cd;

-- Multicolumn Grouping
-- Ex. Find total balances by Product-Branches
SELECT product_cd, open_branch_id,
  SUM(avail_balance) tot_balance
FROM account
GROUP BY product_cd, open_branch_id; /* separate multiple groups by commas */

-- Grouping via Expressions
-- Ex. Group employees by the year they started working for the bank
SELECT EXTRACT(YEAR FROM start_date) year,
  COUNT(*) how_many
FROM employee
GROUP BY EXTRACT(YEAR FROM start_date);

-- Generating Rollups
-- WITH ROLLUP can also perform the aggregate for the top level group
-- Ex. Find total balances by Product-Branches and include total per product
SELECT product_cd, open_branch_id,
  SUM(avail_balance) tot_balance
FROM account
GROUP BY product_cd, open_branch_id WITH ROLLUP; /* sums rows per group */

-- Ex. WITH CUBE can also perform the aggregate for all unique combinations
-- Note: WITH CUBE is not implemented as of MySQL 8.0
SELECT product_cd, open_branch_id,
  SUM(avail_balance) tot_balance
FROM account
GROUP BY product_cd, open_branch_id WITH CUBE;

/* ******************************************** ****/
/* ***  Group Filter Conditions                 ****/
/* ******************************************** ****/
-- HAVING allows us to filter by groups
-- Ex. Find the total balance of active accounts with balances greater than 10k
-- Note: WHERE filters before grouping, and HAVING filters after grouping
SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
WHERE status = 'ACTIVE'
GROUP BY product_cd
HAVING SUM(avail_balance) >= 10000;

-- MySQL throws an error if you include group filtering in the WHERE statement
SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
WHERE status = 'ACTIVE'
  AND SUM(avail_balance) > 10000 /* invalid use of group function */
GROUP BY product_cd;

-- You may include aggregate functions in HAVING that don't appear in SELECT
-- Ex. Find active account balances among products with minimum balances 
--      at least $1,000 and maximum balances at most $10,000.
SELECT product_cd, SUM(avail_balance) prod_balance
FROM account
WHERE status = 'ACTIVE'
GROUP BY product_cd
HAVING MIN(avail_balance) >= 1000
  AND MAX(avail_balance) <= 10000;
  
/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 8-1
--  Construct a query that counts the number of rows in the account table.
SELECT COUNT(*)
FROM account;

-- Exercise 8-2
--  Modify your query in Exercise 8-1 to count the number of accounts held by
--  each customer. Show the customer ID and the number of accounts for each 
--  customer.
SELECT cust_id, COUNT(*) num_accounts
FROM account
GROUP BY cust_id;

-- Exercise 8-3
--  Modify your query in Exercise 8-2 to include only those customers having
--  at least two accounts.
SELECT cust_id, COUNT(*) num_accounts
FROM account
GROUP BY cust_id
HAVING num_accounts >= 2;

SELECT cust_id, COUNT(*) num_accounts
FROM account
GROUP BY cust_id
HAVING COUNT(*) >= 2;

-- Exercise 8-4 (Extra Credit)
--  Find the total available balance by product and branch where there is more
--  than one account per product and branch. Order the results by total 
--  balance (highest to lowest).
SELECT product_cd, open_branch_id,
  SUM(avail_balance) tot_balance,
  COUNT(*) num_acc
FROM account
GROUP BY product_cd, open_branch_id
HAVING COUNT(*) > 1
ORDER BY tot_balance DESC; /* Book uses ORDER BY 3 because old version */