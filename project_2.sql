-- Library Management System Project 2

CREATE DATABASE library_project_2;
USE library_project_2;
DROP DATABASE library_project_2;

-- creating branch table
DROP TABLE IF EXISTS branch;
CREATE TABLE branch(
	branch_id VARCHAR(10) PRIMARY KEY,
    manager_id VARCHAR(10),	
    branch_address VARCHAR(50),	
    contact_no VARCHAR(10)
);

ALTER TABLE branch
MODIFY contact_no VARCHAR(15);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
	emp_id VARCHAR(10) PRIMARY KEY,
	emp_name VARCHAR(25),	
    position_ VARCHAR(15),	
    salary INT,	
    branch_id VARCHAR(25) -- FK
);

ALTER TABLE employees
MODIFY salary FLOAT;

DROP TABLE IF EXISTS books;
CREATE TABLE books(
	isbn VARCHAR(20) PRIMARY KEY,	
    book_title VARCHAR(75),	
    category VARCHAR(25),	
    rental_price FLOAT,	
    status_ VARCHAR(15),	
    author VARCHAR(15),	
    publisher VARCHAR(55)
);

DROP TABLE IF EXISTS members;
CREATE TABLE members(
	member_id VARCHAR(10) PRIMARY KEY,	
    member_name VARCHAR(25),	
    member_address VARCHAR(75),	
    reg_date DATE
);

DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status(
	issued_id VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(10), -- FK	
    issued_book_name VARCHAR(75),	
    issued_date DATE,	
    issued_book_isbn VARCHAR(25), -- FK 	
    issued_emp_id VARCHAR(10) -- FK
);

ALTER TABLE issued_status
MODIFY issued_book_name VARCHAR(200);


DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status(
	return_id VARCHAR(10) PRIMARY KEY,	
    issued_id VARCHAR(10),	
    return_book_name VARCHAR(75),	
    return_date DATE,	
    return_book_isbn VARCHAR(20)
);

ALTER TABLE return_status
MODIFY return_book_name VARCHAR(200);

-- FOREIGN KEY

ALTER TABLE issued_status
ADD CONSTRAINT fk_members 
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books 
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees 
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch 
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

INSERT INTO return_status (return_id, issued_id, return_book_name, return_date, return_book_isbn) VALUES
('RS104', 'IS106', NULL, '2024-05-01', NULL),
('RS108', 'IS110', NULL, '2024-05-09', NULL),
('RS109', 'IS111', NULL, '2024-05-11', NULL),
('RS111', 'IS113', NULL, '2024-05-15', NULL),
('RS113', 'IS115', NULL, '2024-05-19', NULL),
('RS114', 'IS116', NULL, '2024-05-21', NULL),
('RS115', 'IS117', NULL, '2024-05-23', NULL),
('RS116', 'IS118', NULL, '2024-05-25', NULL),
('RS117', 'IS119', NULL, '2024-05-27', NULL),
('RS118', 'IS120', NULL, '2024-05-29', NULL);
-- others data imported by normally importing

-- Project task

-- Task 1 : Create a New Book Record : "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT *
FROM books;

-- Task 2 : Update an Existing Member's Address
UPDATE members
SET member_address='abc_colony'
WHERE member_id='C101';

-- Task 3 : Delete a Record from the Issued Status Table
DELETE FROM issued_status
WHERE issued_id='IS106';

-- Task 4 : Retrieve All Books Issued by a Specific Employee
SELECT * 
FROM issued_status
WHERE issued_emp_id='E105';  

-- Task 5 : List Members Who Have Issued More Than One Book
SELECT issued_emp_id,COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*)>1;

-- CTAS(Create Table As Select)

-- Task 6 : Create Summary Tables : Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE book_cnts AS
SELECT b.isbn,b.book_title,COUNT(i.issued_id) AS book_issued_cnt
FROM books AS b 
JOIN issued_status AS i
ON b.isbn=i.issued_book_isbn
GROUP BY 1;

SELECT * FROM book_cnts;

-- Data Analysis & Findings

-- Task 7 : Retrieve All Books in a Specific Category

SELECT *
FROM books
WHERE category='Classic';

-- Task 8 : Find Total Rental Income by Category
SELECT b.category,SUM(b.rental_price)
FROM issued_status AS i
JOIN books AS b
ON b.isbn=i.issued_book_isbn
GROUP BY 1;

-- Task 9 : List Members Who Registered in the Last 180 Days
SELECT * 
FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

-- Task 10 : List Employees with Their Branch Manager's Name and their branch details
SELECT e1.emp_id,e1.emp_name,e1.position_,e1.salary,b.*,e2.emp_name AS manager
FROM employees AS e1
JOIN branch AS b
ON e1.branch_id=b.branch_id
JOIN employees AS e2
ON e1.emp_id=b.manager_id;

-- Task 11 : Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE expensive_books AS 
SELECT * 
FROM books
WHERE rental_price>7.00;

SELECT *
FROM expensive_books;

-- Task 12 : Retrieve the List of Books Not Yet Returned
SELECT *
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
WHERE r.issued_id IS NULL;

-- Advanced SQL Operations

-- Task 13 : Identify Members with Overdue Books 
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue
SELECT i.issued_member_id,m.member_name,b.book_title,i.issued_date,DATEDIFF(CURRENT_DATE(),i.issued_date) AS over_dues_days
FROM issued_status AS i
JOIN members AS m 
ON i.issued_member_id=m.member_id
JOIN books AS b
ON b.isbn=i.issued_book_isbn
LEFT JOIN return_status AS r
ON r.issued_id=i.issued_id
WHERE r.return_date IS NULL AND (CURRENT_DATE()-i.issued_date)>30
ORDER BY 1;

-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table)
DELIMITER $$

CREATE PROCEDURE add_return_records(
	IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
	DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);
    
	-- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id,issued_id,return_date,book_quality)
    VALUES (p_return_id,p_issued_date,CURRENT_DATE(),p_book_quality);
    
    SELECT issued_book_isbn,issued_book_name
    INTO v_isbn,v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id
    LIMIT 1;
    
    UPDATE books
    SET status='yes'
    WHERE isbn=v_isbn;
    
    SELECT CONCAT('Thankyou for returning the book : ',v_book_name) AS message;
END$$

DELIMITER ;

CALL add_return_records('RS148', 'IS140', 'Good');


-- Task 15 : Branch Performance Report 
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals
CREATE TABLE branch_reports AS 
SELECT b.branch_id,b.manager_id,COUNT(i.issued_id) AS number_book_issued,COUNT(r.return_id) AS number_book_returned,SUM(bk.rental_price) AS total_revenue
FROM issued_status AS i
JOIN employees AS e
ON i.issued_emp_id=e.emp_id
JOIN branch AS b
ON e.branch_id=b.branch_id
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
JOIN books AS bk
ON bk.isbn=i.issued_book_isbn
GROUP BY 1,2;

SELECT *
FROM branch_reports;

-- Task 16 : CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN(SELECT DISTINCT issued_member_id
                   FROM issued_status
                   WHERE issued_date >= CURRENT_DATE() - INTERVAL 2 month
                   );
                   
SELECT * FROM active_members;

-- Task 17 : Find Employees with the Most Book Issues Processed  
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch
SELECT e.emp_name,b.*,COUNT(i.issued_id) AS no_book_issued
FROM issued_status AS i
JOIN employees AS e
ON e.emp_id=i.issued_emp_id
JOIN branch AS b
ON e.branch_id=b.branch_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;

-- Task 19 : Stored Procedure
-- Objective:
-- Create a stored procedure to manage the status of books in a library system.
-- Description:
-- Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
-- The stored procedure should take the book_id as an input parameter.
-- The procedure should first check if the book is available (status = 'yes').
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
-- If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available
DELIMITER $$

CREATE PROCEDURE issue_book(p_issued_id VARCHAR(10),p_issued_member_id VARCHAR(30),p_issued_book_isbn VARCHAR(30),p_issued_emp_id VARCHAR(10))

BEGIN
	DECLARE v_status VARCHAR(10);
	
    -- all the code
	-- checking if status of book is 'yes'
	SELECT status INTO v_status
	FROM books 
	WHERE isbn=p_issued_book_isbn;
		
	IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn_issued_emp_id)
		VALUES (p_issued_id,p_issued_member_id,CURRENT_DATE(),p_issued_book_isbn,p_issued_emp_id);
            
		UPDATE books
		SET status='no'
		WHERE isbn=p_issued_book_isbn;
            
	    SELECT CONCAT('Book records added successfully for book isbn : %',p_issued_book_isbn) AS message;
        
	ELSE 
	    SELECT CONCAT('sorry to inform you the book you have requested is unavailable: %', p_issued_book_isbn) AS message;
	
    END IF; 
            
END $$

DELIMITER ;