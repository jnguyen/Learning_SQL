/* ************* LEARNING SQL CHAPTER 10 *************** */
/* ************       JOINS REVISITED                *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Outer Joins                             ****/
/* ******************************************** ****/
-- Take a look at account IDs and customer IDs side by side (29 acc, 13 cust)
SELECT account_id, cust_id
FROM account;
-- Take a look at just customer IDs
SELECT cust_id.
FROM customer;
-- Since all 13 customer IDs are accounted for, an INNER JOIN matches all rows
SELECT a.account_id, c.cust_id
FROM account a INNER JOIN customer c
  ON a.cust_id = c.cust_id;
-- However, partial lists of customer IDs will result in partial matches
--  Ex. Joining account and business tables by account_id only returns 5 rows
SELECT a.account_id, b.cust_id, b.name
FROM account a INNER JOIN business b
  ON a.cust_id = b.cust_id;
-- Looking at the business table, there are only 4 business customers total
SELECT cust_id, name
FROM business;

-- Ex. Left outer join: include all rows of first table and matching of 2nd
-- Outer join: only include account name if account is business
SELECT a.account_id, a.cust_id, b.name
FROM account a LEFT OUTER JOIN business b
  ON a.cust_id = b.cust_id;

-- Ex. Left outer join account on individual; only individual accs have names
SELECT a.account_id, a.cust_id, i.fname, i.lname
FROM account a LEFT OUTER JOIN individual i
  ON a.cust_id = i.cust_id;

-- Ex. Include names of business customers only; 13 matches (with nulls)
SELECT c.cust_id, b.name
FROM customer c LEFT OUTER JOIN business b
  ON c.cust_id = b.cust_id;
  
-- Right outer join: rows determined by 2nd, matches by 1st
--  Ex. Include customer IDs of business customers only; 4 matches (all full)
SELECT c.cust_id, b.name
FROM customer c RIGHT OUTER JOIN business b
  ON c.cust_id = b.cust_id;

-- Three-Way Outer Joins: outer-join one table with two other tables
--  Ex. Generate list of all accounts showing either the customer's first
--   and last names for individuals, or the business name
SELECT a.account_id, a.product_cd,
  CONCAT(i.fname, ' ', i.lname) person_name,
  b.name business_name
FROM account a LEFT OUTER JOIN individual i
  ON a.cust_id = i.cust_id
  LEFT OUTER JOIN business b
  ON a.cust_id = b.cust_id;
  
-- Subqueries can be used to restrict the number of outer-joins used above
--  Notice here that each query and subquery only uses one outer join 
SELECT account_ind.account_id, account_ind.product_cd,
  account_ind.person_name,
  b.name business_name
FROM
 (SELECT a.account_id, a.product_cd, a.cust_id, /* Subquery */
   CONCAT(i.fname, ' ', i.lname) person_name
  FROM account a LEFT OUTER JOIN individual i
    ON a.cust_id = i.cust_id) account_ind
  LEFT OUTER JOIN business b                    /* join subquery to business */
  ON account_ind.cust_id = b.cust_id;

-- Self Outer Joins
--  Reminder: self inner join to get names of employees and their managers
--  Note: Employees without supervisors are left out (aka the boss)
SELECT e.fname, e.lname,
  e_mgr.fname mgr_fname, e_mgr.lname mgr_lname
FROM employee e INNER JOIN employee e_mgr
  ON e.superior_emp_id = e_mgr.emp_id;
  
-- Ex. Left outer join to generate all employees and supervisors (correct)
SELECT e.fname, e.lname,
  e_mgr.fname mgr_fname, e_mgr.lname mgr_lname
FROM employee e LEFT OUTER JOIN employee e_mgr
  ON e.superior_emp_id = e_mgr.emp_id;
  
-- Ex. Right outer join to generate all supervisors and employees (oops!)
SELECT e.fname, e.lname,
  e_mgr.fname mgr_fname, e_mgr.lname mgr_lname
FROM employee e RIGHT OUTER JOIN employee e_mgr
  ON e.superior_emp_id = e_mgr.emp_id;

/* ******************************************** ****/
/* ***  Cross Joins                             ****/
/* ******************************************** ****/
-- Cross joins generate the Cartesian product, or all possible combinations
SELECT pt.name, p.product_cd, p.name
FROM product p CROSS JOIN product_type pt;

-- From Chapter 9: fabricated balance groups
SELECT 'Small Fry' name, 0 low_limit, 4999.99 high_limit
UNION ALL
SELECT 'Average Joes' name, 5000 low_limit, 9999.99 high_limit
UNION ALL
SELECT 'Heavy Hitters' name, 10000 low_limit, 9999999.99 high_limit;

-- The above example doesn't work for large tables.
--  Ex. Generate all numbers between 0 and 300 using a CROSS JOIN
SELECT ones.num + tens.num + hundreds.num
FROM
 (SELECT 0 num UNION ALL
  SELECT 1 num UNION ALL
  SELECT 2 num UNION ALL
  SELECT 3 num UNION ALL
  SELECT 4 num UNION ALL
  SELECT 5 num UNION ALL
  SELECT 6 num UNION ALL
  SELECT 7 num UNION ALL
  SELECT 8 num UNION ALL
  SELECT 9 num) ones
  CROSS JOIN
 (SELECT 0 num UNION ALL
  SELECT 10 num UNION ALL
  SELECT 20 num UNION ALL
  SELECT 30 num UNION ALL
  SELECT 40 num UNION ALL
  SELECT 50 num UNION ALL
  SELECT 60 num UNION ALL
  SELECT 70 num UNION ALL
  SELECT 80 num UNION ALL
  SELECT 90 num) tens
  CROSS JOIN
 (SELECT 0 num UNION ALL
  SELECT 100 num UNION ALL
  SELECT 200 num UNION ALL
  SELECT 300 num) hundreds;

-- Ex. Edit the above statement to add days to a date filtering excess dates
--  so that we end up with all days in 2008. Leap day automatically included!
SELECT DATE_ADD('2008-01-01',
  INTERVAL (ones.num + tens.num + hundreds.num) DAY) dt
FROM
 (SELECT 0 num UNION ALL
  SELECT 1 num UNION ALL
  SELECT 2 num UNION ALL
  SELECT 3 num UNION ALL
  SELECT 4 num UNION ALL
  SELECT 5 num UNION ALL
  SELECT 6 num UNION ALL
  SELECT 7 num UNION ALL
  SELECT 8 num UNION ALL
  SELECT 9 num) ones
  CROSS JOIN
 (SELECT 0 num UNION ALL
  SELECT 10 num UNION ALL
  SELECT 20 num UNION ALL
  SELECT 30 num UNION ALL
  SELECT 40 num UNION ALL
  SELECT 50 num UNION ALL
  SELECT 60 num UNION ALL
  SELECT 70 num UNION ALL
  SELECT 80 num UNION ALL
  SELECT 90 num) tens
  CROSS JOIN
 (SELECT 0 num UNION ALL
  SELECT 100 num UNION ALL
  SELECT 200 num UNION ALL
  SELECT 300 num) hundreds
WHERE DATE_ADD('2008-01-01',
  INTERVAL (ones.num + tens.num + hundreds.num) DAY) < '2009-01-01'
ORDER BY 1;

-- Ex. Edit above query to show banking transactions on each day
SELECT days.dt, COUNT(t.txn_id)
FROM transaction t RIGHT OUTER JOIN
 (SELECT DATE_ADD('2008-01-01',
  INTERVAL (ones.num + tens.num + hundreds.num) DAY) dt
 FROM
  (SELECT 0 num UNION ALL
   SELECT 1 num UNION ALL
   SELECT 2 num UNION ALL
   SELECT 3 num UNION ALL
   SELECT 4 num UNION ALL
   SELECT 5 num UNION ALL
   SELECT 6 num UNION ALL
   SELECT 7 num UNION ALL
   SELECT 8 num UNION ALL
   SELECT 9 num) ones
   CROSS JOIN
  (SELECT 0 num UNION ALL
   SELECT 10 num UNION ALL
   SELECT 20 num UNION ALL
   SELECT 30 num UNION ALL
   SELECT 40 num UNION ALL
   SELECT 50 num UNION ALL
   SELECT 60 num UNION ALL
   SELECT 70 num UNION ALL
   SELECT 80 num UNION ALL
   SELECT 90 num) tens
   CROSS JOIN
  (SELECT 0 num UNION ALL
   SELECT 100 num UNION ALL
   SELECT 200 num UNION ALL
   SELECT 300 num) hundreds
 WHERE DATE_ADD('2008-01-01',
   INTERVAL (ones.num + tens.num + hundreds.num) DAY) < 
     '2009-01-01') days
 ON days.dt = t.txn_date
GROUP BY days.dt
ORDER BY days.dt;

/* ******************************************** ****/
/* ***  Natural Joins                           ****/
/* ******************************************** ****/
-- A natural join is when you let the server determine the join conditions
--  Natural joins rely on identical column names across multiple talbes to
--  infer the proper join conditions.
-- Ex. Natural join on cust_id account and customer tables. Primary key cust_id
--  is inferred as the JOIN condition a.cust_id = c.cust_id
SELECT a.account_id, a.cust_id, c.cust_type_cd, c.fed_id
FROM account a NATURAL JOIN customer c;

-- Ex. Natural join where the columns don't have the same names
--  Joining account to branch does a Cartesian product!
SELECT a.account_id, a.cust_id, a.open_branch_id, b.name
FROM account a NATURAL JOIN branch b;

-- Moral of the story: don't be lazy. Specify the exact join you want.

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 10-1
--  Write a query that returns all product names along with the accounts based
--  on that product (use the product_cd column in the account table to link
--  to the product table). Include all products, even if no accounts have been
--  opened for that product.
SELECT p.product_cd, a.account_id, a.cust_id, a.avail_balance
FROM product p LEFT OUTER JOIN account a
  ON p.product_cd = a.product_cd;

-- Exercise 10-2
--  Reformulate your query from Exercser 10-1 to use the other outer join type
--  (e.g., if you used a left outer join in Exercise 10-1, use a right outer
--  join this time) such that the results are identical to Exercise 10-1.
SELECT p.product_cd, a.account_id, a.cust_id, a.avail_balance
FROM account a RIGHT OUTER JOIN product p
  ON p.product_cd = a.product_cd;
  
-- Exercise 10-3
--  Outer-join the account table to both the individual and business tables 
--  (via the account.cust_id column) such that the result set contains one row
--  per account. Columns to include are account.account_id, account.product_cd,
--  individual.fname, individual.lname, and business.name
SELECT a.account_id, a.product_cd,
  i.fname, i.lname,
  b.name
FROM account a LEFT OUTER JOIN individual i
  ON a.cust_id = i.cust_id
  LEFT OUTER JOIN business b
  ON a.cust_id = b.cust_id;
  
-- Exercise 10-4 (Extra Credit)
--  Devise a query that will generate the set {1,2,3,...,99,100}. (Hint: use a
--  cross join with at least two from clause subqueries)
SELECT (1 + ones.num + tens.num) num
FROM
 (SELECT 0 num UNION ALL
  SELECT 1 num UNION ALL
  SELECT 2 num UNION ALL
  SELECT 3 num UNION ALL
  SELECT 4 num UNION ALL
  SELECT 5 num UNION ALL
  SELECT 6 num UNION ALL
  SELECT 7 num UNION ALL
  SELECT 8 num UNION ALL
  SELECT 9 num) ones
  CROSS JOIN
 (SELECT 0 num UNION ALL
  SELECT 10 num UNION ALL
  SELECT 20 num UNION ALL
  SELECT 30 num UNION ALL
  SELECT 40 num UNION ALL
  SELECT 50 num UNION ALL
  SELECT 60 num UNION ALL
  SELECT 70 num UNION ALL
  SELECT 80 num UNION ALL
  SELECT 90 num) tens
ORDER BY num;