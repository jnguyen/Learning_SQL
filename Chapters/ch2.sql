/* ************* LEARNING SQL CHAPTER 2  *************** */
/* ************ CREATING AND POPULATING A DATABASE   *** */
/* ***************************************************** */

/* Query current time */
SELECT now();

/* ************ MYSQL DATATYPES ************* */
/* Show all available character sets */
SHOW CHARACTER SET;  

/* Define a column set to be UTF-8 specifically */
VARCHAR(20) CHARACTER SET utf8

/* Or: define character set for entire database */
CREATE DATABASE foreign_sales CHARACTER SET utf8;

/* Text Types */
TINYTEXT    /* 255 bytes */
TEXT        /* 65,535 bytes */
MEDIUMTEXT  /* 16,777,215 bytes */
LONGTEXT    /* 4,294,967,295 bytes */

/* Integer Types */
TINYINT		
SMALLINT    
MEDIUMINT   
INT          
BIGINT       

/* Float Types */
FLOAT(p,s)  /* Precision (total digits), Scale (decimal only) */
DOUBLE(p,s)

/* Date Types */
DATE       /* YYYY-MM-DD           */
DATETIME   /* YYYY-MM-DD HHH:MI:SS */
TIMESTAMP  /* YYYY-MM-DD HHH:MI:SS */
YEAR       /* YYYY                 */
TIME       /* HHH:MI:SS            */


/* ************ CREATING TABLES ************* */
-- Here, we create tables to describe a person and their favorite foods
CREATE TABLE person
 (person_id SMALLINT UNSIGNED,
  fname VARCHAR(20),
  lname VARCHAR(20),
  gender ENUM('M','F'), /* MySQL doesn't parse CHECK statements */ 
  birth_date DATE,
  street VARCHAR(30),
  city VARCHAR(20),
  state VARCHAR(20),
  country VARCHAR(20),
  postal_code VARCHAR(20),
  CONSTRAINT pk_person PRIMARY KEY (person_id) /* unique ID per person */
 );
 
-- Check newly created TABLE person
DESC person;

-- Create favorite food table
CREATE TABLE favorite_food
 (person_id SMALLINT UNSIGNED,
  food VARCHAR(20),
  CONSTRAINT pk_favorite_food PRIMARY KEY (person_id, food),
  CONSTRAINT fk_fav_food_person_id FOREIGN KEY (person_id)
   REFERENCES person (person_id)
 );
 
DESC favorite_food;

-- Turn on auto-increment for person_id after having CREATEd TABLE person
ALTER TABLE person MODIFY person_id SMALLINT UNSIGNED AUTO_INCREMENT;
DESC person;