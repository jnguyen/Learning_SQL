/* ************* LEARNING SQL CHAPTER 11 *************** */
/* ************     CONDITIONAL LOGIC                *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  What is Conditional Logic?              ****/
/* ******************************************** ****/
-- Take different paths based on situation encountered
--  Ex. Retrieve either fname/lname from individual or business name
--   using outer joins, and let the caller ignore NULL values
SELECT c.cust_id, c.fed_id, c.cust_type_cd,
  CONCAT(i.fname, ' ', i.lname) indiv_name,
  b.name business_name
FROM customer c LEFT OUTER JOIN individual i
  ON c.cust_id = i.cust_id
  LEFT OUTER JOIN business b
  ON c.cust_id = b.cust_id;
  
-- However, it would be cleaner to have one column of names. Let's use a CASE!
--  Ex. Use a case statement to return appropriate name based on table names
SELECT c.cust_id, c.fed_id,
  CASE
    WHEN c.cust_type_cd = 'I'
	  THEN CONCAT(i.fname, ' ', i.lname)
	WHEN c.cust_type_cd = 'B'
	  THEN b.name
	ELSE 'Unknown'
  END name
FROM customer c LEFT OUTER JOIN individual i
  ON c.cust_id = i.cust_id
  LEFT OUTER JOIN business b
  ON c.cust_id = b.cust_id;

/* ******************************************** ****/
/* ***  The Case Expression                     ****/
/* ******************************************** ****/
-- CASE expressions are part of SQL standard and can be included in 
--  SELECT, INSERT, UPDATE, and DELETE statements.

-- Searched Case Expressions
-- Syntax:
-- CASE 
--   WHEN C1 THEN E1
--   WHEN C2 THEN E2...
-- END
-- Ex:
CASE
  WHEN employee.title = 'Head Teller'
    THEN 'Head Teller'
  WHEN employee.title = 'Teller'
    AND YEAR(employee.start_date) > 2007
	THEN 'Teller Trainee'
  WHEN empoyee.title = 'Teller'
    AND YEAR(employee.start_date) < 2006
	THEN 'Experienced Teller'
  WHEN employee.title = 'Teller'
    THEN 'Teller'
  ELSE 'Non-Teller'
END

-- [Note that CASE expressions are evaluated from top to bottom, and any
--  WHEN clause that evaluates to TRUE causes all WHEN clauses below it to
--  be ignored. This can lead to bugs.]

-- Ex: Individual and business names, except with subqueries
--  This version uses correlated subqueries and avoids unnecessary JOINs
SELECT c.cust_id, c.fed_id,
  CASE
    WHEN c.cust_type_cd = 'I' THEN
	 (SELECT CONCAT(i.fname, ' ', i.lname)
	  FROM individual i
	  WHERE i.cust_id = c.cust_id)
	WHEN c.cust_type_cd = 'B' THEN
	 (SELECT b.name
	  FROM business b
	  WHERE b.cust_id = c.cust_id)
	ELSE 'Unknown'
  END name
FROM customer c;

-- Simple Case Expressions
--  These use a value to perform the WHEN evaluation
-- Syntax:
-- CASE V0
  -- WHEN V1 THEN E1
  -- WHEN V2 THEN E2
  -- ...
  -- [ELSE ED]
-- END
-- Ex:
CASE customer.cust_type_cd
  WHEN 'I' THEN
   (SELECT CONCAT(i.fname, ' ', i.lname)
    FROM individual I
	WHERE i.cust_id = customer.cust_id
  WHEN 'B' THEN
   (SELECT b.name
    FROM business b
	WHERE b.cust_id = customer.cust_id)
  ELSE 'Unknown Customer Type'
END

-- Notice that the above has equality statements prespecified.
-- Moral of story: Use searched case expressions.

/* ******************************************** ****/
/* ***  Case Expression Examples                ****/
/* ******************************************** ****/
-- Result Set Transformations
-- Ex. Query that shows number of accounts opened in years 2000 to 2005
SELECT YEAR(open_date) year, COUNT(*) how_many
FROM account
WHERE open_date > '1999-12-31'
  AND open_date < '2006-01-01'
GROUP BY YEAR(open_date);

-- Ex. Same query as above, except using CASE to break into 6 columns by year
--  Note: SQL Server and Oracle have PIVOT clauses for these queries
SELECT
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2000 THEN 1
		ELSE 0
	  END) year_2000,
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2001 THEN 1
		ELSE 0
	  END) year_2001,
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2002 THEN 1
		ELSE 0
	  END) year_2002,
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2003 THEN 1
		ELSE 0
	  END) year_2003,
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2004 THEN 1
		ELSE 0
	  END) year_2004,
  SUM(CASE
        WHEN EXTRACT(YEAR FROM open_date) = 2005 THEN 1
		ELSE 0
	  END) year_2005
FROM account
WHERE open_date > '1999-12-31' AND open_date < '2006-01-01';

-- Selective Aggregation
-- Ex. Find accounts whose balances don't agree with raw data 
SELECT CONCAT('ALERT! : Account #', a.account_id,
  ' Has Incorrect Balance!')
FROM account a
WHERE (a.avail_balance, a.pending_balance) <>
 (SELECT
    SUM(CASE
	      WHEN t.funds_avail_date > CURRENT_TIMESTAMP()
		    THEN 0
		  WHEN t.txn_type_cd = 'DBT'
		    THEN t.amount * -1
		  ELSE t.amount
		END),
	SUM(CASE
	      WHEN t.txn_type_cd = 'DBT'
		    THEN t.amount * -1
		  ELSE t.amount
		END)
	FROM transaction t
	WHERE t.account_id = a.account_id);
	
-- Checking For Existence
-- Ex. Check if customer has a checking or savings account
SELECT c.cust_id, c.fed_id, c.cust_type_cd,
  CASE
    WHEN EXISTS (SELECT 1 FROM account a
	  WHERE a.cust_id = c.cust_id
	    AND a.product_cd = 'CHK') THEN 'Y'
	  ELSE 'N'
  END has_checking,
  CASE 
    WHEN EXISTS (SELECT 1 FROM account a
	  WHERE a.cust_id = c.cust_id
	    AND a.product_cd = 'SAV') THEN 'Y'
	ELSE 'N'
  END has_savings
FROM customer c;

-- Ex. Count number of accounts total each customer has 
SELECT c.cust_id, c.fed_id, c.cust_type_cd,
  CASE (SELECT COUNT(*) FROM account a
      WHERE a.cust_id = c.cust_id)
	WHEN 0 THEN 'None'
	WHEN 1 THEN '1'
	WHEN 2 THEN '2'
	ELSE '3+'
  END num_accounts
FROM customer c;

-- Division-by-Zero Errors
--  When a division-by-zero occurs, MySQL sets the result to NULL
SELECT 100/0;

-- To safeguard from division-by-zero, wrap all denominators in conditional
-- logic. 
-- Ex: 
SELECT a.cust_id, a.product_cd, a.avail_balance / 
  CASE
    WHEN prod_tots.tot_balance = 0 THEN 1 /* Coerce 0 totals */
	ELSE prod_tots.tot_balance
  END percent_of_total
FROM account a INNER JOIN
 (SELECT a.product_cd, SUM(a.avail_balance) tot_balance
  FROM account a
  GROUP BY a.product_cd) prod_tots
  ON a.product_cd = prod_tots.product_cd;
  
-- Conditional Updates
-- Ex. Insert new transaction -> modify avail_balance, pending_balance,
--  and last_activity_date in account. To update avail_balance, we have to 
--  know if the funds are immediately available using funds_avail_date.
UPDATE account
  SET last_activity_date = CURRENT_TIMESTAMP(),
  pending_balance = pending_balance +
   (SELECT t.amount *
      CASE t.txn_type_cd WHEN 'DBT' THEN -1 ELSE 1 END
	FROM transaction t
	WHERE t.txn_id = 999),
  avail_balance = avail_balance + 
   (SELECT
       CASE 
	     WHEN t.funds_avail_date > CURRENT_TIMESTAMP() THEN 0
		 ELSE t.amount *
		   CASE t.txn_type_cd WHEN 'DBT' THEN -1 ELSE 1 END
	   END
	 FROM transaction t
	 WHERE t.txn_id = 999)
  WHERE account.account_id=
   (SELECT t.account_id
    FROM transaction t
	WHERE t.txn_id = 999);

-- Handling Null Values
--  It is not always appropriate to retrieve null value sfor display or for
--  use in expressions. 
-- Ex. Display 'unknown' instead of NULL when retrieving a NULL string
SELECT emp_id, fname, lname,
  CASE 
    WHEN title IS NULL THEN 'Unknown'
	ELSE title
  END
FROM employee;

-- Ex. Calculations with NULL values may lead to NULL results
SELECT (7 * 5) / ((3 + 14) * NULL);
-- Take care to deal with NULL values. Use CASE expressions to deal with them.

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 11-1
--  Rewrite the following query, which uses a simple case expression, so that 
--  the same results are achieved using a searched case expression. Try to use
--  as few WHEN clauses as possible.
-- SELECT emp_id,
--   CASE title
--     WHEN 'President' THEN 'Management'
--     WHEN 'Vice President' THEN 'Management'
--     WHEN 'Treasurer' THEN 'Management'
--     WHEN 'Loan Manager' THEN 'Management'
--     WHEN 'Operations Manager' THEN 'Operations'
--     WHEN 'Head Teller' THEN 'Operations'
--     When 'Teller' THEN 'Operations'
--     ELSE 'Unknown'
--   END
-- FROM employee;
SELECT emp_id,
  CASE
    WHEN title IN ('President','Vice President',
	  'Treasurer','Loan Manager') THEN 'Management'
    WHEN title IN ('Operations Manager','Head Teller',
      'Teller') THEN 'Operations'
    ELSE 'Unknown'
  END dept
FROM employee;

-- Book Answer:
SELECT emp_id,
  CASE
    WHEN title LIKE '%President' OR title = 'Loan Manager'
	  OR title = 'Treasurer'
	  THEN 'Management'
	WHEN title LIKE '%Teller' OR title = 'Operations Manager'
	  THEN 'Operations'
	ELSE 'Unknown'
  END dept
FROM employee;

-- Exercise 11-2
--  Rewrite the following query so that the result contains a single row
--  with four columns (one for each branch). Name the four columns branch_1
--  through branch_4.
-- SELECT open_branch_id, COUNT(*)
-- FROM account
-- GROUP BY open_branch_id;
SELECT
  SUM(CASE
        WHEN open_branch_id = 1 THEN 1
		ELSE 0
	  END) branch_1,
  SUM(CASE
        WHEN open_branch_id = 2 THEN 1
		ELSE 0
	  END) branch_2,
  SUM(CASE
        WHEN open_branch_id = 3 THEN 1
		ELSE 0
	  END) branch_3,
  SUM(CASE
        WHEN open_branch_id = 4 THEN 1
		ELSE 0
	  END) branch_4
FROM account;

-- Book Answer (better formatting)
SELECT
  SUM(CASE WHEN open_branch_id = 1 THEN 1 ELSE 0 END) branch_1,
  SUM(CASE WHEN open_branch_id = 2 THEN 1 ELSE 0 END) branch_2,
  SUM(CASE WHEN open_branch_id = 3 THEN 1 ELSE 0 END) branch_3,
  SUM(CASE WHEN open_branch_id = 4 THEN 1 ELSE 0 END) branch_4
FROM account;