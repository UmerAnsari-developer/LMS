-- CREATE TABLE requested_book (
--     request_id INT AUTO_INCREMENT PRIMARY KEY,

--     student_id INT NOT NULL,
--     book_id INT NOT NULL,

--     request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

--     request_status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',

--     remarks VARCHAR(255),

--     -- Foreign Keys
--     CONSTRAINT fk_request_student
--         FOREIGN KEY (student_id)
--         REFERENCES student(student_id)
--         ON DELETE CASCADE,

--     CONSTRAINT fk_request_book
--         FOREIGN KEY (book_id)
--         REFERENCES book_info(book_id)
--         ON DELETE CASCADE
-- );
-- CREATE UNIQUE INDEX uniq_student_book_request
-- ON requested_book(student_id, book_id, request_status);

-- delimiter $$
-- CREATE DEFINER=root@localhost TRIGGER trg_after_book_request 
-- AFTER INSERT ON requested_book 
-- FOR EACH ROW BEGIN 
-- DECLARE v_student_name VARCHAR(150); 
-- DECLARE v_book_title VARCHAR(200); 
-- -- Get student name 
-- SELECT name INTO v_student_name 
-- FROM student WHERE student_id = NEW.student_id; 
-- -- Get book title 
-- SELECT title INTO v_book_title 
-- FROM book_info WHERE book_id = NEW.book_id;
--  -- Insert notification 
--  INSERT INTO notifications(student_id, Student_name, message) 
--  VALUES ( NEW.student_id, v_student_name, 
--  CONCAT( 'You requested the book "', v_book_title, '". Status: ', NEW.request_status ) ); 
--  END$$

-- DELIMITER $$

-- CREATE DEFINER=`root`@`localhost`
-- TRIGGER trg_after_request_status_update
-- AFTER UPDATE ON requested_book
-- FOR EACH ROW
-- BEGIN
--     DECLARE v_student_name VARCHAR(150);
--     DECLARE v_book_title VARCHAR(200);

--     -- Run only when status actually changes
--     IF OLD.request_status <> NEW.request_status THEN

--         -- Fetch student name
--         SELECT name INTO v_student_name
--         FROM student
--         WHERE student_id = NEW.student_id;

--         -- Fetch book title
--         SELECT title INTO v_book_title
--         FROM book_info
--         WHERE book_id = NEW.book_id;

--         -- Insert notification
--         INSERT INTO notifications(student_id, Student_name, message)
--         VALUES (
--             NEW.student_id,
--             v_student_name,
--             CONCAT(
--                 'Your request for "', 
--                 v_book_title,
--                 '" has been ',
--                 NEW.request_status
--             )
--         );

--     END IF;
-- END$$

-- DELIMITER ;

 
-- DELIMITER $$

-- CREATE DEFINER=`root`@`localhost`
-- PROCEDURE request_book_sp(
--     IN p_student_id INT,
--     IN p_book_id INT,
--     OUT p_message VARCHAR(255)
-- )
-- proc: BEGIN
--     DECLARE v_unpaid_fines INT;

--     -- Check unpaid fines
--     SELECT COUNT(*) INTO v_unpaid_fines
--     FROM issue_fine
--     WHERE student_id = p_student_id
--       AND payment_status = 'Unpaid';

--     IF v_unpaid_fines > 0 THEN
--         SET p_message = 'You have unpaid fines. Clear dues before requesting books.';
--         LEAVE proc;
--     END IF;

--     -- Insert request
--     INSERT INTO requested_book(student_id, book_id)
--     VALUES (p_student_id, p_book_id);

--     SET p_message = 'Book request submitted successfully';
-- END$$

-- DELIMITER ;
-- ALTER TABLE requested_book
-- ADD COLUMN processed_by ENUM('Admin','Librarian'),
-- ADD COLUMN processed_date DATETIME;

DELIMITER $$

CREATE DEFINER=`root`@`localhost`
PROCEDURE approve_reject_request_sp(
    IN p_request_id INT,
    IN p_action ENUM('Approved','Rejected'),
    IN p_processed_by ENUM('Admin','Librarian'),
    OUT p_message VARCHAR(255)
)
proc: BEGIN
    DECLARE v_current_status VARCHAR(20);

    -- Check if request exists
    SELECT request_status
    INTO v_current_status
    FROM requested_book
    WHERE request_id = p_request_id;

    IF v_current_status IS NULL THEN
        SET p_message = 'Request not found';
        LEAVE proc;
    END IF;

    -- Prevent re-processing
    IF v_current_status <> 'Pending' THEN
        SET p_message = CONCAT(
            'Request already ',
            v_current_status
        );
        LEAVE proc;
    END IF;

    -- Update request status
    UPDATE requested_book
    SET request_status = p_action,
        processed_by = p_processed_by,
        processed_date = NOW()
    WHERE request_id = p_request_id;

    SET p_message = CONCAT(
        'Request ',
        p_action,
        ' successfully'
    );
END$$

DELIMITER ;

