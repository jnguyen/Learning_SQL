/* ************* LEARNING SQL CHAPTER 4  *************** */
/* ************      FILTERING                       *** */
/* ***************************************************** */

/* ******** Condition Types ***************** */
-- Equality conditions: use = (do not use ==)
--  Here, we find the names of Customer Accounts offered
SELECT pt.name product_type, p.name product
FROM product p INNER JOIN product_type pt
  ON p.product_type_cd = pt.product_type_cd /* equate columns */
WHERE pt.name = 'Customer Accounts';        /* find Customer Accounts */

-- Inequality conditions: use <> or !=
--  Here, we find the names of all accounts that are not Customer Accounts
SELECT pt.name product_type, p.name product
FROM product p INNER JOIN product_type pt
  ON p.product_type_cd = pt.product_type_cd
WHERE pt.name <> 'Customer Accounts';

-- You can use equality conditions to modify data
--  Note: this will not actually delete anything; it's just an example
DELETE FROM account
WHERE status = 'CLOSED' AND YEAR(close_date) = 2002;

-- Range Conditions: <, >, >=, <=
--  Find employees who started before 2007
SELECT emp_id, fname, lname, start_date
FROM employee
WHERE start_date < '2007-01-01';

-- You can also specify an interval, i.e. between 2005 and 2007
SELECT emp_id, fname, lname, start_date
FROM employee
WHERE start_date < '2007-01-01'
  AND start_date >= '2005-01-01';
  
-- The BETWEEN operator achieves the same result as a range joined with AND
--  Note: the dates are inclusive on both provided dates
SELECT emp_id, fname, lname, start_date
FROM employee
WHERE start_date BETWEEN '2005-01-01' AND '2007-01-01';

-- If you specify the upper range first with BETWEEN, you get an empty set
SELECT emp_id, fname, lname, start_date
FROM employee
WHERE start_date BETWEEN '2007-01-01' AND '2005-01-01';

-- By misspecifying the range, you are essentially doing this:
SELECT emp_id, fname, lname, start_date
FROM employee
WHERE start_date >= '2007-01-01'
  AND start_date <= '2005-01-01';
  
-- BETWEEN can be used with numbers, too.
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE avail_balance BETWEEN 3000 AND 5000;

-- String ranges: you can search a range of strings
--  Be sure to know the relevant collation of the column's character set!
SELECT cust_id, fed_id
FROM customer
WHERE cust_type_cd = 'I'
  AND fed_id BETWEEN '500-00-0000' AND '999-99-9999';
  
-- Membership Conditions: restrict to a finite set of values
--  i.e. product codes 'CHK', 'SAV', 'CD', and 'MM' only:
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE product_cd = 'CHK' OR product_cd = 'SAV'
  OR product_cd = 'CD' OR product_cd = 'MM';
 
-- The above is ugly to write. Use IN to define a finite set of values:
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE product_cd IN ('CHK','SAV','CD','MM');

-- Using subqueries: you can generate a set on the fly instead of using IN
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE product_cd IN (SELECT product_cd FROM product
  WHERE product_type_cd = 'ACCOUNT');
  
-- You can also negate an IN statement by writing NOT IN
SELECT account_id, product_cd, cust_id, avail_balance
FROM account
WHERE product_cd NOT IN ('CHK','SAV','CD','MM');

-- Functions can be used in WHERE statements
--  For example, we can find all employees with last name starting with 'T'
SELECT emp_id, fname, lname
FROM employee
WHERE LEFT(lname, 1) = 'T';

-- Wildcards give more flexibility when searching strings
--  _: an underscore will match exactly one character
--  %: a percent sign will match any number of characters (including 0)

-- Get all employees with last name having 'a' as 2nd char, and e somewhere
--  To invoke wildcards, use the LIKE operator:
SELECT lname
FROM employee
WHERE lname LIKE '_a%e%';

-- Find all federal IDs that match the format of an SSN
SELECT cust_id, fed_id
FROM customer
WHERE fed_id LIKE '___-__-____';

-- Find all employees with last name starting with 'F' or 'G'
--  Note: each time we invoke a wildcard search, we need to specify LIKE
SELECT emp_id, fname, lname
FROM employee
WHERE lname LIKE 'F%' OR lname LIKE 'G%';

-- SQL also supports regex. Check with your DB for details.
SELECT emp_id, fname, lname
FROM employee
WHERE lname REGEXP '^[FG]'; /* Same query as above */

/* ******** Null: That Four-Letter Word ***** */
-- Important: Expressions can be null, but never EQUAL to null!
--  Two nulls are never equal to each other.

-- Use IS NULL to determine whether an expression is null.
SELECT emp_id, fname, lname, superior_emp_id
FROM employee
WHERE superior_emp_id IS NULL;

-- If you tried using '=' to find null values, you would get nothing.
--  Notice that there is no error. This is a common pitfall.
--  Lesson: Do not use equality conditions to find null values!
SELECT emp_id, fname, lname, superior_emp_id
FROM employee
WHERE superior_emp_id= NULL;

-- You can also find values that are NOT NULL
SELECT emp_id, fname, lname, superior_emp_id
FROM employee
WHERE superior_emp_id IS NOT NULL;

-- Good practice: Try to account for possible null values
--  E.g. if you identified employees not managed by Helen Fleming (id=6)
--  using '!=', you would totally miss Michael Smith, who has a null value.
SELECT emp_id, fname, lname, superior_emp_id
FROM employee
WHERE superior_emp_id != 6;

-- Not managed by Helen Fleming, including the (null) boss:
SELECT emp_id, fname, lname, superior_emp_id
FROM employee
WHERE superior_emp_id != 6 OR superior_emp_id IS NULL;

/* ******** Test Your Knowledge ************* */
-- Exercise 4-1
--  Which of the transaction IDs would be returned by the following filter
--  conditions?
--    txn_date < '2005-02-26' AND (txn_type_cd = 'DBT' OR amount > 100)
--  A: rows 1,2,3,5,6,7

-- Exercise 4-2
--  Which of the transaction IDs would be returned by the following filter
--  conditions?
--    account_id IN (101,103) AND NOT (txn_type_cd = 'DBT' or amount > 100)
--  A: 1,2,3,5,6,7,8 excluded. So only row 4 and 9.

-- Exercise 4-3
-- Construct a query that retrives all accounts opened in 2002.
SELECT account_id, open_date
FROM account
WHERE open_date BETWEEN '2002-01-01' AND '2002-12-31';

-- Exercise 4-4
-- Construct a query that finds all nonbusiness customers whose last name 
--  contains an 'a' in the second position and an 'e' anywhere after the 'a'.
SELECT c.cust_id, c.cust_type_cd, i.fname, i.lname
FROM customer c INNER JOIN individual i
  ON c.cust_id = i.cust_id
WHERE c.cust_type_cd = 'I'
  AND i.lname LIKE '_a%e%';

-- REGEXP version
SELECT c.cust_id, c.cust_type_cd, i.fname, i.lname
FROM customer c INNER JOIN individual i
  ON c.cust_id = i.cust_id
WHERE c.cust_type_cd = 'I'
  AND i.lname REGEXP '^.a.*e.*';
  
-- Book answer:
SELECT cust_id, lname, fname
FROM individual
WHERE lname LIKE '_a%e%';