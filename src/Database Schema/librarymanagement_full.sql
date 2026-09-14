-- Full SQL for Library Management System
-- Database: librarymanagement

DROP DATABASE IF EXISTS librarymanagement;
CREATE DATABASE librarymanagement;
USE librarymanagement;

-- ==================================================================
-- TABLES: Core
-- ==================================================================

CREATE TABLE admin (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    userid VARCHAR(100) UNIQUE NOT NULL,
    pass VARCHAR(255) NOT NULL,
    name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_admin_user (userid)
);

CREATE TABLE librarian (
    librarian_id INT AUTO_INCREMENT PRIMARY KEY,
    userid VARCHAR(100) UNIQUE NOT NULL,
    pass VARCHAR(255) NOT NULL,
    name VARCHAR(150),
    role ENUM('Admin','Librarian') DEFAULT 'Librarian',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_librarian_user (userid)
);

CREATE TABLE student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    enrollment_no VARCHAR(50) UNIQUE,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20),
    pass VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    course VARCHAR(100),
    semester VARCHAR(20),
    department_id INT,
    status ENUM('Active','Inactive') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_student_enroll (enrollment_no),
    INDEX idx_student_email (email),
    FOREIGN KEY(department_id) REFERENCES department(department_id)
);
 CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE student
ADD department_id INT,
ADD FOREIGN KEY (department_id)
REFERENCES department(department_id);

CREATE TABLE book_info (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(200),
    publisher VARCHAR(200),
    isbn VARCHAR(50) UNIQUE,
    book_quantity INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_book_title (title),
    INDEX idx_book_isbn (isbn)
);
CREATE TABLE book_copy (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT,  -- FK to book_info
    copy_number INT,  -- 1, 2, 3 ... N
    status ENUM('Available','Issued','Lost','Damaged') DEFAULT 'Available',
    issued_to INT DEFAULT NULL,  -- FK to student_id
    issue_date TIMESTAMP DEFAULT NULL,
    return_date TIMESTAMP DEFAULT NULL,
    FOREIGN KEY (book_id) REFERENCES book_info(book_id)
);

-- ==================================================================
-- TABLES: Transactions & Logs
-- ==================================================================

-- issued_book: issue_date = date issued, return_date = DUE DATE
CREATE TABLE issued_book (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    issue_date DATE NOT NULL,
    return_date DATE NOT NULL,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book_info(book_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_issued_student (student_id),
    INDEX idx_issued_book (book_id)
);
ALTER TABLE issued_book
    DROP COLUMN return_date,
    ADD COLUMN issue_days INT NOT NULL DEFAULT 20 AFTER issue_date;

ALTER TABLE issued_book
ADD COLUMN copy_id INT NOT NULL AFTER book_id,
ADD INDEX idx_issued_copy (copy_id);

-- Add foreign key to book_copy
ALTER TABLE issued_book
ADD CONSTRAINT fk_issued_copy
FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;


CREATE TABLE returned_book (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    issue_id INT NOT NULL,
    return_date DATE NOT NULL,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book_info(book_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (issue_id) REFERENCES issued_book(issue_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_return_issue (issue_id),
    INDEX idx_return_student (student_id)
);

ALTER TABLE returned_book
ADD COLUMN copy_id INT NOT NULL AFTER book_id,
ADD INDEX idx_return_copy (copy_id);

-- Add foreign key to book_copy
ALTER TABLE returned_book
ADD CONSTRAINT fk_return_copy
FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;


CREATE TABLE issue_fine (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    issue_id INT NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NOT NULL,
    fine_amount DECIMAL(10,2) NOT NULL,
    payment_status ENUM('UNPAID','PAID') DEFAULT 'UNPAID',
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book_info(book_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (issue_id) REFERENCES issued_book(issue_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_fine_student (student_id),
    INDEX idx_fine_issue (issue_id)
);
ALTER TABLE issue_fine
ADD COLUMN copy_id INT NOT NULL AFTER book_id,
ADD INDEX idx_fine_copy (copy_id);

-- Add foreign key to book_copy
ALTER TABLE issue_fine
ADD CONSTRAINT fk_fine_copy
FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

CREATE TABLE fine_payment_records (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    fine_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (fine_id) REFERENCES issue_fine(fine_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_payment_fine (fine_id)
);

-- notifications
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_notify_student (student_id)
);

-- system_settings (ISSUE_DAYS, FINE_PER_DAY)
CREATE TABLE system_settings (
    setting_key VARCHAR(100) PRIMARY KEY,
    setting_value VARCHAR(255) NOT NULL
);
INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES
('ISSUE_DAYS','7'),
('FINE_PER_DAY','10');

-- delete logs
CREATE TABLE deleted_book (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT,
    title VARCHAR(255),
    author VARCHAR(200),
    isbn VARCHAR(50),
    deleted_by INT,
    deleted_role ENUM('Admin','Librarian'),
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_deleted_by (deleted_by)
);
ALTER TABLE deleted_book
ADD COLUMN copy_id INT AFTER book_id,
ADD INDEX idx_deleted_copy (copy_id);

ALTER TABLE deleted_book
ADD CONSTRAINT fk_deleted_copy
FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id)
ON DELETE RESTRICT
ON UPDATE CASCADE;


CREATE TABLE deleted_student (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    name VARCHAR(150),
    deleted_by INT,
    role ENUM('Admin','Librarian'),
    reason VARCHAR(255),
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_deleted_student (student_id)
);

-- login and session logs
CREATE TABLE login_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    role ENUM('Student','Admin','Librarian') NOT NULL,
    status ENUM('SUCCESS','FAILED') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_login_user (user_id, role)
);

CREATE TABLE active_session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role ENUM('Student','Admin','Librarian') NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP NULL,
    session_status ENUM('Active','Terminated') DEFAULT 'Active',
    INDEX idx_active_user (user_id, role)
);

CREATE TABLE session_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role ENUM('Student','Admin','Librarian') NOT NULL,
    logout_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE signup_log (
    signup_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES student(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_student_signup (student_id)
);

CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE student
ADD department_id INT,
ADD FOREIGN KEY (department_id)
REFERENCES department(department_id);
 
 ALTER TABLE student
DROP COLUMN course;


-- ==================================================================
-- INDEXES (additional)
-- ==================================================================
ALTER TABLE issued_book ADD INDEX (issue_date);
ALTER TABLE returned_book ADD INDEX (return_date);
ALTER TABLE book_info ADD INDEX (author);

-- ==================================================================
-- TRIGGERS
-- ==================================================================

DELIMITER $$

-- Trigger: log deleted book when book_info row deleted
CREATE TRIGGER trg_book_copy_delete_log
BEFORE DELETE ON book_copy
FOR EACH ROW
BEGIN
    INSERT INTO deleted_book (
        book_id, 
        copy_id,
        title, 
        author, 
        isbn, 
        deleted_by, 
        deleted_role, 
        deleted_at
    )
    SELECT
        OLD.book_id,
        OLD.copy_id,
        b.title,
        b.author,
        b.isbn,
        @deleted_by,
        @deleted_role,
        NOW()
    FROM book_info b
    WHERE b.book_id = OLD.book_id;
END$$

DELIMITER ;

-- Trigger: when a student is deleted (soft-delete recommended). We'll log and prevent hard delete via FK restrict; but if delete happens, log it.
DELIMITER $$
CREATE TRIGGER trg_student_delete_log
BEFORE DELETE ON student
FOR EACH ROW
BEGIN
    INSERT INTO deleted_student (student_id, name, deleted_by, role, reason, deleted_at)
    VALUES (OLD.student_id, OLD.name, @deleted_by, @deleted_role, @deleted_reason, NOW());
END$$
DELIMITER ;
-- Trigger: after insert on student -> signup log
DELIMITER $$
CREATE TRIGGER trg_student_signup
AFTER INSERT ON student
FOR EACH ROW
BEGIN
    INSERT INTO signup_log (student_id, message, created_at)
    VALUES (NEW.student_id, CONCAT('New student registered: ', NEW.name), NOW());
END$$

-- Trigger: after delete on active_session -> move to session_log
CREATE TRIGGER trg_session_delete
AFTER DELETE ON active_session
FOR EACH ROW
BEGIN
    INSERT INTO session_log (user_id, role, logout_time)
    VALUES (OLD.user_id, OLD.role, NOW());
END$$

DELIMITER ;

-- ==================================================================
-- STORED PROCEDURES
-- ==================================================================

DELIMITER $$

-- Procedure: student signup
CREATE DEFINER=`root`@`localhost` PROCEDURE `student_sign_up`(
    IN p_enrollment_no VARCHAR(50),
    IN p_name VARCHAR(150),
    IN p_email VARCHAR(200),
    IN p_phone VARCHAR(20),
    IN p_pass VARCHAR(255),
    IN p_address VARCHAR(255),
    IN p_course VARCHAR(100),
    IN p_semester VARCHAR(20),
    OUT p_message VARCHAR(255)
)
Main_block:BEGIN
    -- Check Enrollment
    IF EXISTS (SELECT 1 FROM student WHERE enrollment_no = p_enrollment_no) THEN
        SET p_message = 'Enrollment already exists';
        LEAVE Main_block;
    END IF;

    -- Check Email
    IF p_email IS NOT NULL AND EXISTS (SELECT 1 FROM student WHERE email = p_email) THEN
        SET p_message = 'Email already exists';
        LEAVE Main_block;
    END IF;

    -- Insert Student
    INSERT INTO student (enrollment_no, name, email, phone, pass, address, course, semester)
    VALUES (p_enrollment_no, p_name, p_email, p_phone, p_pass, p_address, p_course, p_semester);

    -- Auto Login after signup
    CALL student_login_sp(p_email, p_pass, @login_msg);

    SET p_message = 'Student registered successfully';
END$$

-- Procedure: student login
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `student_login_sp`(
    IN  p_email   VARCHAR(255),
    IN  p_pass    VARCHAR(255),
    OUT p_message VARCHAR(255)
)
proc: BEGIN
    DECLARE v_student_id INT DEFAULT NULL;
    DECLARE v_status VARCHAR(20);
    DECLARE v_pass   VARCHAR(255);
    DECLARE v_restriction VARCHAR(80);

    -- Fetch student row
    SELECT student_id, pass, `status`, restriction_status
    INTO v_student_id, v_pass, v_status, v_restriction
    FROM student
    WHERE email = p_email;
    -- CASE-based decision logic
    CASE
        -- CASE 1: Student not found
        WHEN v_student_id IS NULL THEN
			SET p_message = 'Invalid Credentials!!!';
       
            INSERT INTO login_log(user_id, role, status)
            VALUES (p_email, 'Student', 'FAILED');

            LEAVE proc;

        -- CASE 2: Invalid password (case-sensitive)
        WHEN  v_pass <>  TRIM(p_pass) THEN
            SET p_message = 'Invalid password!!!';

            INSERT INTO login_log(user_id, role, status)
            VALUES (p_email, 'Student', 'FAILED');

            LEAVE proc;

        -- CASE 3: Inactive account
        WHEN v_status = 'Inactive' THEN
            SET p_message = 'Your account is inactive. Contact Admin.';

            LEAVE proc;

        -- CASE 4: Restricted account
        WHEN v_restriction = 'Restricted' THEN
            SET p_message = 'Your account is RESTRICTED. Please contact Admin.';

            LEAVE proc;

        -- CASE 5: SUCCESS
        ELSE
            INSERT INTO login_log(user_id, role, status)
            VALUES (p_email, 'Student', 'SUCCESS');

            INSERT INTO active_session(user_id, role, login_time, session_status)
            VALUES (p_email, 'Student', NOW(), 'Active');

            SET p_message = 'Student Login Successful.';
    END CASE;

END$$
DELIMITER ;

-- Procedure: admin login
DELIMITER $$
CREATE PROCEDURE admin_login(
    IN p_userid VARCHAR(100),
    IN p_pass VARCHAR(255)
)
BEGIN
    DECLARE v_admin_id INT;
    SELECT admin_id INTO v_admin_id FROM admin WHERE userid = p_userid AND pass = p_pass;
    IF v_admin_id IS NULL THEN
        INSERT INTO login_log (user_id, role, status) VALUES (0, 'Admin', 'FAILED');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid credentials';
    END IF;
    INSERT INTO login_log (user_id, role, status) VALUES (v_admin_id, 'Admin', 'SUCCESS');
    INSERT INTO active_session (user_id, role, login_time) VALUES (v_admin_id, 'Admin', NOW());
END$$

-- Procedure: librarian login
CREATE PROCEDURE librarian_login(
    IN p_userid VARCHAR(100),
    IN p_pass VARCHAR(255)
)
BEGIN
    DECLARE v_lib_id INT;
    SELECT librarian_id INTO v_lib_id FROM librarian WHERE userid = p_userid AND pass = p_pass;
    IF v_lib_id IS NULL THEN
        INSERT INTO login_log (user_id, role, status) VALUES (0, 'Librarian', 'FAILED');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid credentials';
    END IF;
    INSERT INTO login_log (user_id, role, status) VALUES (v_lib_id, 'Librarian', 'SUCCESS');
    INSERT INTO active_session (user_id, role, login_time) VALUES (v_lib_id, 'Librarian', NOW());
END$$

-- Procedure: get student details by enrollment
CREATE PROCEDURE get_student_details(
    IN p_enrollment_no VARCHAR(50)
)
BEGIN
    SELECT * FROM student WHERE enrollment_no = p_enrollment_no;
END$$

-- Procedure: issue book (transaction)
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `issue_book_sp`(
    IN p_student_id INT,
    IN p_book_id INT,
    IN p_issue_date DATE,
    IN p_issue_days INT,
    OUT p_message VARCHAR(255)
)
main_block: BEGIN
    DECLARE v_restriction VARCHAR(20);
    DECLARE v_quantity INT;
    DECLARE v_copy_id INT;

    -- Check student restriction
    SELECT restriction_status INTO v_restriction 
    FROM student 
    WHERE student_id = p_student_id;

    IF v_restriction = 'Restricted' THEN
        SET p_message = 'This student is RESTRICTED. Book issuing is not allowed.';
        LEAVE main_block;
    END IF;

    -- Check available copies of the book
    SELECT COUNT(*) INTO v_quantity
    FROM book_copy
    WHERE book_id = p_book_id AND status = 'Available';

    IF v_quantity <= 0 THEN
        SET p_message = 'Book is currently unavailable.';
        LEAVE main_block;
    END IF;

    -- Get an available copy_id
    SELECT copy_id INTO v_copy_id
    FROM book_copy
    WHERE book_id = p_book_id AND status = 'Available'
    LIMIT 1;

    -- Issue the book
    INSERT INTO issued_book (student_id, book_id, copy_id, issue_date, issue_days)
    VALUES (p_student_id, p_book_id, v_copy_id, p_issue_date, IFNULL(p_issue_days, 20));

    -- Update copy status to 'Issued'
    UPDATE book_copy
    SET status = 'Issued'
    WHERE copy_id = v_copy_id;

    SET p_message = 'Book issued successfully.';
END$$

-- Procedure: return book (transaction + auto fine)
CREATE DEFINER=`root`@`localhost` PROCEDURE `return_book_proc`(
    IN p_issue_id INT,
    IN p_return_date DATE -- Optional: if you provide, use it
)
main_block: BEGIN
    DECLARE v_student_id INT;
    DECLARE v_book_id INT;
    DECLARE v_copy_id INT;
    DECLARE v_issue_date DATE;
    DECLARE v_issue_days INT;
    DECLARE v_due_date DATE;
    DECLARE v_actual_return_date DATE;
    DECLARE v_days_late INT DEFAULT 0;
    DECLARE v_fine_per_day INT DEFAULT 10;
    DECLARE v_fine_amount DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Return failed — rollback executed.';
    END;

    START TRANSACTION;

    -- Fetch issue details
    SELECT student_id, book_id, copy_id, issue_date, issue_days
    INTO v_student_id, v_book_id, v_copy_id, v_issue_date, v_issue_days
    FROM issued_book 
    WHERE issue_id = p_issue_id 
    FOR UPDATE;

    IF v_student_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Issue ID not found.';
    END IF;

    -- Calculate due date using issue_days
    SET v_due_date = DATE_ADD(v_issue_date, INTERVAL v_issue_days DAY);

    -- Determine actual return date
    IF p_return_date IS NOT NULL THEN
        SET v_actual_return_date = p_return_date;
    ELSE
        SET v_actual_return_date = CURDATE();
    END IF;

    -- Fetch fine per day from system settings
    SELECT CAST(setting_value AS UNSIGNED)
    INTO v_fine_per_day 
    FROM system_settings 
    WHERE setting_key = 'FINE_PER_DAY';

    IF v_fine_per_day IS NULL THEN 
        SET v_fine_per_day = 10; 
    END IF;

    -- Insert into returned_book
    INSERT INTO returned_book (student_id, book_id, copy_id, issue_id, return_date)
    VALUES (v_student_id, v_book_id, v_copy_id, p_issue_id, v_actual_return_date);

    -- Update book_copy status to 'Available'
    UPDATE book_copy
    SET status = 'Available'
    WHERE copy_id = v_copy_id;

    -- Calculate days late
    SET v_days_late = DATEDIFF(v_actual_return_date, v_due_date);

    -- Fine calculation
    IF v_days_late > 0 THEN
        SET v_fine_amount = v_days_late * v_fine_per_day;

        INSERT INTO issue_fine
            (student_id, book_id, issue_id, due_date, return_date, fine_amount, payment_status)
        VALUES
            (v_student_id, v_book_id, p_issue_id, v_due_date, v_actual_return_date, v_fine_amount, 'UNPAID');

        INSERT INTO notifications (student_id, message)
        VALUES (v_student_id, CONCAT('Late return by ', v_days_late, ' days. Fine: ₹', v_fine_amount));
    ELSE
        INSERT INTO notifications (student_id, message)
        VALUES (v_student_id, 'Book returned on time — no fine.');
    END IF;

    COMMIT;

END$$

-- Procedure: pay fine (transactional)
CREATE PROCEDURE pay_fine_proc(
    IN p_fine_id INT,
    IN p_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_error INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = 1;
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment failed. Transaction rolled back.';
    END;

    START TRANSACTION;

    SELECT student_id INTO v_student_id FROM issue_fine WHERE fine_id = p_fine_id FOR UPDATE;
    IF v_student_id IS NULL THEN
        ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fine record not found';
    END IF;

    INSERT INTO fine_payment_records (fine_id, payment_date, amount_paid)
    VALUES (p_fine_id, CURDATE(), p_amount);

    UPDATE issue_fine SET payment_status = 'PAID' WHERE fine_id = p_fine_id;

    INSERT INTO notifications (student_id, message)
    VALUES (v_student_id, CONCAT('Fine ID ', p_fine_id, ' paid. Amount: ₹', p_amount));

    COMMIT;
END$$

-- Procedure: get student details by enrollment
CREATE PROCEDURE get_student_full_details(
    IN p_enrollment_no VARCHAR(50)
)
BEGIN
    SELECT s.*, 
           IFNULL((SELECT COUNT(*) FROM issued_book ib WHERE ib.student_id = s.student_id AND ib.return_date >= CURDATE()),0) AS active_issues,
           IFNULL((SELECT SUM(fine_amount) FROM issue_fine f WHERE f.student_id = s.student_id AND f.payment_status='UNPAID'),0) AS total_unpaid_fines
    FROM student s
    WHERE s.enrollment_no = p_enrollment_no;
END$$

DELIMITER ;

-- ==================================================================
-- EVENTS
-- ==================================================================

-- Cleanup old login logs older than 90 days (runs daily)
DELIMITER $$
DROP EVENT IF EXISTS cleanup_old_logs;
CREATE EVENT cleanup_old_logs
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DELETE FROM login_log WHERE timestamp < DATE_SUB(NOW(), INTERVAL 90 DAY);
END;

-- ==================================================================
-- SAMPLE DATA
-- ==================================================================

INSERT INTO admin (userid, pass, name) VALUES ('admin1','adminpass','Admin One');
INSERT INTO librarian (userid, pass, name, role) VALUES ('lib1','libpass','Lib One','Librarian');

INSERT INTO student (enrollment_no, name, email, phone, pass, address, course, semester)
VALUES
('ENR2025001','Ali Khan','ali@example.com','9998887771','pass123','Street 1','BCA','1'),
('ENR2025002','Mira Patel','mira@example.com','9898989898','pass123','Street 2','BCA','1');

INSERT INTO book_info (title, author, publisher, isbn, book_quantity)
VALUES
('Java Programming','Balaguruswamy','TechPub','ISBN-JAVA-001',5),
('Database Systems','Korth','DBPub','ISBN-DB-002',3);

-- Example: how to set deleted_by before deleting book (application should set these)
-- SET @deleted_by = 1; SET @deleted_role = 'Admin'; DELETE FROM book_info WHERE book_id = 1;

-- ==================================================================
-- End of file
-- ==================================================================
