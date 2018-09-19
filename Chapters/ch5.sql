/* ************* LEARNING SQL CHAPTER 5  *************** */
/* ************  QUERYING MULTIPLE TABLES            *** */
/* ***************************************************** */

/* ******** What is a join? ***************** */
-- Cartesian product (Cross Join)
--  Using the JOIN keyword produces every permutation of the JOINed tables
SELECT e.fname, e.lname, d.name
FROM employee e JOIN department d;

-- Inner Join
--  Join two tables on a related column, i.e. ID
--  Ex: Find all employee names and associated departments
--  Note: When a row cannot be properly JOINed, it is excluded from the result
SELECT e.fname, e.lname, d.name
FROM employee e JOIN department d
  ON e.dept_id = d.dept_id;
  
-- When JOIN is used without a prefix, it is by default an INNER JOIN
SELECT e.fname, e.lname, d.name
FROM employee e INNER JOIN department d
  ON e.dept_id = d.dept_id;
  
-- The USING subclause is useful when the joining column(s) are identical
--  In general, just use ON to avoid confusion
SELECT e.fname, e.lname, d.name
FROM employee e INNER JOIN department d
  USING (dept_id);
  
-- ANSI Join Syntax.
--  The following is the older join syntax.
SELECT e.fname, e.lname, d.name
FROM employee e, department d
WHERE e.dept_id = d.dept_id;


-- SQL92 syntax is useful to identify complex queries with both join and
--  filter conditions. Here is without SQL92 syntax. Notice that it is hard
--  to determine which is a JOIN condition and what is a filter condition.
SELECT a.account_id, a.cust_id, a.open_date, a.product_cd
FROM account a, branch b, employee e
WHERE a.open_emp_id = e.emp_id
  AND e.start_date < '2007-01-01'
  AND e.assigned_branch_id = b.branch_id
  AND (e.title = 'Teller' OR e.title = 'Head Teller')
  AND b.name = 'Woburn Branch';

-- The equivalent SQL92 syntax is easier to parse.
--   * JOIN conditions are contained in the FROM keyword
--   * filtering conditions are contained in the WHERE keyword
SELECT a.account_id, a.cust_id, a.open_date, a.product_cd
FROM account a INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
  INNER JOIN branch b
  ON e.assigned_branch_id = b.branch_id
WHERE e.start_date < '2007-01-01'
  AND (e.title = 'Teller' OR e.title = 'Head Teller')
  AND b.name = 'Woburn Branch';

/* ******** Joining Three or More Tables **** */
-- Two table join
--  Get the customer and federal IDs of business customers
SELECT a.account_id, c.fed_id
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id
WHERE c.cust_type_cd = 'B';

-- Three table join
--  Same as two table join, along with employee name that opened the account
SELECT a.account_id, c.fed_id, e.fname, e.lname
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id
  INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
WHERE c.cust_type_cd = 'B';

-- Order of tables does not change the result of the INNER JOIN
SELECT a.account_id, c.fed_id, e.fname, e.lname
FROM customer c INNER JOIN account a
  ON a.cust_id = c.cust_id
  INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
WHERE c.cust_type_cd = 'B';

SELECT a.account_id, c.fed_id, e.fname, e.lname
FROM employee e INNER JOIN account a
  ON e.emp_id = a.open_emp_id
  INNER JOIN customer c
  ON a.cust_id = c.cust_id
WHERE c.cust_type_cd = 'B';

-- SQL is nonprocedural, and thus the optimizer picks the JOIN order.
--  In MySQL, you can force the JOIN order by specifying STRAIGHT_JOIN
SELECT STRAIGHT_JOIN a.account_id, c.fed_id, e.fname, e.lname
FROM customer c INNER JOIN account a
  ON a.cust_id = c.cust_id
  INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
WHERE c.cust_type_cd = 'B';

-- Using Subqueries As Tables
--  INNER JOIN using subqueries to find all accounts opened by experienced
--  tellers currently assigned to the Woburn branch
SELECT a.account_id, a.cust_id, a.open_date, a.product_cd
FROM account a INNER JOIN
  (SELECT emp_id, assigned_branch_id
    FROM employee
	WHERE start_date < '2007-01-01'
	  AND (title = 'Teller' OR title = 'Head Teller')) e
  ON a.open_emp_id = e.emp_id
  INNER JOIN
    (SELECT branch_id
	  FROM branch
	  WHERE name = 'Woburn Branch') b
	ON e.assigned_branch_id = b.branch_id;

-- Using the same table twice
--  To use the same table twice for an INNER JOIN, you can give each instance
--  of that table a different alias to perform the operation.
SELECT a.account_id, e.emp_id,
  b_a.name open_branch, b_e.name emp_branch
FROM account a INNER JOIN branch b_a
  ON a.open_branch_id = b_a.branch_id
  INNER JOIN employee e
  ON a.open_emp_id = e.emp_id
  INNER JOIN branch b_e
  ON e.assigned_branch_id = b_e.branch_id
WHERE a.product_cd = 'CHK';

/* ************* Self-Joins ***************** */
-- Joining a table to itself may be useful, for example, when a table includes
--  a self-referencing foreign key.
-- Ex: List every employee along with name of manager
SELECT e.fname, e.lname,
  e_mgr.fname mgr_fname, e_mgr.lname mgr_lname
FROM employee e INNER JOIN employee e_mgr
  ON e.superior_emp_id = e_mgr.emp_id;
  
/* *** Equi-Joins Versus Non-Equi-Joins ***** */
-- All the above queries are equi-joins, meaning tables must match to succeed
--  Non-equi-joins use ranges of values to join instead
--  In this example, employee and product have no foreign key relationship.
--  (empty, just an example)
SELECT e.emp_id, e.fname, e.lname, e.start_date
FROM employee e INNER JOIN product p
  ON e.start_date >= p.date_offered
  AND e.start_date <= p.date_retired
WHERE p.name = 'no-fee checking';

-- Self-non-equi-join is also possible.
--  Ex. Chess competition: all tellers matched to all except themselves.
SELECT e1.fname, e1.lname, 'VS' vs, e2.fname, e2.lname
FROM employee e1 INNER JOIN employee e2
  ON e1.emp_id != e2.emp_id
WHERE e1.title = 'Teller' AND e2.title = 'Teller';

-- The above example double counts matches. A non-equi-join prevents this.
--  You should get (9 choose 2) = 36 match-ups.
SELECT e1.fname, e1.lname, 'VS' vs, e2.fname, e2.lname
FROM employee e1 INNER JOIN employee e2
  ON e1.emp_id < e2.emp_id /* non-equi-join */
WHERE e1.title = 'Teller' AND e2.title = 'Teller';

/* * Join Conditions Versus Filter Conditions */
-- Simple INNER JOIN example in right order.
SELECT a.account_id, a.product_cd, c.fed_id
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id
WHERE c.cust_type_cd = 'B';

-- What if you put "AND" instead of "WHERE"? Spoiler: still works...
SELECT a.account_id, a.product_cd, c.fed_id
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id
    AND c.cust_type_cd = 'B';
	
-- What if you place the conditions in WHERE, but FROM is still ANSI? (works)
SELECT a.account_id, a.product_cd, c.fed_id
FROM account a INNER JOIN customer c
WHERE a.cust_id = c.cust_id
  AND c.cust_type_cd = 'B';
  
-- Bottom line: be consistent so that your code is maintainble.

/* ******** Test Your Knowledge ************* */
-- Exercise 5-1
--  Fill in the blanks (denoted by <#>) for the following query to obtain
--  the results that follow.
SELECT e.emp_id, e.fname, e.lname, b.name
FROM employee e INNER JOIN branch b
  ON e.assigned_branch_id = b.branch_id;
  
-- Exercise 5-2
--  Write a query that returns the account ID for each nonbusiness customer
--  (customer.cust_type_cd = 'I') with the customer's federal ID
--  (customer.fed_id) and the name of the product on which the account is
--  based (product.name)
SELECT a.account_id, c.fed_id, p.name
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id
  INNER JOIN product p
  ON a.product_cd = p.product_cd
WHERE c.cust_type_cd = 'I';

-- Exercise 5-3
--  Construct a query that finds all employees whose supervisor is assigned
--   to a different department. Retrieve the employees' ID, first name, and
--   last name.
SELECT e.emp_id, e.fname, e.lname,
  e_mgr.fname mgr_fname, e_mgr.lname mgr_lname,
  d_e.name e_dept, d_e_mgr.name e_mgr_dept
FROM employee e INNER JOIN employee e_mgr
  ON e.superior_emp_id = e_mgr.emp_id
  INNER JOIN department d_e
  ON e.dept_id = d_e.dept_id
  INNER JOIN department d_e_mgr
  ON e_mgr.dept_id = d_e_mgr.dept_id
WHERE d_e.name != d_e_mgr.name;

-- Book solution: no need to join with department if you don't care
--  what the actual departments were. 
SELECT e.emp_id, e.fname, e.lname
FROM employee e INNER JOIN employee mgr
  ON e.superior_emp_id= mgr.emp_id
WHERE e.dept_id != mgr.dept_id;