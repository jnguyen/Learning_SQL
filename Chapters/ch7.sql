/* ************* LEARNING SQL CHAPTER 7 **************** */
/* *** DATA GENERATION, CONVERSION, AND MANIPULATION *** */
/* ***************************************************** */

/* ******************************************** ****/
/* ***  Working With String Data                ****/
/* ******************************************** ****/
-- String Generation
--  Several options exist for storing string data, dependent on the SQL server
CREATE TABLE string_tbl
 (char_fld CHAR(30),       /* fixed length */
  vchar_fld VARCHAR(30),  /* variable length */
  text_fld TEXT           /* large variable length */
 );

-- Populate a character column by enclosing a string in quotes.
INSERT INTO string_tbl (char_fld, vchar_fld, text_fld)
VALUES ('This is char data',
  'This is varchar data',
  'This is text data');
  
-- Inserting a string above the maximum char of a column throws an error
UPDATE string_tbl
SET vchar_fld = 'This is a piece of extremely long varchar data';

-- By default, MySQL is 'strict' and throws errors. Setting MySQL to ANSI
--  mode instead will truncate long strings and warn you instead.
-- Output current SQL mode
SELECT @@session.sql_mode;

-- Change to ANSI compatibility; will now truncate overflowing strings
SET sql_mode='ansi';

-- Inserting the long string now truncates it
UPDATE string_tbl
SET vchar_fld = 'This is a piece of extremely long varchar data';

SHOW WARNINGS;

SELECT vchar_fld
FROM string_tbl;
-- Note that MySQL only stores enough for each string, so setting a high
--  limit is not necessarily wasteful

-- Strings are demarcated by single quotes ('). To include single quotes
--  in a string literal, simply type it twice (''),or use an escape char (\')
--  Note: when retrieving non-system generated data for export, use quote()
UPDATE string_tbl
SET text_fld = 'This string didn''t work, but it does now';

SELECT text_fld
FROM string_tbl;

-- MySQL includes a chr() function for special characters in the ASCII set.
SELECT 'abcdefg', CHAR(97,98,99,100,101,102,103);

-- Use CONCAT() to concatenate individual strings
SELECT CONCAT('Hanna', 'Monta', CHAR(195), 'a');

-- ASCII equivalents can be retrieved via the ASCII() function
SELECT ASCII('ñ');

-- String Manipulation
--  Delete rows using DELETE FROM to reset the string_tbl
DELETE FROM string_tbl;

INSERT INTO string_tbl (char_fld, vchar_fld, text_fld)
VALUES ('This string is 28 characters',
  'This string is 28 characters',
  'This string is 28 characters');

-- String functions can return numbers or strings
-- Ex. LENGTH() returns the length of a string. Note that MySQL Server 
--  removes all trailing spaces from char data when it is retrieved.
SELECT LENGTH(char_fld) char_length,
  LENGTH(vchar_fld) varchar_length,
  LENGTH(text_fld) text_length
FROM string_tbl;

-- POSITION() finds the location of a substring within the string
--  Note: value 0 means substring not found, and counting begins at 1
SELECT POSITION('characters' IN vchar_fld)
FROM string_tbl;

-- LOCATE() is a MySQL function that can perform POSITION at a different start
SELECT LOCATE('is', vchar_fld, 5)
FROM string_tbl;

-- STRCMP() is a MySQL function that compares two strings
--  -1: first string comes before second string in sort order
--   0: strings are identical
--   1: first string comes after second string in sort order
DELETE FROM string_tbl;
INSERT INTO string_tbl(vchar_fld) VALUES ('abcd');
INSERT INTO string_tbl(vchar_fld) VALUES ('xyz');
INSERT INTO string_tbl(vchar_fld) VALUES ('QRSTUV');
INSERT INTO string_tbl(vchar_fld) VALUES ('qrstuv');
INSERT INTO string_tbl(vchar_fld) VALUES ('12345');
-- View the strings in sort order
SELECT vchar_fld
FROM string_tbl
ORDER BY vchar_fld;

-- Use STRCMP(); to compare strings by their sort order 
SELECT STRCMP('12345','12345') 12345_12345,
  STRCMP('abcd','xyz') abcd_xyz,
  STRCMP('abcd','QRSTUV') abcd_QRSTUV,
  STRCMP('qrstuv','QRSTUV') qrstuv_QRSTUV, /* 0: strcmp() case-insensitive */
  STRCMP('12345','xyz') 12345_xyz,
  STRCMP('xyz','qrstuv') xyz_qrstuv;
  
-- MySQL allows the use of like and regexp operators to compare strings
--  The result of these comparisons is a boolean (0 = false; 1 = true)
-- Get names of each department and whether they end in 'ns'
SELECT name, name LIKE '%ns' ends_in_ns
FROM department;

-- regexp provides more complex search options
SELECT cust_id, cust_type_cd, fed_id,
  fed_id REGEXP '.{3}-.{2}-.{4}' is_ss_no_format /* \d{3}-\d{2}-\d{4} */
FROM customer;

-- String functions that return strings
DELETE FROM string_tbl;
INSERT INTO string_tbl (text_fld)
VALUES ('This string was 29 characters');

-- CONCAT() is useful for appending characters to a string
UPDATE string_tbl
SET text_fld = CONCAT(text_fld, ',but now it is longer');

SELECT text_fld
FROM string_tbl;

-- It is possible to build strings from individual pieces of data with CONCAT()
SELECT CONCAT(fname, ' ', lname, ' has been a ',
  title, ' since ', start_date) emp_narrative
FROM employee
WHERE title = 'Teller' or title = 'Head Teller';

-- MySQL allows you to INSERT() characters anywhere in a string
--  INSERT(str_orig, start, n_replace_chars, str_to_insert)
SELECT INSERT('goodbye world', 9, 0, 'cruel ') string; /*goodbye cruel world*/
SELECT INSERT('goodbye world', 1, 7, 'hello') string;  /*hello world*/

-- Use SUBSTR() to extract a substring
--  SUBSTRING(string, start, n_chars)
SELECT SUBSTRING('goodbye cruel world', 9, 5) cruel;

/* ******************************************** ****/
/* ***  Working With Numeric Data               ****/
/* ******************************************** ****/
-- Usual arithmetic operators function as expected (PEMDAS)
SELECT (37 * 59) / (78 - (8 * 6));

-- Many usual built in mathematical functions exist, like COS( X ) and EXP( X )
SELECT EXP(1), MOD(10,4), COS(0),
SELECT MOD(22.75, 5); /* MOD() also works with real numbers */
SELECT POW(2,8);      /* 2^8 */
SELECT POW(2,10) kilobyte, POW(2,20) megabyte, /* get number of bytes */
  POW(2,30) gigabyte, POW(2,40) terabyte;
  
-- Use CEIL(), FLOOR(), ROUND(), and TRUNCATE() to trim real numbers
SELECT CEIL(72.445), FLOOR(72.445); /* CEIL rounds up, FLOOR rounds down */
SELECT CEIL(72.0000000001), FLOOR(72.9999999999); /* 73, 72 */
-- ROUND() will round based on how many digits to the right you specify
SELECT ROUND(72.0909, 1), ROUND(72.0909, 2), ROUND(72.0909, 3);
-- TRUNCATE() keeps the number of digits to the right you specify
SELECT TRUNCATE(72.0909, 1), TRUNCATE(72.0909, 2), TRUNCATE(72.0909, 3);
-- ROUND() and TRUNCATE() also take negative values for the second argument
SELECT ROUND(17, -1), /* round left hand side to digits specified */
  TRUNCATE(17, -1);   /* convert n number of left hand side digits to 0 */
  
-- Use SIGN() to get the sign of a number (-1 neg, 0 none, 1 pos)
--  and ABS() to get the magnitude of a number
SELECT account_id, SIGN(avail_balance), ABS(avail_balance)
FROM account;

/* ******************************************** ****/
/* ***  Working With  Temporal Data             ****/
/* ******************************************** ****/
-- MySQL can retrieve UTC time with UTC_TIMESTAMP()
SELECT UTC_TIMESTAMP();
-- MySQL has two time zone settings: global and session
--  'SYSTEM' means the server's time zone is being used
SELECT @@global.time_zone, @@session.time_zone;
-- You can the session time zone by running SET time_zone
--  Note: You may need to manually import TZ tables on Windows or Ubuntu
-- mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
SET time_zone = 'America/Detroit';
SELECT @@global.time_zone, @@session.time_zone;

-- Generate temporal data by copying, executing a function, or using a string
--  Ex: edit transaction date using a string for a datetime column
UPDATE transaction
SET txn_date = '2008-09-17 15:30:00'
WHERE txn_id = 99999;

-- If the server doesn't expect a datetime, you must explicit CAST() the string
SELECT CAST('2008-09-17' AS DATE) date_field,
  CAST('108:17:57' AS TIME) time_field;
  
-- Servers may be strict about format, though MySQL is lenient.
--  The following are all equivalent DATETIME formats:
--    '2008-09-17 15:30:00'
--    '2008/09/17 15:30:00'
--    '2008,09,17 15,30,00'
--    '20080917153000'

-- STR_TO_DATE() allows non-standard date formats to be properly parsed
--  The function will return the minimum time format needed to store the result
UPDATE individual
SET birth_date = STR_TO_DATE('September 17, 2008', '%M %d, %Y')
WHERE cust_id = 9999;

-- You can SELECT the CURRENT_DATE(), CURRENT_TIME(), and CURRENT_TIMESTAMP()
SELECT CURRENT_DATE(), CURRENT_TIME(), CURRENT_TIMESTAMP();

-- Manipulating Temporal Data
--  Built-in functions are useful for manipulating time fields
-- DATE_ADD() can add a date to another, ex. today + 5 days
SELECT DATE_ADD(CURRENT_DATE(), INTERVAL 5 DAY);

-- Add an amount of hours, minutes, and seconds with the Hour_second format
--  ex. add 3 hours, 27 minutes, and 11 seconds ('3:27:11')
UPDATE transaction
SET txn_date = DATE_ADD(txn_date, INTERVAL '3:27:11' HOUR_SECOND)
WHERE txn_id = 9999;

-- Add 9 years and 11 months to employee 4789's birth year record
UPDATE employee
SET birth_date = DATE_ADD(birth_date, INTERVAL '9-11' YEAR_MONTH)
WHERE emp_id = 4789;

-- Use LAST_DAY() to get the last day in the month
SELECT LAST_DAY('2008-09-17');

-- MySQL's CONVERT_TZ() can convert one datetime timezone to another
SELECT CURRENT_TIMESTAMP current_set,
  CONVERT_TZ(CURRENT_TIMESTAMP(), 'US/Eastern', 'UTC') current_utc;

-- MySQL includes DAYNAME() to get the day of the week of a given date
SELECT DAYNAME('2008-09-18');

-- EXTRACT() is SQL:2003 compliant, and can extract a date element
-- ex. Extract the year from a date
SELECT EXTRACT(YEAR FROM '2008-09-18 22:19:05');

-- Temporal functions that return numbers
--  DATEDIFF() determines the number of intervals between two dates
-- Ex. Number of days in summer break
SELECT DATEDIFF('2009-09-03', '2009-06-24'); /* 71 */
-- Note: DATEDIFF() ignores the time of day in the argument
SELECT DATEDIFF('2009-09-03 23:59:59', '2009-06-24 00:00:01'); /* still 71 */
-- DATEDIFF() always takes the difference between the first and second argument
SELECT DATEDIFF('2009-06-24', '2009-09-03'); /* -71 */

/* ******************************************** ****/
/* ***  Conversion Functions                    ****/
/* ******************************************** ****/
-- CAST() can be generally used to convert between data types
-- Ex. Convert a string of numbers to a signed integer
SELECT CAST('1456328' AS SIGNED INTEGER);

-- CAST() attempts conversion from left to right
-- Ex. Trying to convert a mixed string will result in first type encountered
SELECT CAST('999ABC111' AS UNSIGNED INTEGER);
SHOW WARNINGS; /* Truncated incorrect INTEGER value; */

-- Note that CAST() cannot take a format string, so you must use the 
--  exact formats when casting strings for date, time, or datetime
--  Functions like STR_TO_DATE() can overcome this limitation

/* ******************************************** ****/
/* ***  Test Your Knowledge                     ****/
/* ******************************************** ****/
-- Exercise 7-1
--  Write a query that returns the 17th through 25th characters of the string
--  'Please find the substring in this string'
SELECT SUBSTRING('Please find the substring in this string', 17, 25-17+1);

-- Exercise 7-2
--  Write a query that returns the absolute value and sign (-1, 0, or 1) of
--  the number -25.76823. Also return the number rounded to the nearest 100th.
SELECT -25.76823 number, ABS(-25.76823) abs_num,
  SIGN(-25.76823) sgn_num, ROUND(-25.76823,2) rnd_num;
  
-- Exercise 7-3
--  Write a query to return just the month portion of the current date.
SELECT EXTRACT(MONTH FROM CURRENT_DATE());