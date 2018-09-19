/* ************* LEARNING SQL CHAPTER 9 **************** */
/* ************         SUBQUERIES                   *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  What is a Subquery?                     ****/
/* ******************************************** ****/
-- A subquery is a query contained within a query
-- Data returned by a subquery is temporary and discarded
-- Ex. Get details of the latest account created
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE account_id = (SELECT MAX(account_id) FROM account);

-- Subqueries may be self-contained and run by themselves
SELECT MAX(account_id) FROM account;

-- The first query was the equivalent of the following
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE account_id = 29;

/* ******************************************** ****/
/* ***  Subquery Types                          ****/
/* ******************************************** ****/
-- Noncorrelated subquery: Self-contained query
-- Correlated subquery: references columns from the containing query

/* ******************************************** ****/
/* ***  Noncorrelated Subqueries                ****/
/* ******************************************** ****/
-- Most subqueries are noncorrelated unless they are insert/delete statements
-- Scalar subquery: returns a single row and column
--  Ex. Return all accounts not opened by Woburn Branch's Head Teller
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE open_emp_id <> (SELECT e.emp_id
  FROM employee e INNER JOIN branch b
    ON e.assigned_branch_id = b.branch_id
  WHERE e.title = 'Head Teller' AND b.city = 'Woburn');

-- Subqueries returning more than one row in an inequality throws an error
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE open_emp_id <> (SELECT e.emp_id
  FROM employee e INNER JOIN branch b
    ON e.assigned_branch_id = b.branch_id
  WHERE e.title = 'Teller' AND b.city = 'Woburn'); /* error: >1 row */

SELECT e.emp_id /* emp_id = {11, 12} */
FROM employee e INNER JOIN branch b
  ON e.assigned_branch_id = b.branch_id
WHERE e.title = 'Teller' AND b.city = 'Woburn';

-- Multiple-Row, Single-Column Subqueries
--  You can check if a single value is contained in a set using IN and NOT IN
-- Ex. Retrieve the cities belonging to Headquarters and Quincy Branch
SELECT branch_id, name, city
FROM branch
WHERE name IN ('headquarters', 'quincy Branch'); /* case insensitive */

-- Ex. The above example is logically doing this:
SELECT branch_id, name, city
FROM branch
WHERE name = 'headquarters' OR name = 'quincy Branch';

-- Ex. Select the employee IDs of all managers
SELECT emp_id, fname, lname, title
FROM employee
WHERE emp_id IN (SELECT superior_emp_id
  FROM employee);

-- Ex. Select all employee IDs that do not manage other employees
SELECT emp_id, fname, lname, title
FROM employee
WHERE emp_id NOT IN (SELECT superior_emp_id
  FROM employee
  WHERE superior_emp_id IS NOT NULL);
  
-- The ALL operator
--  ALL makes a comparison between a single value and all values of a set
--  Ex. Find all employee IDs not equal to any supervisor employee ID
SELECT emp_id, fname, lname, title
FROM employee
WHERE emp_id <> ALL (SELECT superior_emp_id
  FROM employee
  WHERE superior_emp_id IS NOT NULL);

-- Note: Any attempt to compare a null value results in unknown,
--       and neglecting to remove nulls will return an empty set 
SELECT emp_id, fname, lname, title
FROM employee
WHERE emp_id <> ALL (SELECT superior_emp_id
  FROM employee);
  
-- Ex. Find all accounts with balances smaller than all of Frank Tucker's
SELECT account_id, cust_id, product_cd, avail_balance
FROM account
WHERE avail_balance < ALL (SELECT a.avail_balance
  FROM account a INNER JOIN individual i
    ON a.cust_id = i.cust_id
  WHERE i.fname = 'Frank' AND i.lname = 'Tucker');

-- The subquery above returns a list of Frank Tucker's account balances
SELECT a.avail_balance
  FROM account a INNER JOIN individual i
    ON a.cust_id = i.cust_id
  WHERE i.fname = 'Frank' AND i.lname = 'Tucker';
  
-- The ANY operator
--  Works like ALL, but stops as soon as a favorable comparison is made
-- Ex. Find all accounts having a balance greater than any of Frank's accounts
SELECT account_id, cust_id, product_cd, avail_balance
FROM account
WHERE avail_balance > ANY (SELECT a.avail_balance
  FROM account a INNER JOIN individual i
    ON a.cust_id = i.cust_id
  WHERE i.fname = 'Frank' AND i.lname = 'Tucker');
  
-- Note: "in" is equivalent to "= any"

-- Multicolumn Subqueries
--  Some subqueries may return more than one column
-- Ex. Two subqueries linked by an AND
SELECT account_id, product_cd, cust_id   /* Select accounts... */
FROM account
WHERE open_branch_id = (SELECT branch_id /* ... from Woburn Branch ... */
  FROM branch
  WHERE name = 'Woburn Branch')
  AND open_emp_id IN (SELECT emp_id      /* ... opened by a teller ... */
  FROM employee
  WHERE title = 'Teller' OR title = 'Head Teller');
  
-- We can achieve the same as above with a single multicolumn subquery:
SELECT account_id, product_cd, cust_id
FROM account
WHERE (open_branch_id, open_emp_id) IN /* must be in same order as subquery */
 (SELECT b.branch_id, e.emp_id         /* same order as in WHICH statement  */
  FROM branch b INNER JOIN employee e
    ON b.branch_id = e.assigned_branch_id
  WHERE b.name = 'Woburn Branch'
    AND (e.title = 'Teller' OR e.title = 'Head Teller'));

/* ******************************************** ****/
/* ***  Correlated Subqueries                   ****/
/* ******************************************** ****/
-- Correlated subqueries references the containing statement, meaning that it
--  is not executed prior to execution of the container; it is executed once
--  per candidate row
-- Ex. Correlated subquery to count number of accounts for each customer
--      where the containing query retrives customers with exactly 2 accounts
SELECT c.cust_id, c.cust_type_cd, c.city
FROM customer c
WHERE 2 = (SELECT COUNT(*)
  FROM account a
  WHERE a.cust_id = c.cust_id); /* c comes from parent query */

-- Correlated subqueries can also use range conditions
-- Ex. Get list of customers with total balances between $5,000 and $10,000
SELECT c.cust_id, c.cust_type_cd, c.city
FROM customer c
WHERE (SELECT SUM(a.avail_balance)
    FROM account a
	WHERE a.cust_id = c.cust_id)
  BETWEEN 5000 AND 10000;
  
-- The EXISTS operator
--  Use EXISTS to identify if a relationship exists without regard for quantity
-- Ex. Find all accounts for which a transaction was posted on a given day
SELECT a.account_id, a.product_cd, a.cust_id, a.avail_balance
FROM account a
WHERE EXISTS (SELECT 1 /* simply checks if any rows returned */
  FROM transaction t
  WHERE t.account_id = a.account_id 
    AND t.txn_date = '2008-01-05');

-- You can technically make a fancy subquery with EXISTS 
--  But: convention is either select 1 or select *, since we only care if
--  a row was returned at all.
SELECT a.account_id, a.product_cd, a.cust_id, a.avail_balance
FROM account a
WHERE EXISTS (SELECT t.txn_id, 'hello', 3.1415927
  FROM transaction t
  WHERE t.account_id = a.account_id 
    AND t.txn_date = '2008-01-05');

-- NOT EXISTS finds whether a relationship doesn't exist.
-- Ex. Find all accounts not appearing in the business table
SELECT a.account_id, a.product_cd, a.cust_id
FROM account a
WHERE NOT EXISTS (SELECT 1
  FROM business b
  WHERE b.cust_id = a.cust_id);

-- Data Manipulation Using Correlated Subqueries
--  Correlated subqueries are helpful when using UPDATE, DELETE, and INSERT
-- Ex. Modify last_activity_date in the account table
UPDATE account a
SET a.last_activity_date =
 (SELECT MAX(t.txn_date)
  FROM transaction t
  WHERE t.account_id = a.account_id);
  
-- Ex. Check for null before modifying table to avoid returning empty rows
UPDATE account a
SET a.last_activity_date =
 (SELECT MAX(t.txn_date)
  FROM transaction t
  WHERE t.account_id = a.account_id)
WHERE EXISTS (SELECT 1
  FROM transaction t
  WHERE t.account_id = a.account_id);
  
-- Ex. Remove all data from department table with no child rows in employee
DELETE FROM department
WHERE NOT EXISTS(SELECT 1
  FROM employee
  WHERE employee.dept_id = department.dept_id);
  
-- Ex. Table aliases are not allowed when using delete + correlated subqueries
--  in MySQL, though this is typically allowed in other SQL servers.
DELETE FROM department d
WHERE NOT EXISTS (SELECT 1
  FROM employee e
  WHERE e.dept_id = d.dept_id);
  
/* ******************************************** ****/
/* ***  When To Use Subqueries                  ****/
/* ******************************************** ****/
-- Subqueries As Data Sources
-- Ex. Count number of employees by department and include name of each dept
SELECT d.dept_id, d.name, e_cnt.how_many num_employees
FROM department d INNER JOIN
 (SELECT dept_id, COUNT(*) how_many
  FROM employee
  GROUP BY dept_id) e_cnt
  ON d.dept_id = e_cnt.dept_id;

-- The subquery is noncorrelated, and counts the number of employees by dept_id
--  Note: Any subqueries in the FROM clause must be noncorrelated.
SELECT dept_id, COUNT(*) how_many
  FROM employee
  GROUP BY dept_id;

-- Data Fabrication
--  Subqueries can be used to generate data that doesn't exist in the database
-- Ex. Suppose you wanted to group accounts by income range:
SELECT 'Small Fry' name, 0 low_limit, 4999.99 high_limit
UNION ALL
SELECT 'Average Joes' name, 5000 low_limit, 9999.99 high_limit
UNION ALL
SELECT 'Heaver Hitter' name, 10000 low_limit, 9999999.99 high_limit;

-- Ex. Use the above query as a subquery to define balance groups to GROUP BY
--  and then classify each account based on total balance by those groups
-- Note: Book uses 'group' as the name, but this causes MySQL to think you
--  are actually issuing a group command! So I renamed them here to 'grp'
SELECT grp.name, COUNT(*) num_customers
FROM
 (SELECT SUM(a.avail_balance) cust_balance 
  FROM account a INNER JOIN product p
    ON a.product_cd = p.product_cd
  WHERE p.product_type_cd = 'ACCOUNT' /* total balances */
  GROUP BY a.cust_id) cust_rollup
  INNER JOIN 
 (SELECT 'Small Fry' name, 0 low_limit, 4999.99 high_limit
  UNION ALL
  SELECT 'Average Joes' name, 5000 low_limit,
    9999.99 high_limit
  UNION ALL
  SELECT 'Heavy Hitters' name, 10000 low_limit,
    9999999.99 high_limit) grp       /* balance groups */
  ON cust_rollup.cust_balance        /* joining on a range condition */
    BETWEEN grp.low_limit AND grp.high_limit
GROUP BY grp.name;

-- Task-oriented subqueries
-- Ex. Get total deposits into accounts opened by employees by branch
SELECT p.name product, b.name branch,
  CONCAT(e.fname, ' ', e.lname) name,
  SUM(a.avail_balance) tot_deposits
FROM account a INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
  INNER JOIN branch b
  ON a.open_branch_id = b.branch_id
  INNER JOIN product p
  ON a.product_cd = p.product_cd
WHERE p.product_type_cd = 'ACCOUNT'
GROUP BY p.name, b.name, e.fname, e.lname
ORDER BY product, branch;

-- Ex. The account table actually can perform the desired grouping with IDs
SELECT product_cd, open_branch_id branch_id, open_emp_id emp_id,
  SUM(avail_balance) tot_deposits
FROM account
GROUP BY product_cd, open_branch_id, open_emp_id;

-- Ex. We only need the other tables to get names, so we use a subquery:
SELECT p.name product, b.name branch,
  CONCAT(e.fname, ' ', e.lname) name,
  account_groups.tot_deposits
FROM
 (SELECT product_cd, open_branch_id branch_id,
    open_emp_id emp_id,
	SUM(avail_balance) tot_deposits
  FROM account
  GROUP BY product_cd, open_branch_id, open_emp_id) account_groups
  INNER JOIN employee e ON e.emp_id = account_groups.emp_id
  INNER JOIN branch b ON b.branch_id = account_groups.branch_id
  INNER JOIN product p ON p.product_cd = account_groups.product_cd
WHERE p.product_type_cd = 'ACCOUNT';

-- Ex. Same query as above, except with USING keyword
SELECT p.name product, b.name branch,
  CONCAT(e.fname, ' ', e.lname) name,
  account_groups.tot_deposits
FROM
 (SELECT product_cd, open_branch_id branch_id,
    open_emp_id emp_id,
	SUM(avail_balance) tot_deposits
  FROM account
  GROUP BY product_cd, open_branch_id, open_emp_id) account_groups
  INNER JOIN employee e USING (emp_id    )
  INNER JOIN branch b   USING (branch_id )
  INNER JOIN product p  USING (product_cd)
WHERE p.product_type_cd = 'ACCOUNT';

-- Subqueries in Filter Conditions
--  Use subqueries to filter data not just in WHERE, but in HAVING as well
-- Ex. Select employee who opened the most accounts using subqueries
SELECT open_emp_id, COUNT(*) how_many
FROM account
GROUP BY open_emp_id
HAVING COUNT(*) = (SELECT MAX(emp_cnt.how_many)
  FROM (SELECT COUNT(*) how_many
    FROM account
	GROUP BY open_emp_id) emp_cnt);
	
-- Subqueries As Expression Generators
--  Ex. Find total deposits by employee, product, and branch
-- Note: This query finds 3 extra NULL rows, and uses correlated subqueries
--  since the filter condition for 'ACCOUNT' is removed here. Since there is no
--  JOIN statement, we cannot filter the condition in the main query.
SELECT
 (SELECT p.name FROM product p
  WHERE p.product_cd = a.product_cd
    AND p.product_type_cd = 'ACCOUNT') product,
 (SELECT b.name FROM branch b
  WHERE b.branch_id = a.open_branch_id) branch,
 (SELECT CONCAT(e.fname, ' ', e.lname) FROM employee e
  WHERE e.emp_id = a.open_emp_id) name,
  SUM(a.avail_balance) tot_deposits
FROM account a
GROUP BY a.product_cd, a.open_branch_id, a.open_emp_id
ORDER BY product, branch;

-- Ex. Same as above, except dealing with the NULL condition
--  Idea: wrap the previous query in a subquery to enable WHERE filtering
--  to avoid using JOIN statements (just as an example)
SELECT all_prods.product, all_prods.branch,
  all_prods.name, all_prods.tot_deposits
FROM
 (SELECT
   (SELECT p.name FROM product p
    WHERE p.product_cd = a.product_cd
      AND p.product_type_cd = 'ACCOUNT') product, /* generates 3 nulls */
   (SELECT b.name FROM branch b
    WHERE b.branch_id = a.open_branch_id) branch,
   (SELECT CONCAT(e.fname, ' ', e.lname) FROM employee e 
    WHERE e.emp_id = a.open_emp_id) name,
	SUM(a.avail_balance) tot_deposits
  FROM account a
  GROUP BY a.product_cd, a.open_branch_id, a.open_emp_id
 ) all_prods
WHERE all_prods.product IS NOT NULL /* filters null product names */
ORDER BY all_prods.product, all_prods.branch;

-- Ex. scalar subqueries in the ORDER BY statement: sort by boss lname then emp
SELECT emp.emp_id, CONCAT(emp.fname, ' ', emp.lname) emp_name,
 (SELECT CONCAT(boss.fname, ' ', boss.lname)
  FROM employee boss
  WHERE boss.emp_id = emp.superior_emp_id) boss_name
FROM employee emp
WHERE emp.superior_emp_id IS NOT NULL
ORDER BY (SELECT boss.lname FROM employee boss
  WHERE boss.emp_id = emp.superior_emp_id), emp.lname;

-- Ex. use noncorrelated subqueries to  generate values for an insert statement
--  Here, we automatically retrieve foreign keys for an INSERT statement
-- Caution: INSERT still succeeds even if one of the subqueries returns null!
INSERT INTO account
 (account_id, product_cd, cust_id, open_date, last_activity_date,
  status, open_branch_id, open_emp_id, avail_balance, pending_balance)
VALUES (NULL,
 (SELECT product_cd FROM product WHERE name = 'savings account'),
 (SELECT cust_id FROM customer WHERE fed_id = '555-55-5555'),
  '2008-09-25', '2008-09-25', 'ACTIVE',
 (SELECT branch_id FROM branch WHERE name = 'Quincy Branch'),
 (SELECT emp_id FROM employee WHERE lname = 'Portman' AND fname = 'Frank'),
  0, 0);

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 9-1
--  Construct a query against the account table that uses a filter condition
--  with a noncorrelated subquery against the product table to find all loan
--  accounts (product.product_type_cd = 'LOAN'). Retrieve the account ID,
--  product code, customer ID, and available balance.
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE product_cd IN (SELECT product_cd
     FROM product
	 WHERE product_type_cd = 'LOAN');
	 
-- Exercise 9-2
--  Rework the query from Exercise 9-1 using a correlated subquery against
--  the product table to achieve the same results.
SELECT a.account_id, a.product_cd, a.cust_id, a.avail_balance
FROM account a
WHERE EXISTS(SELECT 1
  FROM product p
  WHERE a.product_cd = p.product_cd
    AND p.product_type_cd = 'LOAN');
	
-- Exercise 9-3
--  Join the following query to the employee table to show the experience level
--  of each employee:
--   SELECT 'trainee' name, '2004-01-01' start_dt, '2005-12-31' end_dt
--   UNION ALL
--   SELECT 'worker' name, '2002-01-01' start_dt, '2003-12-31' end_dt
--   UNION ALL
--   SELECT 'mentor' name, '2000-01-01' start_dt, '2001-12-31' end_dt
--  Give the subquery the alias levels, and include the employee ID,
--  first name, last name, and experience level (levels.name). (Hint: build a
--  join condition using an inequality condition to determine into which level
--  the employee.start_date column falls.)
SELECT e.emp_id, CONCAT(e.fname, ' ', e.lname) emp_name,
  levels.name experience, e.start_date
FROM 
 (SELECT emp_id, fname, lname, 
    start_date
  FROM employee) e
  INNER JOIN
 (SELECT 'trainee' name, '2004-01-01' start_dt, '2005-12-31' end_dt
  UNION ALL
  SELECT 'worker' name, '2002-01-01' start_dt, '2003-12-31' end_dt
  UNION ALL
  SELECT 'mentor' name, '2000-01-01' start_dt, 
    '2001-12-31' end_dt) levels
  ON e.start_date 
    BETWEEN levels.start_dt AND levels.end_dt;
	
-- Book answer: you can just join the full tables
SELECT e.emp_id, e.fname, e.lname, levels.name
FROM employee e INNER JOIN
 (SELECT 'trainee' name, '2004-01-01' start_dt, '2005-12-31' end_dt
  UNION ALL
  SELECT 'worker' name, '2002-01-01' start_dt, '2003-12-31' end_dt
  UNION ALL
  SELECT 'mentor' name, '2000-01-01' start_dt, '2001-12-31' end_dt) levels
  ON e.start_date BETWEEN levels.start_dt AND levels.end_dt;
	
-- Exercise 9-4
--  Construct a query against the employee table that retrieves the
--  employee ID, first name, and last name, along with the names of the
--  department and branch to which the employee is assigned. Do not join
--  any tables.
SELECT e.emp_id, e.fname, e.lname,
 (SELECT d.name
  FROM department d
  WHERE e.dept_id = d.dept_id) department,
 (SELECT b.name
  FROM branch b
  WHERE e.assigned_branch_id = b.branch_id) branch
FROM employee e;