/* ************* LEARNING SQL CHAPTER 3  *************** */
/* ************      QUERY PRIMER                    *** */
/* ***************************************************** */

-- A failed query returns an Empty set
SELECT emp_id, fname, lname
FROM employee
WHERE lname = 'Bkadfl';

-- A successful query will print an ASCII table of the results
-- Note that SQL does not guarantee results in any order
SELECT fname, lname
FROM employee;

/* ************ THE select CLAUSE *********** */
-- Commentary: select is often the last thing a DB server will evaluate
-- Select all rows and columns in department:
SELECT *
FROM department;

-- You can select specific columns:
SELECT dept_id, name
FROM department;

SELECT name
FROM department;

-- select can also return literals, expressions, and run built-in functions
SELECT emp_id,     /* column */
 'ACTIVE',         /* string literal */
 emp_id * 3.14159, /* expression */
 UPPER(lname)      /* function */
FROM employee;

-- if only function calls are needed, then FROM can be omitted
SELECT VERSION(),
 USER(),
 DATABASE();
 
-- you can assign custom labels to result columns
SELECT emp_id,     
 'ACTIVE' status, /* rename column to status */        
 emp_id * 3.14159 empid_x_pi, /* rename result column to empid_x_pi */
 UPPER(lname) last_name_upper /* rename result column to last_name_upper */     
FROM employee;

-- use the keyword AS to make column aliasing more clear
SELECT emp_id,     
 'ACTIVE' AS status,
 emp_id * 3.14159 AS empid_x_pi, 
 UPPER(lname) AS last_name_upper 
FROM employee;

-- select may return duplicate rows of data
SELECT cust_id
FROM account;

-- to return unique values, use the DISTINCT keyword
-- note: DISTINCT requires data to be sorted, which can be costly
SELECT DISTINCT cust_id
FROM account;

/* ************ the FROM clause ************* */
-- The FROM clause defines the tables used by a query, along with 
--  the means of linking the tables together. This definition emphasizes
--  the looser definition of tables and how data is stored in relational DBs.

-- You can select from a temporary table generated by another selection
--  The inner select is referred to as a 'subquery'
--  Here, we select 3 out of 5 tables in the subquery
SELECT e.emp_id, e.fname, e.lname
FROM (SELECT emp_id, fname, lname, start_date, title
      FROM employee) e;
	  
-- Generate a view, a table-like object stored in data dictionary
--  No data is actually associated with a view
CREATE VIEW employee_vw AS
SELECT emp_id, fname, lname,
  YEAR(start_date) start_year /* grab year only and name it start_year */
FROM employee;

-- Once the VIEW is created, you can issue queries against it
SELECT emp_id, start_year
FROM employee_vw;

-- For ANSI portability, include conditions to link tables when joining
--  multiple tables
SELECT employee.emp_id, employee.fname,
  employee.lname, department.name dept_name
FROM employee INNER JOIN department
  ON employee.dept_id = department.dept_id;
  
-- Instead of writing the full table name, we can use TABLE aliases
SELECT e.emp_id, e.fname, e.lname,
  d.name dept_name
FROM employee e INNER JOIN department d
  ON e.dept_id = d.dept_id;

-- Equivalent statement with AS keyword for clarity
SELECT e.emp_id, e.fname, e.lname,
  d.name AS dept_name
FROM employee AS e INNER JOIN department AS d
  ON e.dept_id = d.dept_id;

/* ************ the WHERE clause ************ */
-- Generally, we don't want every row in a table. We use WHERE to filter
--  rows that we do want based on common characteristics.

-- select only employees with the title 'Head Teller'
SELECT emp_id, fname, lname, start_date, title
FROM employee
WHERE title = 'Head Teller';

-- WHERE can include multiple logical conditions
SELECT emp_id, fname, lname, start_date, title
FROM employee
WHERE title = 'Head Teller'
  AND start_date > '2006-01-01';
  
-- If we used OR instead, we would get all employees past 2006
--  as well as the head tellers. Probably not useful!
SELECT emp_id, fname, lname, start_date, title
FROM employee
WHERE title = 'Head Teller'
  OR start_date > '2006-01-01';

-- Use parentheticals () to compound AND and OR statements
SELECT emp_id, fname, lname, start_date, title
FROM employee
WHERE (title = 'Head Teller' AND start_date > '2006-01-01')
  OR (title = 'Teller' AND start_date > '2007-01-01');
  
/* **** the GROUP BY and HAVING clauses ***** */
-- GROUP BY and HAVING can filter data into groups of interest
--  More on these statements in Chapter 8

-- Count number of employees in each department
SELECT d.name, count(e.emp_id) AS num_employees
FROM department AS d INNER JOIN employee AS e
  ON d.dept_id = e.dept_id
GROUP BY d.name
HAVING count(e.emp_id) > 2;

/* ********* the ORDER BY clause ************ */
-- Use the ORDER BY clause to return results in a desired order

-- Unordered results can be messy:
SELECT open_emp_id, product_cd
FROM account;

-- Use ORDER BY to organize account types by employee IDs:
SELECT open_emp_id, product_cd
FROM account
ORDER BY open_emp_id;

-- We can further ORDER BY product_cd alphabetically within open_emp_id
SELECT open_emp_id, product_cd
FROM account
ORDER BY open_emp_id, product_cd;

-- By default, ORDER BY is ascending. Use DESC for descending order
SELECT account_id, product_cd, open_date, avail_balance
FROM account
ORDER BY avail_balance DESC;

-- ORDER BY can also sort by expressions and functions
SELECT cust_id, cust_type_cd, city, state, fed_id
FROM customer
ORDER BY RIGHT(fed_id, 3); /* Get last 3 digits */

-- You can also ORDER BY relative position in the SELECT clause
--  Don't do this though, because it will be difficult to edit and maintain
SELECT emp_id, title, start_date, fname, lname
FROM employee
ORDER BY 2, 5;

/* ********* Test Your Knowledge ************ */
-- Exercise 3-1
--  Retrieve the employee ID, first name, and last name for all bank 
--  employees. Sort by last name and then by first name
SELECT emp_id, lname, fname
FROM employee
ORDER BY lname, fname;

-- Exercise 3-2
--  Retrieve the account ID, customer ID, and available balance for all
--  accounts whose status equals 'ACTIVE' and whose available balance is 
--  greater than $2,500.
SELECT account_id, cust_id, avail_balance
FROM account
WHERE status = 'ACTIVE'
  AND avail_balance > 2500;

-- Exercise 3-3
--  Write a query against the account table that returns the IDs of the 
--  employees who opened the accounts (use the account.open_emp_id column).
--  Include a single row for each distinct employee.
SELECT DISTINCT open_emp_id
FROM account;

-- Exercise 3-4
--  Fill in the blanks (denoted by <#>) for this mult-data-set query to 
--  achieve the results shown.
SELECT p.product_cd, a.cust_id, a.avail_balance
FROM product p INNER JOIN account a
  ON p.product_cd = a.product_cd
WHERE p.product_type_cd = 'ACCOUNT'
ORDER BY product_cd, cust_id;