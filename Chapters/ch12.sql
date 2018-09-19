/* ************* LEARNING SQL CHAPTER 12 *************** */
/* ************     TRANSACTIONS                     *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Multiuser Databases                     ****/
/* ******************************************** ****/
-- Realistically, multiple queries are going on in a database that may edit
--  the database as queries are being run. For example, getting transactions
--  while a teller is actually inputting a new transaction.

-- Locking
--  Locks control simultaneous use of data resources. The main strategies are:
--  1. DB writers request and receive a write lock to modify data, and
--   DB user receive and request a read lock. One write lock is given at a time
--   and read requests are blocked until the write lock is released.
--  --> While someone is modifying, no one should be trying to read further.
--  2. DB writers request and receive write lock, but users don't need lock
--   to query data. Server ensures consistent view of data from time of query.
--   This is known as "versioning."
--  Strat 1 can lead to long wait times, and strat 2 can be messy for long read

-- Lock Granularities
--  Table locks: Restrict simultaneous editing of a table by multiple users
--  Page locks: Restrict simultaneous editing of page of table (2KB - 16KB)
--  Row locks: Restrict simultaneous of a row

/* ******************************************** ****/
/* ***  What Is a Transaction?                  ****/
/* ******************************************** ****/
-- To solve concurrency and chance for human error, databases can group
--  SQL statements together in a transaction. If all is well, we COMMIT the
--  changes, much like a version control. Otherwise, we can ROLLBACK.
-- For example, we would process a transfer from savings to checking
--  only if everything along the way succeeded. Otherwise, money would be in
--  limbo if, say, the bank closed at the time of transaction or an ATM error.

-- Ex. Pseudocode to record a transaction
-- START TRANSACTION;
-- /* withdraw money from first account, making sure balance is sufficient */
-- UPDATE account SET avail_balance = avail_balance - 500
-- WHERE account_id = 9988
  -- AND avail_balance > 500;

-- IF <exactly one row was updated by the previous statement> THEN
  -- /* deposit money into second account */
  -- UPDATE account SET avail_balance = avail_balance + 500
    -- WHERE account_id = 9989;
  
  -- IF <exactly one row was updated by the previous statement> THEN
    -- /* everything worked, make the changes permanent */
	-- COMMIT;
  -- ELSE
    -- /* something went wrong, undo all changes in this transaction */
	-- ROLLBACK;
  -- END IF;
-- ELSE
  -- /* insufficient funds, or error encountered during update */
  -- ROLLBACK;
-- END IF;

-- Suppose the above transaction didn't complete, then the server will 
--  roll it back before coming online. If a COMMIT was applied, then the
--  server will reapply the changes when the server is restarted (durability)

-- Starting a Transaction
--  There are two main ways a server deals with transaction creation:
--    1. The active transaction is always associated with the DB session
--    2. Unless transaction is explicit, SQL statements are auto committed
--  The second is known as auto-commit mode, and MySQL uses it
-- To turn auto-commit mode off:
SET IMPLICIT_TRANSACTIONS ON /* SQL Server */

SET AUTOCOMMIT = 0 /* MySQL */
-- It's a good idea to turn autocommit off to avoid mistakes.

-- Permanently commit changes using COMMIT
COMMIT;

-- ROLLBACK changes to undo any changes done with COMMIT
ROLLBACK;

-- Transactions can end outside the context of COMMIT and ROLLBACK
--  * server turns off --> current transaction is rolled back
--  * SQL schema statements (e.g. alter table) --> transaction is committed
--  * start another START TRANSACTION --> previous transaction committed
--  * server ends transaction because of a deadlock --> rollback
-- Note: Any alterations to a database, like adding a new table or index,
--  cannot be rolled back. Commands that alter the schema must take place
--  outside of the context of a transaction.
--    So, in the 3rd bullet, the transaction ends, schema altered, and then
--  a new transaction is created automatically. 
--    In a deadlock, two different transactions are waiting for resources
--  the other holds. i.e. A updates account and waits for write lock on 
--  transaction, but B updates transaction and waits for write lock on account
--  Both would wait forever! One must be rolled back so the other proceeds.
--  You can retry after a deadlock. But in general, the server should be 
--  designed to minimize deadlocks.

-- Transaction Savepoints
--  Rollbacks undo everything in a commit. If you want to save checkpoints
--   along the way, then savepoints are what you want.
--  MySQL includes several storage engines. 
-- To get your engine:
SHOW TABLE STATUS LIKE 'transaction' \G
-- To change engine:
ALTER TABLE transaction ENGINE = INNODB;

-- Savepoints must be named:
SAVEPOINT my_savepoint;

-- To rollback to a savepoint:
ROLLBACK TO SAVEPOINT my_savepoint;

-- Ex:
START TRANSACTION;

UPDATE product
SET date_required = CURRENT_TIMESTAMP()
WHERE product_cd = 'XYZ';

SAVEPOINT before_close_accounts;

UPDATE account
SET status = 'CLOSED', close_date = CURRENT_TIMESTAMP(),
  last_activity_date = CURRENT_TIMESTAMP()
WHERE product_cd = 'XYZ';

ROLLBACK TO SAVEPOINT before_close_accounts;
COMMIT;

-- Nothing in a savepoint is actually saved. You must COMMIT for the 
--  transaction to be permanent. If you ROLLBACK without a savepoint,
--  the entire transaction is undone.

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 12-1
--  Generate a transaction to transfer $50 from Frank Tucker's money market
--  account to his checking account. You will need to insert two rows into
--  the transaction table and update two rows in the account table.
START TRANSACTION;

SAVEPOINT before_transactions;
/* Insert two transactions */
-- Debit from Frank's MM
INSERT INTO transaction
 (txn_date, account_id, txn_type_cd, amount, funds_avail_date)
VALUES
 (CURRENT_TIMESTAMP(),
  (SELECT account_id
   FROM account a INNER JOIN individual i
     ON a.cust_id = i.cust_id
   WHERE i.fname = 'Frank' AND i.lname = 'Tucker'
     AND a.product_cd = 'MM'),
   'DBT',
   50,
   CURRENT_TIMESTAMP())
 
-- Credit to Frank's checking
INSERT INTO transaction
 (txn_date, account_id, txn_type_cd, amount, funds_avail_date)
VALUES
 (CURRENT_TIMESTAMP(),
  (SELECT account_id
   FROM account a INNER JOIN individual i
     ON a.cust_id = i.cust_id
   WHERE i.fname = 'Frank' AND i.lname = 'Tucker'
     AND a.product_cd = 'CHK'),
   'CDT',
   50,
   CURRENT_TIMESTAMP();
   
SAVEPOINT before_accounts_after_txn;

/* Subtract money from Frank's MM account */
UPDATE account SET avail_balance = avail_balance - 50;
  WHERE account_id = (SELECT account_id
   FROM account a INNER JOIN individual i
     ON a.cust_id = i.cust_id
   WHERE i.fname = 'Frank' AND i.lname = 'Tucker'
     AND a.product_cd = 'CHK')

/* Add money to Frank's checking account */
UPDATE account SET avail_balance = avail_balance + 50;
  WHERE account_id = (SELECT account_id
   FROM account a INNER JOIN individual i
     ON a.cust_id = i.cust_id
   WHERE i.fname = 'Frank' AND i.lname = 'Tucker'
     AND a.product_cd = 'CHK')

COMMIT;

-- Book Answer, using user-defined variables never introduced lol & subqueries
START TRANSACTION;
/* Find Frank Tucker's information and place into variables to reuse */
SELECT i.cust_id 
 (SELECT a.account_id FROM account a
  WHERE a.cust_id = i.cust_id
    AND a.product_cd = 'MM') mm_id
 (SELECT a.account_id FROM account a
  WHERE a.cust_id = i.cust_id
    AND a.product_cd = 'CHK') chk_id
INTO @cst_id, @mm_id, @chk_id
FROM individual i
WHERE i.fname = 'Frank' AND i.lname = 'Tucker';
/* Update transaction table */
INSERT INTO transaction (txn_id, txn_date, account_id,
  txn_type_cd, amount)
VALUE (NULL, now(), @mm_id, 'CDT', 50);

INSERT INTO transaction (txn_id, txn_date, account_id,
  txn_type_cd, amount)
VALUES (NULL, now(), @chk_id, 'DBT', 50);

UPDATE account
SET last_activity_date = now(),
  avail_balance = avail_balance - 50
WHERE account_id = @mm_id;

UPDATE account
SET last_activity_date = now(),
  avail_balance = avail_balance + 50
WHERE account_id = @chk_id;

COMMIT;