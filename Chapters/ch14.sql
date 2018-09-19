/* ************* LEARNING SQL CHAPTER 14 *************** */
/* ************          VIEWS                       *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  What Are Views?                         ****/
/* ******************************************** ****/
-- A mechanism for querying data. No data storage required.
-- Ex. Mask some digits of federal IDs (SSNs) using a view
CREATE VIEW customer_vw
 (cust_id,
  fed_id,
  cust_type_cd,
  address,
  city,
  state,
  zipcode
 )
AS
SELECT cust_id,
  concat('ends in ', substr(fed_id, 8, 4)) fed_id,
  cust_type_cd,
  address,
  city,
  state,
  postal_code
FROM customer;

-- Views are just definitions, stored for later use. To use a view, you just
--  query it as if it were a table.
SELECT cust_id, fed_id, cust_type_cd
FROM customer_vw;

-- The actual query performed is a combination of the view and query of it
SELECT cust_id,
  concat('ends in ', substr(fed_id, 8, 4)) fed_id,
  cust_type_cd
FROM customer;

-- Use the DESCRIBE command to see what columns are in the view
DESCRIBE customer_vw;

-- Ex. You can use a view exactly as how you would a table
SELECT cust_type_cd, count(*)
FROM customer_vw
WHERE state = 'MA'
GROUP BY cust_type_cd
ORDER BY 1;

-- Ex. You can also join views to other tables or views within a query
SELECT cst.cust_id, cst.fed_id, bus.name
FROM customer_vw cst INNER JOIN business bus
  ON cst.cust_id = bus.cust_id;
  
/* ******************************************** ****/
/* ***  Why Use Views?                          ****/
/* ******************************************** ****/
-- Data Security
--  Views are useful to keep PHI safe and to comply with relevant laws.
-- Ex: only allow business customers to be queried
CREATE VIEW business_customer_vw
 (cust_id,
  fed_id,
  cust_type_cd,
  address,
  city,
  state,
  zipcode
 )
AS
SELECT cust_id,
  concat('end in ', substr(fed_id, 8, 4)) fed_id,
  cust_type_cd,
  address,
  city,
  state,
  postal_code
FROM customer
WHERE cust_type_cd = 'B';
-- Oracle can also achieve this using policies

-- Data Aggregation
--  Views are useful to make data appear pre-aggregated
-- Ex. Provide application writers a view of aggregated data
CREATE VIEW customer_totals_vw
 (cust_id,
  cust_type_cd,
  cust_name,
  num_accounts,
  tot_deposits
 )
AS
SELECT cst.cust_id, cst.cust_type_cd,
  CASE
    WHEN cst.cust_type_cd = 'B' THEN
	 (SELECT bus.name FROM business bus WHERE bus.cust_id = cst.cust_id)
	ELSE
	 (SELECT concat(ind.fname, ' ', ind.lname)
	  FROM individual ind
	  WHERE ind.cust_id = cst.cust_id)
  END cust_name,
  sum(CASE WHEN act.status = 'ACTIVE' THEN 1 ELSE 0 END) tot_active_accounts,
  sum(CASE WHEN act.status = 'ACTIVE' THEN act.avail_balance ELSE 0 END) tot_balance
FROM customer cst INNER JOIN account act
  ON act.cust_id = cst.cust_id
GROUP BY cst.cust_id, cst.cust_type_cd;

-- Ex. Let's say you wanted pre-aggregated rather than as a view. You can 
--  use the view to pre-populate the new table
CREATE TABLE customer_totals
AS
SELECT * FROM customer_totals_vw;
 /* update view to pull from new customer_totals table */
CREATE OR REPLACE VIEW customer_totals_vw
 (cust_id,
  cust_type_cd,
  cust_name,
  num_accounts,
  tot_deposits
 )
AS
SELECT cust_id, cust_type_cd, cust_name, num_accounts, tot_deposits
FROM customer_totals;

-- Hiding Complexity
--  Ex. Create a view to simplify querying multiple tables
-- Note: We use scalar subqueries here. If no columns using the subqueries
--  are referenced, then no subqueries will be executed.
CREATE VIEW branch_activity_vw
 (branch_name,
  city,
  state,
  num_employees,
  num_active_accounts,
  tot_transactions
 )
AS
SELECT br.name, br.city, br.state,
 (SELECT count(*)
  FROM employee emp
  WHERE emp.assigned_branch_id = br.branch_id) num_emps,
 (SELECT count(*)
  FROM account acnt
  WHERE acnt.status = 'ACTIVE' AND acnt.open_branch_id = br.branch_id) num_accounts,
 (SELECT count(*)
  FROM transaction txn
  WHERE txn.execution_branch_id = br.branch_id) num_txns
FROM branch br;

-- Joining Partitioned Data
--  Breaking large tables into pieces can improve performance, for example
--   breaking up transactions into last 6 months and all transactions
-- Ex. Join 6 month transactions and historic transactions to query a single
--  account's history.
-- Remark: Designers can change structure of underlying data without forcing
--  users to modify their queries.
CREATE VIEW transaction_vw
 (txn_date,
  account_id,
  txn_type_cd,
  amount,
  teller_emp_id,
  execution_branch_id,
  funds_avail_date
 )
AS
SELECT txn_date, account_id, txn_type_cd, amount, teller_emp_id
  execution_branch_id, funds_avail_date
FROM transaction_historic
UNION ALL
SELECT txn_date, account_id, txn_type_cd, amount, teller_emp_id,
  execution_branch_id, funds_avail_date
FROM transaction_current;

/* ******************************************** ****/
/* ***  Updatable Views                         ****/
/* ******************************************** ****/
-- Sometimes, users need to update data too. This is achievable through views
--  with a few restrictions.
--  * No aggregate functions allowed
--  * The view does not use GROUP BY or HAVING clauses
--  * No subqueries in EXIST or FROM; no subqueries in WHERE referring to FROM
--  * No UNION, UNION ALL, or DISTINCT
--  * The FROM clause includes at least one table or updatable view
--  * The FROM clause uses only INNER JOINS if >= 1 table or view

-- Updating Simple Views
--  Recall customer_vw (see above).
-- Ex. We can update the customer table using the view!
UPDATE customer_vw
SET city = 'Woooburn'
WHERE city = 'Woburn';

SELECT DISTINCT city FROM customer;

-- Ex. You cannot, however, edit fed_id, since it was derived from expression
UPDATE customer_vw
SET city = 'Woburn', fed_id = '999999999'
WHERE city = 'Woburn';

-- Ex. You cannot insert data, since derived columns cannot be used for INSERT
INSERT INTO customer_vw(cust_id, cust_type_cd, city)
VALUES (9999, 'I', 'Worcester');

-- Updating Complex Views
--  Recall business_customer_vw (see above).
DROP VIEW business_customer_vw;

CREATE VIEW business_customer_vw
 (cust_id,
  fed_id,
  address,
  city,
  state,
  postal_code,
  business_name,
  state_id,
  incorp_date
 )
AS
SELECT cst.cust_id,
  cst.fed_id,
  cst.address,
  cst.city,
  cst.state,
  cst.postal_code,
  bsn.name,
  bsn.state_id,
  bsn.incorp_date
FROM customer cst INNER JOIN business bsn
  ON cst.cust_id = bsn.cust_id
WHERE cust_type_cd = 'B';

-- Ex. You may use the view to update data in customer or business
UPDATE business_customer_vw     /* modifies customer */
SET postal_code = '99999'
WHERE cust_id = 10;

UPDATE business_customer_vw     /* modifies business */
SET incorp_date = '2008-11-17'
WHERE cust_id = 10;

-- Ex. You cannot modify two tables at once in a single statement, though.
UPDATE business_customer_vw
SET postal_code = '88888', incorp_date = '2008-10-31'
WHERE cust_id = 10;

-- Ex. Insert data for a new customer with ID 99 into customer table -- works
INSERT INTO business_customer_vw
 (cust_id, fed_id, address, city, state, postal_code)
VALUES (99, '04-9999999', '99 Main St.', 'Peabody', 'MA', '01975');

-- Ex. Insert data into business using view -- doesn't work
--  Note: both customer and business have cust_id, but cust_id in the view is
--   mapped to customer.cust_id, so we cannot insert this data into the 
--   business table using the view definition.
INSERT INTO business_customer_vw
 (cust_id, business_name, state_id, incorp_date)
VALUES (99, 'Ninety-Nine Restaurant', '99-999-999', '1999-01-01');
/* reset table */
DROP FROM customer
WHERE cust_id = 99;

-- Updating tables through views can be tricky. SQL Server and Oracle Database
--  include instead-of triggers, which intercept insert, update, and delete
--  statements to use custom code to incorporate changes if needed.

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 14-1
--  Create a view that queries the employee table and generates the following
--  output when queried with no WHERE clause:
-- +-----------------+------------------+
-- | supervisor_name | employee_name    |
-- +-----------------+------------------+
-- | NULL            | Michael Smith    |
-- | Michael Smith   | Susan Barker     |
-- | Michael Smith   | Robert Tyler     |
-- | Robert Tyler    | Susan Hawthorne  |
-- | Susan Hawthorne | John Gooding     |
-- | Susan Hawthorne | Helen Fleming    |
-- | Helen Fleming   | Chris Tucker     |
-- | Helen Fleming   | Sarah Parker     |
-- | Helen Fleming   | Jane Grossman    |
-- | Susan Hawthorne | Paula Roberts    |
-- | Paula Roberts   | Thomas Ziegler   |
-- | Paula Roberts   | Samantha Jameson |
-- | Susan Hawthorne | John Blake       |
-- | John Blake      | Cindy Mason      |
-- | John Blake      | Frank Portman    |
-- | Susan Hawthorne | Theresa Markham  |
-- | Theresa Markham | Beth Fowler      |
-- | Theresa Markham | Rick Tulman      |
-- +-----------------+------------------+
-- 18 rows in set (1.47 sec)
CREATE VIEW employee_sup_vw
 (supervisor_name,
  employee_name
 )
AS
SELECT CONCAT(sup.fname, ' ', sup.lname), 
  CONCAT(emp.fname, ' ', emp.lname)
FROM employee sup RIGHT OUTER JOIN employee emp
  ON sup.emp_id = emp.superior_emp_id;
  
-- Exercise 14-2
--  The bank president would like to have a report showing the name and city of
--  each branch, along with the total balances of all accounts opened at the 
--  branch. Create a view to generate the data.
CREATE VIEW branch_balance_vw
 (branch_id,
  name,
  city,
  tot_balance
 )
AS
SELECT b.branch_id, b.name, b.city,
 (SELECT SUM(avail_balance)
  FROM account a
  WHERE b.branch_id = a.open_branch_id) tot_balance
FROM branch b;

-- Book Answer (uses inner join):
CREATE VIEW branch_summary_vw
 (branch_name,
  branch_city,
  total_balance
 )
AS
SELECT b.name, b.city, sum(a.avail_balance)
FROM branch b INNER JOIN account a
  ON b.branch_id = a.open_branch_id
GROUP BY b.name, b.city;