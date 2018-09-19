/* ************* LEARNING SQL CHAPTER 3  *************** */
/* ************   WORKING WITH SETS                  *** */
/* ***************************************************** */

/* ****** Set Theory In Practice ************ */
-- Union of Tables
DESC product;
DESC customer;
-- The above tables don't really make sense to combine
--  So, there are two rules for performing set operations on tables.
--    1. Both tables have the same number of columns
--    2. Each corresponding column has the same data type

-- To use set operations, place a set operator between select statements
SELECT 1 num, 'abc' str
UNION
SELECT 9 num, 'xyz' str;

/* ****** Set Operators ********************* */
-- UNION (unique) and UNION ALL (duplicates allowed)
SELECT 'IND' type_cd, cust_id, lname name
FROM individual
UNION ALL /* duplicates are allowed, all rows preserved */
SELECT 'BUS' type_cd, cust_id, name
FROM business;

-- Same query but with a duplicate UNION ALL
SELECT 'IND' type_cd, cust_id, lname name
FROM individual
UNION ALL 
SELECT 'BUS' type_cd, cust_id, name
FROM business
UNION ALL /* duplicates preserved! */
SELECT 'BUS' type_cd, cust_id, name
FROM business;

-- Compound queries may return duplicate data with a UNION ALL statement
--  Here, we get all tellers assigned to Woburn and distinct tellers who
--  opened accounts at Woburn. This is {10, 11, 12} UNION ALL {10}, which
--  ends up duplicating emp_id 10.
SELECT emp_id
FROM employee
WHERE assigned_branch_id = 2
  AND (title = 'Teller' OR title = 'Head Teller') /* 10, 11, 12 */
UNION ALL
SELECT DISTINCT open_emp_id
FROM account
WHERE open_branch_id = 2; /* 10 */

-- To avoid duplicates, use the UNION statement.
SELECT emp_id
FROM employee
WHERE assigned_branch_id = 2
  AND (title = 'Teller' OR title = 'Head Teller') /* 10, 11, 12 */
UNION
SELECT DISTINCT open_emp_id
FROM account
WHERE open_branch_id = 2; /* 10 */

-- The INTERSECT operator
--  ANSI SQL includes an INTERSECT operator. 
--  However, MySQL does not implement it...
--  Like UNION, there is also an INTERSECT ALL, available in IBM DB2 server
SELECT emp_id, fname, lname
FROM employee
INTERSECT
SELECT cust_id, fname, lname
FROM individual;
-- Empty set (0.04 sec)

-- Hypothetical INTERSECT operation from Woburn example above
SELECT emp_id
FROM employee
WHERE assigned_branch_id = 2
  AND (title = 'Teller' OR title = 'Head Teller') /* 10, 11, 12 */
UNION
SELECT DISTINCT open_emp_id
FROM account
WHERE open_branch_id = 2; /* 10 */
-- --> emp_id, 10.

-- The EXCEPT operator
--  MySQL also does not include the ANSI EXCEPT operator
--  IBM DB2 has an EXCEPT ALL that allows duplicates
SELECT emp_id
FROM employee
WHERE assigned_branch_id = 2 /* 10, 11, 12 */
  AND (title = 'Teller' OR title = 'Head Teller')
EXCEPT
SELECT DISTINCT open_emp_id
FROM account
WHERE open_branch_id = 2; /* 10 */
-- -> {11, 12}

/* ****** Set Operation Rules *************** */
-- ORDER BY requires column names from the first query in a complex query
SELECT emp_id, assigned_branch_id /* Must choose these columns for ORDER BY */
FROM employee
WHERE title = 'Teller'
UNION
SELECT open_emp_id, open_branch_id
FROM account
WHERE product_cd = 'SAV'
ORDER BY emp_id;

-- Trying to ORDER BY a column not in the first query spits out an error
SELECT emp_id, assigned_branch_id 
FROM employee
WHERE title = 'Teller'
UNION
SELECT open_emp_id, open_branch_id
FROM account
WHERE product_cd = 'SAV'
ORDER BY open_emp_id;

-- Giving the ORDER BY column the same alias resolves this issue
SELECT emp_id id, assigned_branch_id 
FROM employee
WHERE title = 'Teller'
UNION
SELECT open_emp_id id, open_branch_id
FROM account
WHERE product_cd = 'SAV'
ORDER BY id;

/* ****** Set Operation Precedence ********** */
-- The order of set operations matters. Here, UNION comes second.
SELECT cust_id
FROM account
WHERE product_cd IN ('SAV', 'MM')
UNION ALL
SELECT a.cust_id
FROM account a INNER JOIN branch b
  ON a.open_branch_id = b.branch_id
WHERE b.name = 'Woburn Branch'
UNION
SELECT cust_id
FROM account
WHERE avail_balance BETWEEN 500 AND 2500;

-- Here, UNION comes first, and UNION ALL second. Result includes duplicates!
SELECT cust_id
FROM account
WHERE product_cd IN ('SAV', 'MM')
UNION
SELECT a.cust_id
FROM account a INNER JOIN branch b
  ON a.open_branch_id = b.branch_id
WHERE b.name = 'Woburn Branch'
UNION ALL
SELECT cust_id
FROM account
WHERE avail_balance BETWEEN 500 AND 2500;

-- In general, compound queries are evaluated from top to bottom, but:
--   * ANSI SQL says INTERSECT has precedence
--   * Order of operations may be dictated using parentheses ()

-- Ex: (SAV/MM customers at Woburn Branch) INTERSECT
--     (customers with $500-$2500 except CD customers with less than $1,000)
-- Result: Savings/Money Market customers at Woburn Branch with $500-$2,500
--  in their accounts excluding all CD customers with less than $1,000. 
(SELECT cust_id
 FROM account
 WHERE product_cd IN ('SAV', 'MM')
 UNION ALL
 SELECT a.cust_id
 FROM account a INNER JOIN branch b
   ON a.open_branch_id = b.branch_id
 WHERE b.name = 'Woburn Branch')
INTERSECT
(SELECT cust_id
 FROM account
 WHERE avail_balance BETWEEN 500 AND 2500;
 EXCEPT 
 SELECT cust_id
 FROM account
 WHERE product_cd = 'CD'
   AND avail_balance < 1000);
 
/* ****** Test Your Knowledge *************** */
-- Exercise 6-1
--  If set A = {L M N O P} and B = {P Q R S T}, what sets are generated by
--  the following operations?
--  A union B: {L M N O P Q R S T}
--  A union all B: {L M N O P P Q R S T}
--  A intersect B: {P}
--  A except B: {L M N O}

-- Exercise 6-2
--  Write a compound query that finds the first and last names of all 
--  individual customers along with the first and last names of all employees.
SELECT fname, lname
FROM individual
UNION
SELECT fname, lname
FROM employee;

-- Exercise 6-3
--  Sort the results from Exercise 6-2 by the lname column
SELECT fname, lname
FROM individual
UNION ALL
SELECT fname, lname
FROM employee
ORDER BY lname;