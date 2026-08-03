-- ==================================================================
-- Library Management System - Production Ready Database
-- Target: Microsoft SQL Server
-- Schema: Star Schema + Data Warehousing
-- ==================================================================
-- Author: Production DBA Team
-- Version: 2.0
-- Description: Full production-grade database with operational OLTP
--   tables, data warehouse (star schema), stored procedures,
--   triggers, views, indexes, scalar functions, and scheduled jobs.
--
-- DATA WAREHOUSE ARCHITECTURE: STAR SCHEMA
--   - Flat, denormalized dimension tables (no sub-dimensions)
--   - Fact tables connect directly to dimension tables
--   - SCD Type 2 for slowly changing dimensions (book, student)
--   - Columnstore indexes on fact tables for analytical queries
-- ==================================================================

-- ==================================================================
-- SECTION 1: DATABASE CREATION
-- ==================================================================

-- IMPORTANT: This script must be run by a user with sysadmin or dbcreator role.
-- If your SQL Server does not have C:\SQLData or C:\SQLLog folders,
-- the CREATE DATABASE will fail. We use the server's default path instead.

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'LibraryManagement_System')
BEGIN
    ALTER DATABASE LibraryManagement_System SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LibraryManagement_System;
END
GO

-- Get the default data path for this SQL Server instance
DECLARE @DefaultDataPath NVARCHAR(256);
DECLARE @DefaultLogPath NVARCHAR(256);
DECLARE @DataFilePath NVARCHAR(256);
DECLARE @LogFilePath NVARCHAR(256);
DECLARE @SqlCmd NVARCHAR(MAX);

-- Get default data path from registry (SQL Server standard location)
EXEC master..xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'DefaultData',
    @DefaultDataPath OUTPUT;

-- Get default log path from registry
EXEC master..xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'DefaultLog',
    @DefaultLogPath OUTPUT;

-- Fallback if registry read fails: use master database path
IF @DefaultDataPath IS NULL OR @DefaultDataPath = ''
BEGIN
    SELECT @DefaultDataPath = SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
    FROM master.sys.database_files WHERE file_id = 1;
END

IF @DefaultLogPath IS NULL OR @DefaultLogPath = ''
BEGIN
    SELECT @DefaultLogPath = SUBSTRING(physical_name, 1, CHARINDEX(N'mastlog.ldf', LOWER(physical_name)) - 1)
    FROM master.sys.database_files WHERE file_id = 2;
END

SET @DataFilePath = @DefaultDataPath + N'LibraryManagement_System_Data.mdf';
SET @LogFilePath = @DefaultLogPath + N'LibraryManagement_System_Log.ldf';

-- Print paths for debugging
PRINT 'Data file path: ' + @DataFilePath;
PRINT 'Log file path: ' + @LogFilePath;
GO

-- Create database using dynamic SQL since we need variable paths
DECLARE @DataFilePath NVARCHAR(256);
DECLARE @LogFilePath NVARCHAR(256);
DECLARE @SqlCmd NVARCHAR(MAX);

EXEC master..xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'DefaultData',
    @DataFilePath OUTPUT;

EXEC master..xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'DefaultLog',
    @LogFilePath OUTPUT;

IF @DataFilePath IS NULL OR @DataFilePath = ''
BEGIN
    SELECT @DataFilePath = SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
    FROM master.sys.database_files WHERE file_id = 1;
END

IF @LogFilePath IS NULL OR @LogFilePath = ''
BEGIN
    SELECT @LogFilePath = SUBSTRING(physical_name, 1, CHARINDEX(N'mastlog.ldf', LOWER(physical_name)) - 1)
    FROM master.sys.database_files WHERE file_id = 2;
END

-- Ensure paths end with backslash
IF RIGHT(@DataFilePath, 1) <> '\'
    SET @DataFilePath = @DataFilePath + '\';
IF RIGHT(@LogFilePath, 1) <> '\'
    SET @LogFilePath = @LogFilePath + '\';

-- Build the CREATE DATABASE command dynamically.
-- In dynamic SQL single quotes inside the string must be doubled.
-- A literal N'path' in the inner SQL becomes N''path'' in the outer string.
SET @SqlCmd = N'
CREATE DATABASE LibraryManagement_System
ON PRIMARY
(
    NAME = N''LibraryManagement_System_Data'',
    FILENAME = N''''' + @DataFilePath + N'LibraryManagement_System_Data.mdf'',
    SIZE = 512MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 128MB
)
LOG ON
(
    NAME = N''LibraryManagement_System_Log'',
    FILENAME = N''''' + @LogFilePath + N'LibraryManagement_System_Log.ldf'',
    SIZE = 256MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 64MB
);';

-- PRINT @SqlCmd;  -- Uncomment for debugging
EXEC sp_executesql @SqlCmd;
GO

USE LibraryManagement_System;
GO

ALTER DATABASE LibraryManagement_System SET ENABLE_BROKER;
GO
ALTER DATABASE LibraryManagement_System SET RECOVERY FULL;
GO
ALTER DATABASE LibraryManagement_System SET COMPATIBILITY_LEVEL = 160;
GO

-- ==================================================================
-- SECTION 2: SCHEMAS
-- ==================================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'oltp')
BEGIN
    EXEC('CREATE SCHEMA oltp AUTHORIZATION dbo;');
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw')
BEGIN
    EXEC('CREATE SCHEMA dw AUTHORIZATION dbo;');
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reporting')
BEGIN
    EXEC('CREATE SCHEMA reporting AUTHORIZATION dbo;');
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg AUTHORIZATION dbo;');
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'util')
BEGIN
    EXEC('CREATE SCHEMA util AUTHORIZATION dbo;');
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit AUTHORIZATION dbo;');
END
GO

PRINT 'Schemas created successfully.';
GO

-- ==================================================================
-- SECTION 3: OPERATIONAL TABLES (OLTP)
-- ==================================================================

-- =========================================================
-- 3.1 ROLE & USER TABLES
-- =========================================================

CREATE TABLE oltp.department (
    department_id INT IDENTITY(1,1) PRIMARY KEY,
    department_name NVARCHAR(100) NOT NULL UNIQUE,
    department_code NVARCHAR(20) NULL,
    faculty NVARCHAR(100) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL
);
GO

CREATE TABLE oltp.admin (
    admin_id INT IDENTITY(1,1) PRIMARY KEY,
    userid NVARCHAR(100) NOT NULL UNIQUE,
    pass NVARCHAR(255) NOT NULL,
    name NVARCHAR(150) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    last_login DATETIME2(7) NULL
);
GO

CREATE TABLE oltp.librarian (
    librarian_id INT IDENTITY(1,1) PRIMARY KEY,
    userid NVARCHAR(100) NOT NULL UNIQUE,
    pass NVARCHAR(255) NOT NULL,
    name NVARCHAR(150) NOT NULL,
    role NVARCHAR(50) NOT NULL DEFAULT 'Librarian'
        CHECK (role IN ('Admin', 'Librarian')),
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    last_login DATETIME2(7) NULL
);
GO

CREATE TABLE oltp.student (
    student_id INT IDENTITY(1,1) PRIMARY KEY,
    enrollment_no NVARCHAR(50) NOT NULL UNIQUE,
    name NVARCHAR(150) NOT NULL,
    email NVARCHAR(200) UNIQUE,
    phone NVARCHAR(20) NOT NULL,
    pass NVARCHAR(255) NOT NULL,
    address NVARCHAR(500) NULL,
    course NVARCHAR(100) NULL,
    semester NVARCHAR(20) NULL,
    department_id INT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (status IN ('Active', 'Inactive')),
    restriction_status NVARCHAR(20) NOT NULL DEFAULT 'Normal'
        CHECK (restriction_status IN ('Normal', 'Restricted')),
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    last_login DATETIME2(7) NULL,
    CONSTRAINT FK_student_department
        FOREIGN KEY (department_id) REFERENCES oltp.department(department_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- =========================================================
-- 3.2 BOOK CATALOG TABLES
-- =========================================================

CREATE TABLE oltp.publisher (
    publisher_id INT IDENTITY(1,1) PRIMARY KEY,
    publisher_name NVARCHAR(200) NOT NULL UNIQUE,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE oltp.book_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE oltp.book_info (
    book_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    author NVARCHAR(200) NOT NULL,
    publisher_id INT NULL,
    category_id INT NULL,
    isbn NVARCHAR(50) UNIQUE NULL,
    book_quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10,2) NULL,
    language NVARCHAR(50) NULL,
    edition NVARCHAR(50) NULL,
    year_published INT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_book_publisher
        FOREIGN KEY (publisher_id) REFERENCES oltp.publisher(publisher_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT FK_book_category
        FOREIGN KEY (category_id) REFERENCES oltp.book_category(category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
GO

CREATE TABLE oltp.book_copy (
    copy_id INT IDENTITY(1,1) PRIMARY KEY,
    book_id INT NOT NULL,
    copy_number INT NOT NULL,
    status NVARCHAR(20) NOT NULL DEFAULT 'Available'
        CHECK (status IN ('Available', 'Issued', 'Lost', 'Damaged')),
    condition_rating NVARCHAR(20) NOT NULL DEFAULT 'Good'
        CHECK (condition_rating IN ('New', 'Good', 'Fair', 'Poor')),
    issued_to INT NULL,
    issue_date DATETIME2(7) NULL,
    return_date DATETIME2(7) NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_copy_book
        FOREIGN KEY (book_id) REFERENCES oltp.book_info(book_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_copy_student
        FOREIGN KEY (issued_to) REFERENCES oltp.student(student_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT UQ_book_copy_number
        UNIQUE (book_id, copy_number)
);
GO

-- =========================================================
-- 3.3 TRANSACTION TABLES (OLTP)
-- =========================================================

CREATE TABLE oltp.issued_book (
    issue_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    copy_id INT NOT NULL,
    issue_date DATE NOT NULL,
    issue_days INT NOT NULL DEFAULT 20,
    due_date AS DATEADD(DAY, issue_days, issue_date) PERSISTED,
    is_returned BIT NOT NULL DEFAULT 0,
    issued_by INT NULL,
    issued_role NVARCHAR(50) NULL
        CHECK (issued_role IN ('Admin', 'Librarian')),
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_issued_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_issued_book
        FOREIGN KEY (book_id) REFERENCES oltp.book_info(book_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_issued_copy
        FOREIGN KEY (copy_id) REFERENCES oltp.book_copy(copy_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE oltp.returned_book (
    return_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    copy_id INT NOT NULL,
    issue_id INT NOT NULL,
    return_date DATE NOT NULL,
    returned_by INT NULL,
    returned_role NVARCHAR(50) NULL
        CHECK (returned_role IN ('Admin', 'Librarian')),
    days_late INT NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_return_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_return_book
        FOREIGN KEY (book_id) REFERENCES oltp.book_info(book_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_return_issue
        FOREIGN KEY (issue_id) REFERENCES oltp.issued_book(issue_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE TABLE oltp.requested_book (
    request_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    request_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    request_status NVARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (request_status IN ('Pending', 'Approved', 'Rejected')),
    remarks NVARCHAR(500) NULL,
    processed_by NVARCHAR(50) NULL
        CHECK (processed_by IN ('Admin', 'Librarian')),
    processed_date DATETIME2(7) NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_request_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_request_book
        FOREIGN KEY (book_id) REFERENCES oltp.book_info(book_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT UQ_student_book_request
        UNIQUE (student_id, book_id, request_status)
);
GO

-- =========================================================
-- 3.4 FINE & PAYMENT TABLES
-- =========================================================

CREATE TABLE oltp.issue_fine (
    fine_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    copy_id INT NOT NULL,
    issue_id INT NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NOT NULL,
    days_late INT NOT NULL,
    fine_amount DECIMAL(10,2) NOT NULL,
    fine_per_day DECIMAL(10,2) NOT NULL,
    payment_status NVARCHAR(20) NOT NULL DEFAULT 'UNPAID'
        CHECK (payment_status IN ('UNPAID', 'PAID', 'PARTIALLY_PAID', 'WAIVED')),
    assessed_by INT NULL,
    assessed_date DATETIME2(7) NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_fine_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_fine_book
        FOREIGN KEY (book_id) REFERENCES oltp.book_info(book_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_fine_issue
        FOREIGN KEY (issue_id) REFERENCES oltp.issued_book(issue_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE TABLE oltp.fine_payment_records (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    fine_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_method NVARCHAR(50) NULL
        CHECK (payment_method IN ('Cash', 'Card', 'UPI', 'BankTransfer', 'Cheque', NULL)),
    receipt_number NVARCHAR(100) NULL UNIQUE,
    collected_by INT NULL,
    collected_role NVARCHAR(50) NULL
        CHECK (collected_role IN ('Admin', 'Librarian')),
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL,
    CONSTRAINT FK_payment_fine
        FOREIGN KEY (fine_id) REFERENCES oltp.issue_fine(fine_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- =========================================================
-- 3.5 NOTIFICATION TABLES
-- =========================================================

CREATE TABLE oltp.notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    notification_type NVARCHAR(50) NOT NULL DEFAULT 'General'
        CHECK (notification_type IN ('General', 'Fine', 'Return', 'Restriction', 'Request')),
    is_read BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    read_at DATETIME2(7) NULL,
    CONSTRAINT FK_notification_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

-- =========================================================
-- 3.6 SYSTEM SETTINGS
-- =========================================================

CREATE TABLE oltp.system_settings (
    setting_key NVARCHAR(100) PRIMARY KEY,
    setting_value NVARCHAR(255) NOT NULL,
    description NVARCHAR(500) NULL,
    updated_by INT NULL,
    updated_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

INSERT INTO oltp.system_settings (setting_key, setting_value, description)
VALUES
    ('ISSUE_DAYS', '20', 'Default number of days a book can be issued'),
    ('FINE_PER_DAY', '10', 'Fine amount per day for late return (in currency units)'),
    ('MAX_BOOKS_PER_STUDENT', '4', 'Maximum books a student can have issued simultaneously'),
    ('RESTRICTION_THRESHOLD', '50', 'Cumulative fine threshold for student restriction (in currency units)'),
    ('AUTO_RESTRICT_ON_FINE', 'true', 'Whether to auto-restrict students exceeding fine threshold'),
    ('LOGIN_ATTEMPT_LIMIT', '5', 'Maximum failed login attempts before temporary lockout'),
    ('LOGIN_LOCKOUT_MINUTES', '30', 'Minutes of lockout after exceeding login attempt limit'),
    ('NOTIFICATION_RETENTION_DAYS', '90', 'Days to retain notification records'),
    ('LOG_RETENTION_DAYS', '90', 'Days to retain login/session log records'),
    ('SESSION_TIMEOUT_MINUTES', '480', 'Session timeout in minutes (8 hours default)');
GO

-- =========================================================
-- 3.7 AUDIT & LOG TABLES
-- =========================================================

CREATE TABLE oltp.deleted_book (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    book_id INT NULL,
    copy_id INT NULL,
    title NVARCHAR(255) NULL,
    author NVARCHAR(200) NULL,
    isbn NVARCHAR(50) NULL,
    deleted_by INT NULL,
    deleted_role NVARCHAR(50) NULL
        CHECK (deleted_role IN ('Admin', 'Librarian')),
    reason NVARCHAR(500) NULL,
    deleted_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE oltp.deleted_student (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NULL,
    enrollment_no NVARCHAR(50) NULL,
    name NVARCHAR(150) NULL,
    email NVARCHAR(200) NULL,
    department_name NVARCHAR(100) NULL,
    deleted_by INT NULL,
    role NVARCHAR(50) NULL
        CHECK (role IN ('Admin', 'Librarian')),
    reason NVARCHAR(500) NULL,
    deleted_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE oltp.login_log (
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(100) NULL,
    role NVARCHAR(20) NOT NULL
        CHECK (role IN ('Student', 'Admin', 'Librarian')),
    status NVARCHAR(20) NOT NULL
        CHECK (status IN ('SUCCESS', 'FAILED')),
    ip_address NVARCHAR(50) NULL,
    user_agent NVARCHAR(500) NULL,
    [timestamp] DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE oltp.active_session (
    session_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL
        CHECK (role IN ('Student', 'Admin', 'Librarian')),
    login_time DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    logout_time DATETIME2(7) NULL,
    session_status NVARCHAR(20) NOT NULL DEFAULT 'Active'
        CHECK (session_status IN ('Active', 'Terminated', 'Expired')),
    ip_address NVARCHAR(50) NULL,
    CONSTRAINT CK_active_session_status_logout
        CHECK (
            (session_status = 'Active' AND logout_time IS NULL) OR
            (session_status <> 'Active' AND logout_time IS NOT NULL)
        )
);
GO

CREATE TABLE oltp.session_log (
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(100) NOT NULL,
    role NVARCHAR(20) NOT NULL
        CHECK (role IN ('Student', 'Admin', 'Librarian')),
    login_time DATETIME2(7) NOT NULL,
    logout_time DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    duration_minutes AS DATEDIFF(MINUTE, login_time, logout_time) PERSISTED
);
GO

CREATE TABLE oltp.signup_log (
    signup_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    enrollment_no NVARCHAR(50) NULL,
    message NVARCHAR(500) NOT NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_signup_student
        FOREIGN KEY (student_id) REFERENCES oltp.student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

CREATE TABLE oltp.audit_trail (
    audit_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    table_name NVARCHAR(100) NOT NULL,
    record_id NVARCHAR(100) NULL,
    action_type NVARCHAR(20) NOT NULL
        CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values NVARCHAR(MAX) NULL,
    new_values NVARCHAR(MAX) NULL,
    performed_by INT NULL,
    performed_role NVARCHAR(50) NULL,
    performed_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

PRINT 'Operational tables created successfully.';
GO

-- ==================================================================
-- SECTION 4: DATA WAREHOUSE - STAR SCHEMA
-- ==================================================================
-- STAR SCHEMA ARCHITECTURE:
--   Dimension tables are FLAT and DENORMALIZED (no sub-dimensions).
--   Each fact table connects directly to its dimension tables.
--   The star has the fact at the center, dimensions radiate outward.
--
-- DIMENSIONS (flat, denormalized):
--   - dim_date        (all date attributes in one table)
--   - dim_book        (publisher + category denormalized into one row)
--   - dim_student     (department name denormalized into one row)
--   - dim_staff       (admin + librarian unified, flat)
--   - dim_department  (core business dimension)
--   - dim_book_copy   (book copy details, flat)
--
-- FACTS (grain of a single transaction):
--   - fact_book_issue     (one row per book issue)
--   - fact_book_return    (one row per book return)
--   - fact_fine           (one row per fine assessment)
--   - fact_fine_payment   (one row per payment)
--   - fact_login_audit    (one row per login session)
--   - fact_book_request   (one row per book request)

-- =========================================================
-- 4.1 DIM_DATE (Flat - all date attributes inline)
-- =========================================================

CREATE TABLE dw.dim_date (
    date_key INT NOT NULL PRIMARY KEY,            -- Format: YYYYMMDD
    full_date DATE NOT NULL,
    date_name NVARCHAR(50) NOT NULL,
    day_of_week INT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    day_of_month INT NOT NULL,
    day_of_year INT NOT NULL,
    week_of_month INT NOT NULL,
    week_of_year INT NOT NULL,
    iso_week INT NOT NULL,
    month_number INT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    month_name_short NVARCHAR(10) NOT NULL,
    quarter INT NOT NULL,
    quarter_name NVARCHAR(10) NOT NULL,
    year INT NOT NULL,
    year_month_key INT NOT NULL,                  -- Format: YYYYMM
    year_quarter_key INT NOT NULL,                -- Format: YYYYQ
    is_weekend BIT NOT NULL,
    is_holiday BIT NOT NULL DEFAULT 0,
    holiday_name NVARCHAR(100) NULL,
    fiscal_year INT NOT NULL,
    fiscal_quarter INT NOT NULL,
    fiscal_month INT NOT NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.2 DIM_BOOK (Flat - publisher + category denormalized)
-- =========================================================

CREATE TABLE dw.dim_book (
    book_key INT NOT NULL PRIMARY KEY,
    book_id INT NOT NULL,
    title NVARCHAR(255) NOT NULL,
    author NVARCHAR(200) NOT NULL,
    isbn NVARCHAR(50) NULL,
    publisher_name NVARCHAR(200) NULL,
    category_name NVARCHAR(100) NULL,
    language NVARCHAR(50) NULL,
    edition NVARCHAR(50) NULL,
    year_published INT NULL,
    book_type NVARCHAR(50) NOT NULL DEFAULT 'Physical'
        CHECK (book_type IN ('Physical', 'Digital', 'Hybrid')),
    row_valid_from DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    row_valid_to DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.999',
    is_current BIT NOT NULL DEFAULT 1,
    version_number INT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.3 DIM_BOOK_COPY (Flat)
-- =========================================================

CREATE TABLE dw.dim_book_copy (
    copy_key INT NOT NULL PRIMARY KEY,
    copy_id INT NOT NULL,
    book_key INT NOT NULL,
    copy_number INT NOT NULL,
    book_title NVARCHAR(255) NULL,
    book_author NVARCHAR(200) NULL,
    condition_rating NVARCHAR(20) NULL,
    status NVARCHAR(20) NOT NULL,
    row_valid_from DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    row_valid_to DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.999',
    is_current BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.4 DIM_STUDENT (Flat - department name denormalized)
-- =========================================================

CREATE TABLE dw.dim_student (
    student_key INT NOT NULL PRIMARY KEY,
    student_id INT NOT NULL,
    enrollment_no NVARCHAR(50) NOT NULL,
    full_name NVARCHAR(150) NOT NULL,
    email NVARCHAR(200) NULL,
    phone NVARCHAR(20) NULL,
    department_name NVARCHAR(100) NULL,
    department_code NVARCHAR(20) NULL,
    course NVARCHAR(100) NULL,
    semester NVARCHAR(20) NULL,
    status NVARCHAR(20) NOT NULL,
    restriction_status NVARCHAR(20) NOT NULL,
    registration_date DATE NULL,
    row_valid_from DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    row_valid_to DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.999',
    is_current BIT NOT NULL DEFAULT 1,
    version_number INT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.5 DIM_STAFF (Flat - Admin + Librarian unified)
-- =========================================================

CREATE TABLE dw.dim_staff (
    staff_key INT NOT NULL PRIMARY KEY,
    user_id INT NOT NULL,
    user_type NVARCHAR(20) NOT NULL
        CHECK (user_type IN ('Admin', 'Librarian')),
    userid NVARCHAR(100) NOT NULL,
    full_name NVARCHAR(150) NOT NULL,
    role NVARCHAR(50) NULL,
    row_valid_from DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    row_valid_to DATETIME2(7) NOT NULL DEFAULT '9999-12-31 23:59:59.999',
    is_current BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.6 DIM_DEPARTMENT (Core business dimension)
-- =========================================================

CREATE TABLE dw.dim_department (
    department_key INT NOT NULL PRIMARY KEY,
    department_id INT NOT NULL,
    department_name NVARCHAR(100) NOT NULL,
    department_code NVARCHAR(20) NULL,
    faculty NVARCHAR(100) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- =========================================================
-- 4.7 FACT TABLES (Star Schema - all FK to flat dimensions)
-- =========================================================

-- FACT: Book Issue (grain: one row per book issue transaction)
CREATE TABLE dw.fact_book_issue (
    issue_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    issue_id INT NOT NULL,
    student_key INT NOT NULL,
    book_key INT NOT NULL,
    copy_key INT NOT NULL,
    staff_key INT NULL,
    issue_date_key INT NOT NULL,
    issue_days INT NOT NULL,
    due_date_key INT NOT NULL,
    is_returned BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_issue_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_issue_book
        FOREIGN KEY (book_key) REFERENCES dw.dim_book(book_key),
    CONSTRAINT FK_fact_issue_copy
        FOREIGN KEY (copy_key) REFERENCES dw.dim_book_copy(copy_key),
    CONSTRAINT FK_fact_issue_staff
        FOREIGN KEY (staff_key) REFERENCES dw.dim_staff(staff_key),
    CONSTRAINT FK_fact_issue_date
        FOREIGN KEY (issue_date_key) REFERENCES dw.dim_date(date_key),
    CONSTRAINT FK_fact_issue_due_date
        FOREIGN KEY (due_date_key) REFERENCES dw.dim_date(date_key)
);
GO

-- FACT: Book Return (grain: one row per book return transaction)
CREATE TABLE dw.fact_book_return (
    return_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    return_id INT NOT NULL,
    issue_key BIGINT NULL,
    student_key INT NOT NULL,
    book_key INT NOT NULL,
    copy_key INT NOT NULL,
    staff_key INT NULL,
    return_date_key INT NOT NULL,
    due_date_key INT NOT NULL,
    days_late INT NOT NULL DEFAULT 0,
    fine_incurred DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_return_issue
        FOREIGN KEY (issue_key) REFERENCES dw.fact_book_issue(issue_key),
    CONSTRAINT FK_fact_return_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_return_book
        FOREIGN KEY (book_key) REFERENCES dw.dim_book(book_key),
    CONSTRAINT FK_fact_return_copy
        FOREIGN KEY (copy_key) REFERENCES dw.dim_book_copy(copy_key),
    CONSTRAINT FK_fact_return_staff
        FOREIGN KEY (staff_key) REFERENCES dw.dim_staff(staff_key),
    CONSTRAINT FK_fact_return_date
        FOREIGN KEY (return_date_key) REFERENCES dw.dim_date(date_key),
    CONSTRAINT FK_fact_return_due_date
        FOREIGN KEY (due_date_key) REFERENCES dw.dim_date(date_key)
);
GO

-- FACT: Fine (grain: one row per fine assessment)
CREATE TABLE dw.fact_fine (
    fine_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    fine_id INT NOT NULL,
    issue_key BIGINT NULL,
    return_key BIGINT NULL,
    student_key INT NOT NULL,
    book_key INT NOT NULL,
    copy_key INT NOT NULL,
    fine_date_key INT NOT NULL,
    return_date_key INT NOT NULL,
    days_late INT NOT NULL,
    fine_per_day DECIMAL(10,2) NOT NULL,
    fine_amount DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
    payment_status NVARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_fine_issue
        FOREIGN KEY (issue_key) REFERENCES dw.fact_book_issue(issue_key),
    CONSTRAINT FK_fact_fine_return
        FOREIGN KEY (return_key) REFERENCES dw.fact_book_return(return_key),
    CONSTRAINT FK_fact_fine_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_fine_book
        FOREIGN KEY (book_key) REFERENCES dw.dim_book(book_key),
    CONSTRAINT FK_fact_fine_copy
        FOREIGN KEY (copy_key) REFERENCES dw.dim_book_copy(copy_key),
    CONSTRAINT FK_fact_fine_date
        FOREIGN KEY (fine_date_key) REFERENCES dw.dim_date(date_key),
    CONSTRAINT FK_fact_fine_return_date
        FOREIGN KEY (return_date_key) REFERENCES dw.dim_date(date_key)
);
GO

-- FACT: Fine Payment (grain: one row per payment)
CREATE TABLE dw.fact_fine_payment (
    payment_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    payment_id INT NOT NULL,
    fine_key BIGINT NULL,
    student_key INT NOT NULL,
    staff_key INT NULL,
    payment_date_key INT NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_method NVARCHAR(50) NULL,
    receipt_number NVARCHAR(100) NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_payment_fine
        FOREIGN KEY (fine_key) REFERENCES dw.fact_fine(fine_key),
    CONSTRAINT FK_fact_payment_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_payment_staff
        FOREIGN KEY (staff_key) REFERENCES dw.dim_staff(staff_key),
    CONSTRAINT FK_fact_payment_date
        FOREIGN KEY (payment_date_key) REFERENCES dw.dim_date(date_key)
);
GO

-- FACT: Login Audit (grain: one row per login session)
CREATE TABLE dw.fact_login_audit (
    login_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    student_key INT NULL,
    staff_key INT NULL,
    login_date_key INT NOT NULL,
    login_time DATETIME2(7) NOT NULL,
    logout_time DATETIME2(7) NULL,
    status NVARCHAR(20) NOT NULL,
    role NVARCHAR(20) NOT NULL,
    ip_address NVARCHAR(50) NULL,
    session_duration_minutes INT NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_login_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_login_staff
        FOREIGN KEY (staff_key) REFERENCES dw.dim_staff(staff_key),
    CONSTRAINT FK_fact_login_date
        FOREIGN KEY (login_date_key) REFERENCES dw.dim_date(date_key)
);
GO

-- FACT: Book Request (grain: one row per book request)
CREATE TABLE dw.fact_book_request (
    request_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    request_id INT NOT NULL,
    student_key INT NOT NULL,
    book_key INT NOT NULL,
    request_date_key INT NOT NULL,
    request_status NVARCHAR(20) NOT NULL,
    processed_date_key INT NULL,
    staff_key INT NULL,
    days_to_process INT NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_fact_request_student
        FOREIGN KEY (student_key) REFERENCES dw.dim_student(student_key),
    CONSTRAINT FK_fact_request_book
        FOREIGN KEY (book_key) REFERENCES dw.dim_book(book_key),
    CONSTRAINT FK_fact_request_date
        FOREIGN KEY (request_date_key) REFERENCES dw.dim_date(date_key),
    CONSTRAINT FK_fact_request_processed_date
        FOREIGN KEY (processed_date_key) REFERENCES dw.dim_date(date_key),
    CONSTRAINT FK_fact_request_staff
        FOREIGN KEY (staff_key) REFERENCES dw.dim_staff(staff_key)
);
GO

PRINT 'Data warehouse (Star Schema) tables created successfully.';
GO

-- ==================================================================
-- SECTION 5: STAGING TABLES (ETL)
-- ==================================================================

CREATE TABLE stg.stg_book_info (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    book_id INT NULL,
    title NVARCHAR(255) NULL,
    author NVARCHAR(200) NULL,
    publisher_name NVARCHAR(200) NULL,
    category_name NVARCHAR(100) NULL,
    isbn NVARCHAR(50) NULL,
    book_quantity INT NULL,
    price DECIMAL(10,2) NULL,
    language NVARCHAR(50) NULL,
    edition NVARCHAR(50) NULL,
    year_published INT NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0,
    error_message NVARCHAR(500) NULL
);
GO

CREATE TABLE stg.stg_student (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NULL,
    enrollment_no NVARCHAR(50) NULL,
    name NVARCHAR(150) NULL,
    email NVARCHAR(200) NULL,
    phone NVARCHAR(20) NULL,
    department_name NVARCHAR(100) NULL,
    course NVARCHAR(100) NULL,
    semester NVARCHAR(20) NULL,
    status NVARCHAR(20) NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0,
    error_message NVARCHAR(500) NULL
);
GO

CREATE TABLE stg.stg_issued_book (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    issue_id INT NULL,
    student_id INT NULL,
    book_id INT NULL,
    copy_id INT NULL,
    issue_date DATE NULL,
    issue_days INT NULL,
    is_returned BIT NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE stg.stg_returned_book (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    return_id INT NULL,
    student_id INT NULL,
    book_id INT NULL,
    copy_id INT NULL,
    issue_id INT NULL,
    return_date DATE NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE stg.stg_fine (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    fine_id INT NULL,
    student_id INT NULL,
    book_id INT NULL,
    copy_id INT NULL,
    issue_id INT NULL,
    due_date DATE NULL,
    return_date DATE NULL,
    fine_amount DECIMAL(10,2) NULL,
    payment_status NVARCHAR(20) NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE stg.stg_login_log (
    stg_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(100) NULL,
    role NVARCHAR(20) NULL,
    status NVARCHAR(20) NULL,
    [timestamp] DATETIME2(7) NULL,
    load_date DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    is_processed BIT NOT NULL DEFAULT 0
);
GO

PRINT 'Staging tables created successfully.';
GO

-- ==================================================================
-- SECTION 6: INDEXES
-- ==================================================================

-- =========================================================
-- 6.1 OLTP TABLES - INDEXES
-- =========================================================

-- Student indexes
CREATE INDEX IX_student_enrollment ON oltp.student(enrollment_no);
CREATE INDEX IX_student_email ON oltp.student(email);
CREATE INDEX IX_student_name ON oltp.student(name);
CREATE INDEX IX_student_department ON oltp.student(department_id);
CREATE INDEX IX_student_status ON oltp.student(status);
CREATE INDEX IX_student_restriction ON oltp.student(restriction_status);
CREATE NONCLUSTERED INDEX IX_student_active ON oltp.student(is_active) WHERE is_active = 1;
GO

-- Book info indexes
CREATE INDEX IX_book_title ON oltp.book_info(title);
CREATE INDEX IX_book_author ON oltp.book_info(author);
CREATE INDEX IX_book_isbn ON oltp.book_info(isbn);
CREATE INDEX IX_book_publisher ON oltp.book_info(publisher_id);
CREATE INDEX IX_book_category ON oltp.book_info(category_id);
CREATE NONCLUSTERED INDEX IX_book_active ON oltp.book_info(is_active) WHERE is_active = 1;
GO

-- Book copy indexes
CREATE INDEX IX_copy_book ON oltp.book_copy(book_id);
CREATE INDEX IX_copy_status ON oltp.book_copy(status);
CREATE INDEX IX_copy_issued_to ON oltp.book_copy(issued_to);
CREATE NONCLUSTERED INDEX IX_copy_available ON oltp.book_copy(book_id, status)
    INCLUDE (copy_id, copy_number) WHERE status = 'Available';
GO

-- Issued book indexes
CREATE INDEX IX_issued_student ON oltp.issued_book(student_id);
CREATE INDEX IX_issued_book ON oltp.issued_book(book_id);
CREATE INDEX IX_issued_copy ON oltp.issued_book(copy_id);
CREATE INDEX IX_issued_date ON oltp.issued_book(issue_date);
CREATE INDEX IX_issued_due ON oltp.issued_book(due_date);
CREATE NONCLUSTERED INDEX IX_issued_active ON oltp.issued_book(student_id, is_returned)
    INCLUDE (book_id, copy_id, issue_date, due_date) WHERE is_returned = 0;
GO

-- Returned book indexes
CREATE INDEX IX_return_student ON oltp.returned_book(student_id);
CREATE INDEX IX_return_book ON oltp.returned_book(book_id);
CREATE INDEX IX_return_copy ON oltp.returned_book(copy_id);
CREATE INDEX IX_return_issue ON oltp.returned_book(issue_id);
CREATE INDEX IX_return_date ON oltp.returned_book(return_date);
GO

-- Requested book indexes
CREATE INDEX IX_request_student ON oltp.requested_book(student_id);
CREATE INDEX IX_request_book ON oltp.requested_book(book_id);
CREATE INDEX IX_request_status ON oltp.requested_book(request_status);
GO

-- Fine indexes
CREATE INDEX IX_fine_student ON oltp.issue_fine(student_id);
CREATE INDEX IX_fine_book ON oltp.issue_fine(book_id);
CREATE INDEX IX_fine_issue ON oltp.issue_fine(issue_id);
CREATE INDEX IX_fine_status ON oltp.issue_fine(payment_status);
CREATE NONCLUSTERED INDEX IX_fine_unpaid ON oltp.issue_fine(student_id, payment_status)
    INCLUDE (fine_amount, due_date) WHERE payment_status = 'UNPAID';
GO

-- Payment indexes
CREATE INDEX IX_payment_fine ON oltp.fine_payment_records(fine_id);
CREATE INDEX IX_payment_date ON oltp.fine_payment_records(payment_date);
GO

-- Notification indexes
CREATE INDEX IX_notification_student ON oltp.notifications(student_id);
CREATE INDEX IX_notification_read ON oltp.notifications(is_read);
CREATE NONCLUSTERED INDEX IX_notification_unread ON oltp.notifications(student_id, is_read)
    WHERE is_read = 0;
GO

-- Login log indexes
CREATE INDEX IX_login_user ON oltp.login_log(user_id, role);
CREATE INDEX IX_login_timestamp ON oltp.login_log([timestamp]);
CREATE INDEX IX_login_status ON oltp.login_log(status);
GO

-- Active session indexes
CREATE INDEX IX_active_user ON oltp.active_session(user_id, role);
CREATE INDEX IX_active_status ON oltp.active_session(session_status);
CREATE NONCLUSTERED INDEX IX_active_active_sessions ON oltp.active_session(session_status)
    INCLUDE (user_id, role, login_time) WHERE session_status = 'Active';
GO

-- Audit indexes
CREATE INDEX IX_audit_table ON oltp.audit_trail(table_name);
CREATE INDEX IX_audit_performed_at ON oltp.audit_trail(performed_at);
CREATE INDEX IX_audit_action ON oltp.audit_trail(action_type);
GO

-- =========================================================
-- 6.2 DATA WAREHOUSE (STAR SCHEMA) - INDEXES
-- =========================================================

-- Dimension indexes
CREATE INDEX IX_dw_date_full ON dw.dim_date(full_date);
CREATE INDEX IX_dw_date_month ON dw.dim_date(year, month_number);
CREATE INDEX IX_dw_date_quarter ON dw.dim_date(year, quarter);
CREATE INDEX IX_dw_book_title ON dw.dim_book(title);
CREATE INDEX IX_dw_book_author ON dw.dim_book(author);
CREATE INDEX IX_dw_book_publisher ON dw.dim_book(publisher_name);
CREATE INDEX IX_dw_book_category ON dw.dim_book(category_name);
CREATE INDEX IX_dw_book_current ON dw.dim_book(is_current) WHERE is_current = 1;
CREATE INDEX IX_dw_copy_book ON dw.dim_book_copy(book_key);
CREATE INDEX IX_dw_copy_current ON dw.dim_book_copy(is_current) WHERE is_current = 1;
CREATE INDEX IX_dw_student_enrollment ON dw.dim_student(enrollment_no);
CREATE INDEX IX_dw_student_dept ON dw.dim_student(department_name);
CREATE INDEX IX_dw_student_current ON dw.dim_student(is_current) WHERE is_current = 1;
CREATE INDEX IX_dw_staff_current ON dw.dim_staff(is_current) WHERE is_current = 1;
CREATE INDEX IX_dw_staff_userid ON dw.dim_staff(userid);
CREATE INDEX IX_dw_dept_name ON dw.dim_department(department_name);
GO

-- Fact table indexes
CREATE INDEX IX_fact_issue_student ON dw.fact_book_issue(student_key);
CREATE INDEX IX_fact_issue_book ON dw.fact_book_issue(book_key);
CREATE INDEX IX_fact_issue_date ON dw.fact_book_issue(issue_date_key);
CREATE NONCLUSTERED INDEX IX_fact_issue_unreturned ON dw.fact_book_issue(is_returned)
    WHERE is_returned = 0;
GO

CREATE INDEX IX_fact_return_student ON dw.fact_book_return(student_key);
CREATE INDEX IX_fact_return_book ON dw.fact_book_return(book_key);
CREATE INDEX IX_fact_return_date ON dw.fact_book_return(return_date_key);
GO

CREATE INDEX IX_fact_fine_student ON dw.fact_fine(student_key);
CREATE INDEX IX_fact_fine_date ON dw.fact_fine(fine_date_key);
CREATE INDEX IX_fact_fine_status ON dw.fact_fine(payment_status);
CREATE NONCLUSTERED INDEX IX_fact_fine_unpaid ON dw.fact_fine(student_key, payment_status)
    INCLUDE (fine_amount) WHERE payment_status = 'UNPAID';
GO

CREATE INDEX IX_fact_payment_student ON dw.fact_fine_payment(student_key);
CREATE INDEX IX_fact_payment_date ON dw.fact_fine_payment(payment_date_key);
GO

CREATE INDEX IX_fact_login_date ON dw.fact_login_audit(login_date_key);
CREATE INDEX IX_fact_login_status ON dw.fact_login_audit(status);
GO

CREATE INDEX IX_fact_request_student ON dw.fact_book_request(student_key);
CREATE INDEX IX_fact_request_date ON dw.fact_book_request(request_date_key);
CREATE INDEX IX_fact_request_status ON dw.fact_book_request(request_status);
GO

-- Columnstore indexes for analytical queries on fact tables
CREATE NONCLUSTERED COLUMNSTORE INDEX CCI_fact_book_issue
ON dw.fact_book_issue (issue_id, student_key, book_key, issue_date_key, due_date_key, issue_days);
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX CCI_fact_fine
ON dw.fact_fine (fine_id, student_key, book_key, fine_date_key, fine_amount, payment_status);
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX CCI_fact_book_return
ON dw.fact_book_return (return_id, student_key, book_key, return_date_key, days_late);
GO

PRINT 'Indexes created successfully.';
GO

-- ==================================================================
-- SECTION 7: DEFAULT CONSTRAINTS & CHECK CONSTRAINTS
-- ==================================================================

-- DF_book_qty already defined inline in CREATE TABLE oltp.book_info
ALTER TABLE oltp.book_copy ADD CONSTRAINT DF_copy_status DEFAULT 'Available' FOR status;
ALTER TABLE oltp.issued_book ADD CONSTRAINT DF_issue_days DEFAULT 20 FOR issue_days;
ALTER TABLE oltp.issue_fine ADD CONSTRAINT DF_fine_status DEFAULT 'UNPAID' FOR payment_status;

PRINT 'Default constraints applied.';
GO

-- ==================================================================
-- SECTION 8: SCALAR FUNCTIONS
-- ==================================================================

CREATE OR ALTER FUNCTION util.fn_calculate_fine (
    @issue_date DATE,
    @return_date DATE,
    @issue_days INT,
    @fine_per_day DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @due_date DATE = DATEADD(DAY, @issue_days, @issue_date);
    DECLARE @days_late INT = DATEDIFF(DAY, @due_date, @return_date);
    IF @days_late > 0
        RETURN @days_late * @fine_per_day;
    RETURN 0;
END;
GO

CREATE OR ALTER FUNCTION util.fn_student_unpaid_fines (
    @student_id INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2);
    SELECT @total = ISNULL(SUM(fine_amount), 0)
    FROM oltp.issue_fine
    WHERE student_id = @student_id AND payment_status = 'UNPAID';
    RETURN @total;
END;
GO

CREATE OR ALTER FUNCTION util.fn_student_active_issues (
    @student_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM oltp.issued_book
    WHERE student_id = @student_id AND is_returned = 0;
    RETURN @count;
END;
GO

CREATE OR ALTER FUNCTION util.fn_book_available_copies (
    @book_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM oltp.book_copy
    WHERE book_id = @book_id AND status = 'Available';
    RETURN @count;
END;
GO

CREATE OR ALTER FUNCTION util.fn_book_total_quantity (
    @book_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM oltp.book_copy
    WHERE book_id = @book_id;
    RETURN @count;
END;
GO

CREATE OR ALTER FUNCTION util.fn_get_setting (
    @key NVARCHAR(100)
)
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @val NVARCHAR(255);
    SELECT @val = setting_value
    FROM oltp.system_settings
    WHERE setting_key = @key;
    RETURN @val;
END;
GO

CREATE OR ALTER FUNCTION util.fn_get_setting_int (
    @key NVARCHAR(100)
)
RETURNS INT
AS
BEGIN
    DECLARE @val INT;
    SELECT @val = TRY_CAST(setting_value AS INT)
    FROM oltp.system_settings
    WHERE setting_key = @key;
    RETURN ISNULL(@val, 0);
END;
GO

CREATE OR ALTER FUNCTION util.fn_get_setting_decimal (
    @key NVARCHAR(100)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @val DECIMAL(10,2);
    SELECT @val = TRY_CAST(setting_value AS DECIMAL(10,2))
    FROM oltp.system_settings
    WHERE setting_key = @key;
    RETURN ISNULL(@val, 0);
END;
GO

CREATE OR ALTER FUNCTION util.fn_is_student_restricted (
    @student_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @restricted BIT;
    SELECT @restricted = CASE WHEN restriction_status = 'Restricted' THEN 1 ELSE 0 END
    FROM oltp.student WHERE student_id = @student_id;
    RETURN ISNULL(@restricted, 0);
END;
GO

CREATE OR ALTER FUNCTION util.fn_generate_receipt_number (
    @payment_id INT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN 'RCPT-' + FORMAT(SYSDATETIME(), 'yyyyMMdd') + '-' + RIGHT('000000' + CAST(@payment_id AS NVARCHAR(10)), 8);
END;
GO

CREATE OR ALTER FUNCTION util.fn_course_semester (
    @course NVARCHAR(100),
    @semester NVARCHAR(20)
)
RETURNS NVARCHAR(130)
AS
BEGIN
    IF @course IS NULL AND @semester IS NULL
        RETURN 'N/A';
    IF @course IS NULL
        RETURN 'Sem ' + ISNULL(@semester, '');
    IF @semester IS NULL
        RETURN @course;
    RETURN @course + ' / Sem ' + @semester;
END;
GO

PRINT 'Scalar functions created successfully.';
GO

-- ==================================================================
-- SECTION 9: TABLE-VALUED FUNCTIONS
-- ==================================================================

CREATE OR ALTER FUNCTION oltp.fn_get_overdue_books (
    @student_id INT
)
RETURNS TABLE
AS
RETURN (
    SELECT
        ib.issue_id,
        ib.book_id,
        bi.title,
        bi.author,
        ib.issue_date,
        ib.due_date,
        DATEDIFF(DAY, ib.due_date, CAST(GETDATE() AS DATE)) AS days_overdue
    FROM oltp.issued_book ib
    INNER JOIN oltp.book_info bi ON ib.book_id = bi.book_id
    WHERE ib.student_id = @student_id
      AND ib.is_returned = 0
      AND CAST(GETDATE() AS DATE) > ib.due_date
);
GO

CREATE OR ALTER FUNCTION oltp.fn_student_summary (
    @student_id INT
)
RETURNS TABLE
AS
RETURN (
    SELECT
        s.student_id,
        s.enrollment_no,
        s.name,
        s.email,
        s.phone,
        s.address,
        s.course,
        s.semester,
        d.department_name,
        util.fn_student_active_issues(s.student_id) AS active_issues,
        util.fn_student_unpaid_fines(s.student_id) AS total_unpaid_fines,
        s.restriction_status,
        s.status,
        util.fn_course_semester(s.course, s.semester) AS course_semester
    FROM oltp.student s
    LEFT JOIN oltp.department d ON s.department_id = d.department_id
    WHERE s.student_id = @student_id
);
GO

PRINT 'Table-valued functions created successfully.';
GO

-- ==================================================================
-- SECTION 10: STORED PROCEDURES
-- ==================================================================

-- =========================================================
-- 10.1 AUTHENTICATION PROCEDURES (Java contract: 3 params)
-- =========================================================

-- Student Login
CREATE OR ALTER PROCEDURE oltp.student_login_sp
    @p_email NVARCHAR(255),
    @p_pass NVARCHAR(255),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_student_id INT = NULL;
    DECLARE @v_status NVARCHAR(20);
    DECLARE @v_pass NVARCHAR(255);
    DECLARE @v_restriction NVARCHAR(20);

    SELECT @v_student_id = student_id,
           @v_pass = pass,
           @v_status = status,
           @v_restriction = restriction_status
    FROM oltp.student
    WHERE email = @p_email AND is_active = 1;

    IF @v_student_id IS NULL
    BEGIN
        SET @p_message = 'Invalid Credentials!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES (@p_email, 'Student', 'FAILED');
        RETURN;
    END

    IF @v_pass <> LTRIM(RTRIM(@p_pass))
    BEGIN
        SET @p_message = 'Invalid password!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES (@p_email, 'Student', 'FAILED');
        RETURN;
    END

    IF @v_status = 'Inactive'
    BEGIN
        SET @p_message = 'Your account is inactive. Contact Admin.';
        RETURN;
    END

    IF @v_restriction = 'Restricted'
    BEGIN
        SET @p_message = 'Your account is RESTRICTED. Please contact Admin.';
        RETURN;
    END

    INSERT INTO oltp.login_log (user_id, role, status)
    VALUES (@p_email, 'Student', 'SUCCESS');

    INSERT INTO oltp.active_session (user_id, role, login_time, session_status)
    VALUES (@p_email, 'Student', GETDATE(), 'Active');

    UPDATE oltp.student SET last_login = GETDATE() WHERE student_id = @v_student_id;

    SET @p_message = 'Student Login Successful.';
END;
GO

-- Admin Login
CREATE OR ALTER PROCEDURE oltp.admin_login
    @p_userid NVARCHAR(100),
    @p_pass NVARCHAR(255),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_admin_id INT;
    DECLARE @v_pass NVARCHAR(255);

    SELECT @v_admin_id = admin_id, @v_pass = pass
    FROM oltp.admin
    WHERE userid = @p_userid AND is_active = 1;

    IF @v_admin_id IS NULL
    BEGIN
        SET @p_message = 'User_id did not found!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES ('0', 'Admin', 'FAILED');
        RETURN;
    END

    IF @v_pass <> LTRIM(RTRIM(@p_pass))
    BEGIN
        SET @p_message = 'Invalid password!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES (CAST(@v_admin_id AS NVARCHAR(10)), 'Admin', 'FAILED');
        RETURN;
    END

    INSERT INTO oltp.login_log (user_id, role, status)
    VALUES (CAST(@v_admin_id AS NVARCHAR(10)), 'Admin', 'SUCCESS');

    INSERT INTO oltp.active_session (user_id, role, login_time, session_status)
    VALUES (CAST(@v_admin_id AS NVARCHAR(10)), 'Admin', GETDATE(), 'Active');

    UPDATE oltp.admin SET last_login = GETDATE() WHERE admin_id = @v_admin_id;

    SET @p_message = 'Admin Login Successful.';
END;
GO

-- Librarian Login
CREATE OR ALTER PROCEDURE oltp.librarian_login
    @p_userid NVARCHAR(100),
    @p_pass NVARCHAR(255),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_lib_id INT;
    DECLARE @v_pass NVARCHAR(255);

    SELECT @v_lib_id = librarian_id, @v_pass = pass
    FROM oltp.librarian
    WHERE userid = @p_userid AND is_active = 1;

    IF @v_lib_id IS NULL
    BEGIN
        SET @p_message = 'User_id did not found!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES ('0', 'Librarian', 'FAILED');
        RETURN;
    END

    IF @v_pass <> LTRIM(RTRIM(@p_pass))
    BEGIN
        SET @p_message = 'Invalid password!!!';
        INSERT INTO oltp.login_log (user_id, role, status)
        VALUES (CAST(@v_lib_id AS NVARCHAR(10)), 'Librarian', 'FAILED');
        RETURN;
    END

    INSERT INTO oltp.login_log (user_id, role, status)
    VALUES (CAST(@v_lib_id AS NVARCHAR(10)), 'Librarian', 'SUCCESS');

    INSERT INTO oltp.active_session (user_id, role, login_time, session_status)
    VALUES (CAST(@v_lib_id AS NVARCHAR(10)), 'Librarian', GETDATE(), 'Active');

    UPDATE oltp.librarian SET last_login = GETDATE() WHERE librarian_id = @v_lib_id;

    SET @p_message = 'Librarian Login Successful.';
END;
GO

-- =========================================================
-- 10.2 SESSION / LOGOUT PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.record_user_logout
    @role NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @user_id NVARCHAR(100);

    SELECT @user_id = user_id
    FROM oltp.active_session
    WHERE role = @role AND session_status = 'Active'
    ORDER BY login_time DESC;

    IF @user_id IS NOT NULL
    BEGIN
        UPDATE oltp.active_session
        SET session_status = 'Terminated',
            logout_time = GETDATE()
        WHERE user_id = @user_id AND role = @role AND session_status = 'Active';

        INSERT INTO oltp.session_log (user_id, role, login_time, logout_time)
        SELECT user_id, role, login_time, GETDATE()
        FROM oltp.active_session
        WHERE user_id = @user_id AND role = @role AND session_status = 'Terminated';
    END
END;
GO

-- =========================================================
-- 10.3 STUDENT SIGNUP PROCEDURE (matches Java: 9 params)
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.student_sign_up
    @p_enrollment_no NVARCHAR(50),
    @p_name NVARCHAR(150),
    @p_email NVARCHAR(200),
    @p_phone NVARCHAR(20),
    @p_pass NVARCHAR(255),
    @p_address NVARCHAR(500),
    @p_course NVARCHAR(100),
    @p_semester NVARCHAR(20),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM oltp.student WHERE enrollment_no = @p_enrollment_no)
    BEGIN
        SET @p_message = 'Enrollment already exists';
        RETURN;
    END

    IF @p_email IS NOT NULL AND EXISTS (SELECT 1 FROM oltp.student WHERE email = @p_email)
    BEGIN
        SET @p_message = 'Email already exists';
        RETURN;
    END

    INSERT INTO oltp.student (
        enrollment_no, name, email, phone, pass,
        address, course, semester, status, restriction_status, is_active
    )
    VALUES (
        @p_enrollment_no, @p_name, @p_email, @p_phone, @p_pass,
        @p_address, @p_course, @p_semester, 'Active', 'Normal', 1
    );

    SET @p_message = 'Student registered successfully';
END;
GO

-- =========================================================
-- 10.4 STUDENT INFO PROCEDURES (matches Java contracts)
-- =========================================================

-- Get student full details by enrollment (IssueBookPanel contract)
CREATE OR ALTER PROCEDURE oltp.get_student_full_details
    @p_enrollment_no NVARCHAR(50),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_student_id INT;

    SELECT @v_student_id = student_id FROM oltp.student
    WHERE enrollment_no = @p_enrollment_no AND is_active = 1;

    IF @v_student_id IS NULL
    BEGIN
        SET @p_message = 'Student not found with this enrollment number.';
        RETURN;
    END

    SELECT
        s.name,
        s.email,
        ISNULL(d.department_name, 'N/A') AS department_name,
        ISNULL(s.semester, 'N/A') AS semester,
        ISNULL(s.phone, 'N/A') AS contact
    FROM oltp.student s
    LEFT JOIN oltp.department d ON s.department_id = d.department_id
    WHERE s.student_id = @v_student_id;

    SET @p_message = 'OK';
END;
GO

-- Get logged-in student full info (StudentPanel contract: 2 result sets)
CREATE OR ALTER PROCEDURE oltp.get_logged_in_student_full_info
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_user_id NVARCHAR(100);

    SELECT TOP 1 @v_user_id = user_id
    FROM oltp.active_session
    WHERE role = 'Student' AND session_status = 'Active'
    ORDER BY login_time DESC;

    IF @v_user_id IS NULL
        SET @v_user_id = '0';

    -- RESULT SET 1: Student details
    SELECT
        s.student_id,
        s.enrollment_no,
        s.name,
        s.email,
        s.phone,
        s.address,
        s.pass AS password,
        util.fn_course_semester(s.course, s.semester) AS course_semester
    FROM oltp.student s
    WHERE s.student_id = TRY_CAST(@v_user_id AS INT)
       OR s.email = @v_user_id;

    -- RESULT SET 2: Issued book history
    SELECT
        ib.book_id,
        bi.title,
        ib.issue_date,
        ib.due_date AS return_date
    FROM oltp.issued_book ib
    INNER JOIN oltp.book_info bi ON ib.book_id = bi.book_id
    WHERE ib.student_id = TRY_CAST(@v_user_id AS INT)
       OR ib.student_id = (
            SELECT student_id FROM oltp.student
            WHERE email = @v_user_id
        );
END;
GO

-- =========================================================
-- 10.5 BOOK ISSUE & RETURN PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.issue_book_sp
    @p_student_id INT,
    @p_book_id INT,
    @p_issue_date DATE,
    @p_issue_days INT,
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_restriction NVARCHAR(20);
    DECLARE @v_quantity INT;
    DECLARE @v_copy_id INT;
    DECLARE @v_active_issues INT;
    DECLARE @v_max_books INT;

    SELECT @v_restriction = restriction_status
    FROM oltp.student WHERE student_id = @p_student_id;

    IF @v_restriction = 'Restricted'
    BEGIN
        SET @p_message = 'This student is RESTRICTED. Book issuing is not allowed.';
        RETURN;
    END

    SET @v_max_books = util.fn_get_setting_int('MAX_BOOKS_PER_STUDENT');
    SET @v_active_issues = util.fn_student_active_issues(@p_student_id);

    IF @v_active_issues >= @v_max_books
    BEGIN
        SET @p_message = 'Maximum book issue per student is ' + CAST(@v_max_books AS NVARCHAR(5)) + '.';
        RETURN;
    END

    SELECT @v_quantity = COUNT(*)
    FROM oltp.book_copy
    WHERE book_id = @p_book_id AND status = 'Available';

    IF @v_quantity <= 0
    BEGIN
        SET @p_message = 'Book is currently unavailable.';
        RETURN;
    END

    SELECT TOP 1 @v_copy_id = copy_id
    FROM oltp.book_copy
    WHERE book_id = @p_book_id AND status = 'Available';

    INSERT INTO oltp.issued_book (student_id, book_id, copy_id, issue_date, issue_days)
    VALUES (@p_student_id, @p_book_id, @v_copy_id, @p_issue_date, ISNULL(@p_issue_days, 20));

    UPDATE oltp.book_copy
    SET status = 'Issued',
        issued_to = @p_student_id,
        issue_date = GETDATE()
    WHERE copy_id = @v_copy_id;

    SET @p_message = 'Book issued successfully.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.return_book_proc
    @p_issue_id INT,
    @p_return_date DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_student_id INT;
    DECLARE @v_book_id INT;
    DECLARE @v_copy_id INT;
    DECLARE @v_issue_date DATE;
    DECLARE @v_issue_days INT;
    DECLARE @v_due_date DATE;
    DECLARE @v_actual_return_date DATE;
    DECLARE @v_days_late INT = 0;
    DECLARE @v_fine_per_day DECIMAL(10,2) = 10;
    DECLARE @v_fine_amount DECIMAL(10,2) = 0;

    SELECT @v_student_id = student_id,
           @v_book_id = book_id,
           @v_copy_id = copy_id,
           @v_issue_date = issue_date,
           @v_issue_days = issue_days
    FROM oltp.issued_book
    WHERE issue_id = @p_issue_id;

    IF @v_student_id IS NULL
    BEGIN
        THROW 50000, 'Issue ID not found.', 1;
    END

    SET @v_due_date = DATEADD(DAY, @v_issue_days, @v_issue_date);
    SET @v_actual_return_date = ISNULL(@p_return_date, CAST(GETDATE() AS DATE));

    SELECT @v_fine_per_day = TRY_CAST(setting_value AS DECIMAL(10,2))
    FROM oltp.system_settings WHERE setting_key = 'FINE_PER_DAY';
    IF @v_fine_per_day IS NULL SET @v_fine_per_day = 10;

    INSERT INTO oltp.returned_book (student_id, book_id, copy_id, issue_id, return_date)
    VALUES (@v_student_id, @v_book_id, @v_copy_id, @p_issue_id, @v_actual_return_date);

    UPDATE oltp.book_copy
    SET status = 'Available',
        issued_to = NULL,
        issue_date = NULL,
        return_date = GETDATE()
    WHERE copy_id = @v_copy_id;

    UPDATE oltp.issued_book
    SET is_returned = 1
    WHERE issue_id = @p_issue_id;

    SET @v_days_late = DATEDIFF(DAY, @v_due_date, @v_actual_return_date);

    UPDATE oltp.returned_book SET days_late = @v_days_late
    WHERE issue_id = @p_issue_id;

    IF @v_days_late > 0
    BEGIN
        SET @v_fine_amount = @v_days_late * @v_fine_per_day;

        INSERT INTO oltp.issue_fine (
            student_id, book_id, copy_id, issue_id,
            due_date, return_date, days_late,
            fine_amount, fine_per_day, payment_status
        )
        VALUES (
            @v_student_id, @v_book_id, @v_copy_id, @p_issue_id,
            @v_due_date, @v_actual_return_date, @v_days_late,
            @v_fine_amount, @v_fine_per_day, 'UNPAID'
        );

        INSERT INTO oltp.notifications (student_id, message, notification_type)
        VALUES (@v_student_id,
            'Late return by ' + CAST(@v_days_late AS NVARCHAR(10)) + ' days. Fine: ' + CAST(@v_fine_amount AS NVARCHAR(20)),
            'Fine');

        DECLARE @v_total_fines DECIMAL(10,2);
        DECLARE @v_threshold INT;
        SET @v_total_fines = util.fn_student_unpaid_fines(@v_student_id);
        SET @v_threshold = util.fn_get_setting_int('RESTRICTION_THRESHOLD');

        IF EXISTS (SELECT 1 FROM oltp.system_settings WHERE setting_key = 'AUTO_RESTRICT_ON_FINE' AND setting_value = 'true')
        BEGIN
            IF @v_total_fines >= @v_threshold
            BEGIN
                UPDATE oltp.student SET restriction_status = 'Restricted'
                WHERE student_id = @v_student_id;

                INSERT INTO oltp.notifications (student_id, message, notification_type)
                VALUES (@v_student_id,
                    'Your account has been RESTRICTED due to unpaid fines exceeding threshold.',
                    'Restriction');
            END
        END
    END
    ELSE
    BEGIN
        INSERT INTO oltp.notifications (student_id, message, notification_type)
        VALUES (@v_student_id, 'Book returned on time — no fine.', 'Return');
    END
END;
GO

-- =========================================================
-- 10.6 FINE PAYMENT PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.pay_fine_proc
    @p_fine_id INT,
    @p_amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_student_id INT;
    DECLARE @v_fine_amount DECIMAL(10,2);
    DECLARE @v_payment_status NVARCHAR(20);

    SELECT @v_student_id = student_id,
           @v_fine_amount = fine_amount,
           @v_payment_status = payment_status
    FROM oltp.issue_fine
    WHERE fine_id = @p_fine_id;

    IF @v_student_id IS NULL
    BEGIN
        THROW 50000, 'Fine record not found', 1;
    END

    IF @v_payment_status = 'PAID'
    BEGIN
        THROW 50000, 'Fine already paid', 1;
    END

    INSERT INTO oltp.fine_payment_records (fine_id, payment_date, amount_paid)
    VALUES (@p_fine_id, CAST(GETDATE() AS DATE), @p_amount);

    IF @p_amount >= @v_fine_amount
        UPDATE oltp.issue_fine SET payment_status = 'PAID' WHERE fine_id = @p_fine_id;
    ELSE
        UPDATE oltp.issue_fine SET payment_status = 'PARTIALLY_PAID' WHERE fine_id = @p_fine_id;

    INSERT INTO oltp.notifications (student_id, message, notification_type)
    VALUES (@v_student_id,
        'Fine ID ' + CAST(@p_fine_id AS NVARCHAR(10)) + ' paid. Amount: ' + CAST(@p_amount AS NVARCHAR(20)),
        'Fine');

    DECLARE @v_remaining DECIMAL(10,2);
    SET @v_remaining = util.fn_student_unpaid_fines(@v_student_id);
    DECLARE @v_threshold INT = util.fn_get_setting_int('RESTRICTION_THRESHOLD');

    IF @v_remaining < @v_threshold AND
       EXISTS (SELECT 1 FROM oltp.student WHERE student_id = @v_student_id AND restriction_status = 'Restricted')
    BEGIN
        UPDATE oltp.student SET restriction_status = 'Normal'
        WHERE student_id = @v_student_id;

        INSERT INTO oltp.notifications (student_id, message, notification_type)
        VALUES (@v_student_id,
            'Your account restriction has been lifted. Fines are now below threshold.',
            'Restriction');
    END
END;
GO

-- =========================================================
-- 10.7 BOOK REQUEST PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.request_book_sp
    @p_student_id INT,
    @p_book_id INT,
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_unpaid_fines INT;

    SELECT @v_unpaid_fines = COUNT(*)
    FROM oltp.issue_fine
    WHERE student_id = @p_student_id AND payment_status = 'UNPAID';

    IF @v_unpaid_fines > 0
    BEGIN
        SET @p_message = 'You have unpaid fines. Clear dues before requesting books.';
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM oltp.requested_book
        WHERE student_id = @p_student_id AND book_id = @p_book_id
          AND request_status = 'Pending'
    )
    BEGIN
        SET @p_message = 'You already have a pending request for this book.';
        RETURN;
    END

    INSERT INTO oltp.requested_book (student_id, book_id, request_status)
    VALUES (@p_student_id, @p_book_id, 'Pending');

    SET @p_message = 'Book request submitted successfully';
END;
GO

CREATE OR ALTER PROCEDURE oltp.approve_reject_request_sp
    @p_request_id INT,
    @p_action NVARCHAR(20),
    @p_processed_by NVARCHAR(50),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_current_status NVARCHAR(20);

    SELECT @v_current_status = request_status
    FROM oltp.requested_book WHERE request_id = @p_request_id;

    IF @v_current_status IS NULL
    BEGIN
        SET @p_message = 'Request not found';
        RETURN;
    END

    IF @v_current_status <> 'Pending'
    BEGIN
        SET @p_message = 'Request already ' + @v_current_status;
        RETURN;
    END

    UPDATE oltp.requested_book
    SET request_status = @p_action,
        processed_by = @p_processed_by,
        processed_date = GETDATE()
    WHERE request_id = @p_request_id;

    DECLARE @v_student_id INT;
    DECLARE @v_book_title NVARCHAR(255);

    SELECT @v_student_id = rb.student_id, @v_book_title = bi.title
    FROM oltp.requested_book rb
    INNER JOIN oltp.book_info bi ON rb.book_id = bi.book_id
    WHERE rb.request_id = @p_request_id;

    IF @v_student_id IS NOT NULL AND @v_book_title IS NOT NULL
    BEGIN
        INSERT INTO oltp.notifications (student_id, message, notification_type)
        VALUES (@v_student_id,
            'Your request for "' + @v_book_title + '" has been ' + @p_action,
            'Request');
    END

    SET @p_message = 'Request ' + @p_action + ' successfully';
END;
GO

-- =========================================================
-- 10.8 ADMIN PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.add_admin
    @p_userid NVARCHAR(100),
    @p_pass NVARCHAR(255),
    @p_name NVARCHAR(150),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM oltp.admin WHERE userid = @p_userid)
    BEGIN
        SET @p_message = 'User ID already exists for Admin.';
        RETURN;
    END

    INSERT INTO oltp.admin (userid, pass, name, is_active)
    VALUES (@p_userid, @p_pass, @p_name, 1);

    SET @p_message = 'Admin user added successfully.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.add_librarian
    @p_userid NVARCHAR(100),
    @p_pass NVARCHAR(255),
    @p_name NVARCHAR(150),
    @p_role NVARCHAR(50) = 'Librarian',
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM oltp.librarian WHERE userid = @p_userid)
    BEGIN
        SET @p_message = 'User ID already exists for Librarian.';
        RETURN;
    END

    INSERT INTO oltp.librarian (userid, pass, name, role, is_active)
    VALUES (@p_userid, @p_pass, @p_name, @p_role, 1);

    SET @p_message = 'Librarian user added successfully.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.show_all_users
AS
BEGIN
    SET NOCOUNT ON;

    SELECT admin_id AS user_id, userid, name, 'Admin' AS user_type, is_active, created_at
    FROM oltp.admin
    UNION ALL
    SELECT librarian_id AS user_id, userid, name, role AS user_type, is_active, created_at
    FROM oltp.librarian
    UNION ALL
    SELECT student_id AS user_id, enrollment_no AS userid, name, 'Student' AS user_type,
           is_active, created_at
    FROM oltp.student
    ORDER BY created_at DESC;
END;
GO

CREATE OR ALTER PROCEDURE oltp.delete_user
    @p_user_id INT,
    @p_user_type NVARCHAR(20),
    @p_deleted_by INT,
    @p_deleted_role NVARCHAR(50),
    @p_reason NVARCHAR(500) = NULL,
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_deleted_by INT = @p_deleted_by;
    DECLARE @v_deleted_role NVARCHAR(50) = @p_deleted_role;
    DECLARE @v_reason NVARCHAR(500) = @p_reason;

    IF @p_user_type = 'Admin'
    BEGIN
        INSERT INTO oltp.deleted_student (student_id, name, deleted_by, role, reason)
        SELECT admin_id, name, @v_deleted_by, @v_deleted_role, @v_reason
        FROM oltp.admin WHERE admin_id = @p_user_id;
        DELETE FROM oltp.admin WHERE admin_id = @p_user_id;
        SET @p_message = 'Admin user deleted.';
    END
    ELSE IF @p_user_type = 'Librarian'
    BEGIN
        INSERT INTO oltp.deleted_student (student_id, name, deleted_by, role, reason)
        SELECT librarian_id, name, @v_deleted_by, @v_deleted_role, @v_reason
        FROM oltp.librarian WHERE librarian_id = @p_user_id;
        DELETE FROM oltp.librarian WHERE librarian_id = @p_user_id;
        SET @p_message = 'Librarian user deleted.';
    END
    ELSE IF @p_user_type = 'Student'
    BEGIN
        INSERT INTO oltp.deleted_student (student_id, enrollment_no, name, email, deleted_by, role, reason)
        SELECT student_id, enrollment_no, name, email, @v_deleted_by, @v_deleted_role, @v_reason
        FROM oltp.student WHERE student_id = @p_user_id;
        DELETE FROM oltp.student WHERE student_id = @p_user_id;
        SET @p_message = 'Student user deleted.';
    END
    ELSE
    BEGIN
        SET @p_message = 'Invalid user type.';
    END
END;
GO

-- =========================================================
-- 10.9 BOOK MANAGEMENT PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.add_book
    @p_title NVARCHAR(255),
    @p_author NVARCHAR(200),
    @p_publisher NVARCHAR(200) = NULL,
    @p_isbn NVARCHAR(50) = NULL,
    @p_quantity INT = 1,
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_publisher_id INT = NULL;
    DECLARE @v_book_id INT;

    IF @p_publisher IS NOT NULL
    BEGIN
        SELECT @v_publisher_id = publisher_id
        FROM oltp.publisher WHERE publisher_name = @p_publisher;

        IF @v_publisher_id IS NULL
        BEGIN
            INSERT INTO oltp.publisher (publisher_name) VALUES (@p_publisher);
            SET @v_publisher_id = SCOPE_IDENTITY();
        END
    END

    INSERT INTO oltp.book_info (title, author, publisher_id, isbn, book_quantity)
    VALUES (@p_title, @p_author, @v_publisher_id, @p_isbn, @p_quantity);

    SET @v_book_id = SCOPE_IDENTITY();

    DECLARE @i INT = 1;
    WHILE @i <= @p_quantity
    BEGIN
        INSERT INTO oltp.book_copy (book_id, copy_number, status)
        VALUES (@v_book_id, @i, 'Available');
        SET @i = @i + 1;
    END

    SET @p_message = 'Book added successfully with ' + CAST(@p_quantity AS NVARCHAR(10)) + ' copies.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.update_book_stock
    @p_book_id INT,
    @p_new_quantity INT,
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_current_qty INT;

    SELECT @v_current_qty = COUNT(*)
    FROM oltp.book_copy WHERE book_id = @p_book_id;

    IF @v_current_qty IS NULL
    BEGIN
        SET @p_message = 'Book not found.';
        RETURN;
    END

    IF @p_new_quantity > @v_current_qty
    BEGIN
        DECLARE @i INT = @v_current_qty + 1;
        WHILE @i <= @p_new_quantity
        BEGIN
            INSERT INTO oltp.book_copy (book_id, copy_number, status)
            VALUES (@p_book_id, @i, 'Available');
            SET @i = @i + 1;
        END
    END
    ELSE IF @p_new_quantity < @v_current_qty
    BEGIN
        DECLARE @v_to_remove INT = @v_current_qty - @p_new_quantity;
        DELETE TOP (@v_to_remove) FROM oltp.book_copy
        WHERE book_id = @p_book_id AND status = 'Available';
    END

    SET @p_message = 'Book stock updated to ' + CAST(@p_new_quantity AS NVARCHAR(10)) + ' copies.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.remove_book
    @p_book_id INT,
    @p_deleted_by INT,
    @p_deleted_role NVARCHAR(50),
    @p_message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_title NVARCHAR(255);
    DECLARE @v_author NVARCHAR(200);
    DECLARE @v_isbn NVARCHAR(50);

    SELECT @v_title = title, @v_author = author, @v_isbn = isbn
    FROM oltp.book_info WHERE book_id = @p_book_id;

    IF @v_title IS NULL
    BEGIN
        SET @p_message = 'Book not found.';
        RETURN;
    END

    INSERT INTO oltp.deleted_book (book_id, copy_id, title, author, isbn, deleted_by, deleted_role)
    SELECT book_id, copy_id, @v_title, @v_author, @v_isbn, @p_deleted_by, @p_deleted_role
    FROM oltp.book_copy WHERE book_id = @p_book_id;

    DELETE FROM oltp.book_copy WHERE book_id = @p_book_id;
    UPDATE oltp.book_info SET is_active = 0 WHERE book_id = @p_book_id;

    SET @p_message = 'Book removed successfully.';
END;
GO

CREATE OR ALTER PROCEDURE oltp.search_books
    @p_search_term NVARCHAR(255) = NULL,
    @p_author NVARCHAR(200) = NULL,
    @p_isbn NVARCHAR(50) = NULL,
    @p_category NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bi.book_id,
        bi.title,
        bi.author,
        p.publisher_name,
        bi.isbn,
        bi.edition,
        bi.language,
        util.fn_book_available_copies(bi.book_id) AS available_copies,
        util.fn_book_total_quantity(bi.book_id) AS total_copies,
        bi.is_active
    FROM oltp.book_info bi
    LEFT JOIN oltp.publisher p ON bi.publisher_id = p.publisher_id
    WHERE (@p_search_term IS NULL OR
           bi.title LIKE '%' + @p_search_term + '%' OR
           bi.isbn LIKE '%' + @p_search_term + '%')
      AND (@p_author IS NULL OR bi.author LIKE '%' + @p_author + '%')
      AND (@p_isbn IS NULL OR bi.isbn = @p_isbn)
    ORDER BY bi.title;
END;
GO

-- =========================================================
-- 10.10 REPORTING PROCEDURES
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.get_issue_history
    @p_student_id INT = NULL,
    @p_book_id INT = NULL,
    @p_start_date DATE = NULL,
    @p_end_date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ib.issue_id,
        s.enrollment_no,
        s.name AS student_name,
        bi.title AS book_title,
        ib.issue_date,
        ib.due_date,
        ib.is_returned,
        rb.return_date
    FROM oltp.issued_book ib
    INNER JOIN oltp.student s ON ib.student_id = s.student_id
    INNER JOIN oltp.book_info bi ON ib.book_id = bi.book_id
    LEFT JOIN oltp.returned_book rb ON rb.issue_id = ib.issue_id
    WHERE (@p_student_id IS NULL OR ib.student_id = @p_student_id)
      AND (@p_book_id IS NULL OR ib.book_id = @p_book_id)
      AND (@p_start_date IS NULL OR ib.issue_date >= @p_start_date)
      AND (@p_end_date IS NULL OR ib.issue_date <= @p_end_date)
    ORDER BY ib.issue_date DESC;
END;
GO

CREATE OR ALTER PROCEDURE oltp.get_fine_details
    @p_student_id INT = NULL,
    @p_payment_status NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        f.fine_id,
        s.enrollment_no,
        s.name AS student_name,
        bi.title AS book_title,
        f.due_date,
        f.return_date,
        f.days_late,
        f.fine_amount,
        f.payment_status,
        ISNULL(SUM(fp.amount_paid), 0) AS total_paid
    FROM oltp.issue_fine f
    INNER JOIN oltp.student s ON f.student_id = s.student_id
    INNER JOIN oltp.book_info bi ON f.book_id = bi.book_id
    LEFT JOIN oltp.fine_payment_records fp ON fp.fine_id = f.fine_id
    WHERE (@p_student_id IS NULL OR f.student_id = @p_student_id)
      AND (@p_payment_status IS NULL OR f.payment_status = @p_payment_status)
    GROUP BY f.fine_id, s.enrollment_no, s.name, bi.title,
             f.due_date, f.return_date, f.days_late,
             f.fine_amount, f.payment_status
    ORDER BY f.fine_id DESC;
END;
GO

PRINT 'Stored procedures created successfully.';
GO

-- ==================================================================
-- SECTION 11: TRIGGERS
-- ==================================================================

DECLARE @deleted_by INT;
DECLARE @deleted_role NVARCHAR(50);
DECLARE @deleted_reason NVARCHAR(500);
GO

CREATE OR ALTER TRIGGER oltp.trg_book_copy_delete_log
ON oltp.book_copy
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO oltp.deleted_book (book_id, copy_id, title, author, isbn, deleted_by, deleted_role, deleted_at)
    SELECT d.book_id, d.copy_id, b.title, b.author, b.isbn,
           @deleted_by, @deleted_role, SYSUTCDATETIME()
    FROM deleted d
    INNER JOIN oltp.book_info b ON b.book_id = d.book_id;
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_student_delete_log
ON oltp.student
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO oltp.deleted_student (student_id, enrollment_no, name, email, department_name, deleted_by, role, reason, deleted_at)
    SELECT d.student_id, d.enrollment_no, d.name, d.email,
           dep.department_name, @deleted_by, @deleted_role, @deleted_reason, SYSUTCDATETIME()
    FROM deleted d
    LEFT JOIN oltp.department dep ON dep.department_id = d.department_id;
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_student_signup
ON oltp.student
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO oltp.signup_log (student_id, enrollment_no, message)
    SELECT i.student_id, i.enrollment_no, 'New student registered: ' + i.name
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_session_delete
ON oltp.active_session
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO oltp.session_log (user_id, role, login_time, logout_time)
    SELECT d.user_id, d.role, d.login_time, ISNULL(d.logout_time, SYSUTCDATETIME())
    FROM deleted d;
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_book_copy_status_update
ON oltp.book_copy
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE oltp.issued_book
    SET is_returned = 1
    FROM oltp.issued_book ib
    INNER JOIN inserted i ON ib.copy_id = i.copy_id
    INNER JOIN deleted d ON ib.copy_id = d.copy_id
    WHERE d.status = 'Issued' AND i.status = 'Available';
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_fine_audit
ON oltp.issue_fine
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(payment_status)
    BEGIN
        INSERT INTO oltp.audit_trail (table_name, record_id, action_type, old_values, new_values, performed_at)
        SELECT 'issue_fine', CAST(i.fine_id AS NVARCHAR(10)), 'UPDATE',
               'payment_status: ' + d.payment_status,
               'payment_status: ' + i.payment_status,
               SYSUTCDATETIME()
        FROM inserted i
        INNER JOIN deleted d ON i.fine_id = d.fine_id
        WHERE i.payment_status <> d.payment_status;
    END
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_book_request_insert
ON oltp.requested_book
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO oltp.notifications (student_id, message, notification_type)
    SELECT i.student_id,
           'You requested the book "' + bi.title + '". Status: Pending',
           'Request'
    FROM inserted i
    INNER JOIN oltp.book_info bi ON i.book_id = bi.book_id;
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_book_request_status_update
ON oltp.requested_book
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(request_status)
    BEGIN
        INSERT INTO oltp.notifications (student_id, message, notification_type)
        SELECT i.student_id,
               'Your request for "' + bi.title + '" has been ' + i.request_status,
               'Request'
        FROM inserted i
        INNER JOIN deleted d ON i.request_id = d.request_id
        INNER JOIN oltp.book_info bi ON i.book_id = bi.book_id
        WHERE i.request_status <> d.request_status;
    END
END;
GO

CREATE OR ALTER TRIGGER oltp.trg_department_audit
ON oltp.department
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO oltp.audit_trail (table_name, record_id, action_type, new_values, performed_at)
        SELECT 'department', CAST(i.department_id AS NVARCHAR(10)), 'INSERT',
               'name: ' + i.department_name, SYSUTCDATETIME()
        FROM inserted i;
    END
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO oltp.audit_trail (table_name, record_id, action_type, old_values, new_values, performed_at)
        SELECT 'department', CAST(i.department_id AS NVARCHAR(10)), 'UPDATE',
               'name: ' + d.department_name, 'name: ' + i.department_name, SYSUTCDATETIME()
        FROM inserted i INNER JOIN deleted d ON i.department_id = d.department_id;
    END
    ELSE
    BEGIN
        INSERT INTO oltp.audit_trail (table_name, record_id, action_type, old_values, performed_at)
        SELECT 'department', CAST(d.department_id AS NVARCHAR(10)), 'DELETE',
               'name: ' + d.department_name, SYSUTCDATETIME()
        FROM deleted d;
    END
END;
GO

PRINT 'Triggers created successfully.';
GO

-- ==================================================================
-- SECTION 12: EVENTS (Service Broker + Event Log + Event Triggers)
-- ==================================================================
-- EVENT-DRIVEN ARCHITECTURE:
--   This section implements a full event system using:
--   1) Event log table (oltp.event_log) — every business event is logged
--   2) Service Broker message types, contracts, queues, services
--   3) Event dispatch procedure — sends events asynchronously via Service Broker
--   4) Event-driven triggers — AFTER triggers that publish events to the event bus
--   5) Event processing procedure — reads from Service Broker queue and acts
--   6) Event subscription table — allows subscribing to specific event types
--
-- EVENT TYPES SUPPORTED:
--   - STUDENT_REGISTERED
--   - STUDENT_DELETED
--   - STUDENT_RESTRICTED
--   - STUDENT_UNRESTRICTED
--   - BOOK_ISSUED
--   - BOOK_RETURNED_ON_TIME
--   - BOOK_RETURNED_LATE
--   - FINE_ASSESSED
--   - FINE_PAID
--   - FINE_PARTIALLY_PAID
--   - BOOK_REQUESTED
--   - BOOK_REQUEST_APPROVED
--   - BOOK_REQUEST_REJECTED
--   - LOGIN_SUCCESS
--   - LOGIN_FAILED
--   - SESSION_STARTED
--   - SESSION_ENDED
--   - BOOK_ADDED
--   - BOOK_REMOVED
--   - BOOK_STOCK_UPDATED
--   - ADMIN_CREATED
--   - LIBRARIAN_CREATED
--   - USER_DELETED
--   - SYSTEM_SETTING_CHANGED
--   - RESTRICTION_THRESHOLD_EXCEEDED
--   - OVERDUE_REMINDER
-- ==================================================================

-- =========================================================
-- 12.1 EVENT LOG TABLE
-- =========================================================

CREATE TABLE oltp.event_log (
    event_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    event_type NVARCHAR(100) NOT NULL,
    source_table NVARCHAR(100) NULL,
    record_id NVARCHAR(100) NULL,
    actor_id NVARCHAR(100) NULL,
    actor_role NVARCHAR(50) NULL,
    event_data NVARCHAR(MAX) NULL,
    priority NVARCHAR(20) NOT NULL DEFAULT 'Normal'
        CHECK (priority IN ('Low', 'Normal', 'High', 'Critical')),
    is_dispatched BIT NOT NULL DEFAULT 0,
    dispatched_at DATETIME2(7) NULL,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_event_log_type ON oltp.event_log(event_type);
CREATE INDEX IX_event_log_created ON oltp.event_log(created_at);
CREATE INDEX IX_event_log_dispatched ON oltp.event_log(is_dispatched) WHERE is_dispatched = 0;
CREATE INDEX IX_event_log_source ON oltp.event_log(source_table, record_id);
GO

-- =========================================================
-- 12.2 EVENT SUBSCRIPTION TABLE
-- =========================================================

CREATE TABLE oltp.event_subscription (
    subscription_id INT IDENTITY(1,1) PRIMARY KEY,
    subscriber_name NVARCHAR(100) NOT NULL,
    subscriber_type NVARCHAR(50) NOT NULL
        CHECK (subscriber_type IN ('Application', 'Report', 'Notification', 'Audit', 'External')),
    event_types NVARCHAR(MAX) NOT NULL,  -- Comma-separated event type list, '*' for all
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2(7) NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(7) NULL
);
GO

-- Default subscriptions
INSERT INTO oltp.event_subscription (subscriber_name, subscriber_type, event_types)
VALUES
    ('AuditLogger', 'Audit', '*'),
    ('NotificationEngine', 'Notification', 'STUDENT_RESTRICTED,STUDENT_UNRESTRICTED,FINE_ASSESSED,FINE_PAID,BOOK_REQUEST_APPROVED,BOOK_REQUEST_REJECTED,OVERDUE_REMINDER'),
    ('DashboardReporter', 'Report', 'BOOK_ISSUED,BOOK_RETURNED_ON_TIME,BOOK_RETURNED_LATE,LOGIN_SUCCESS,LOGIN_FAILED'),
    ('SessionManager', 'Application', 'SESSION_STARTED,SESSION_ENDED'),
    ('AdminAlert', 'Notification', 'STUDENT_REGISTERED,BOOK_ADDED,BOOK_REMOVED,RESTRICTION_THRESHOLD_EXCEEDED,LOGIN_FAILED');
GO

-- =========================================================
-- 12.3 SERVICE BROKER MESSAGE TYPES
-- =========================================================

CREATE MESSAGE TYPE [//LMS/Event/Message]
    VALIDATION = WELL_FORMED_XML;
GO

CREATE MESSAGE TYPE [//LMS/Event/Response]
    VALIDATION = NONE;
GO

-- =========================================================
-- 12.4 SERVICE BROKER CONTRACT
-- =========================================================

CREATE CONTRACT [//LMS/Event/Contract]
(
    [//LMS/Event/Message] SENT BY INITIATOR,
    [//LMS/Event/Response] SENT BY TARGET
);
GO

-- =========================================================
-- 12.5 SERVICE BROKER QUEUES
-- =========================================================

CREATE QUEUE oltp.EventQueue
    WITH STATUS = ON,
         RETENTION = ON;
GO

CREATE QUEUE oltp.EventResponseQueue
    WITH STATUS = ON,
         RETENTION = ON;
GO

-- =========================================================
-- 12.6 SERVICE BROKER SERVICES
-- =========================================================

CREATE SERVICE [//LMS/EventService]
    ON QUEUE oltp.EventQueue ([//LMS/Event/Contract]);
GO

CREATE SERVICE [//LMS/EventResponseService]
    ON QUEUE oltp.EventResponseQueue;
GO

PRINT 'Event system tables and Service Broker objects created successfully.';
GO

-- =========================================================
-- 12.7 EVENT PUBLISH PROCEDURE
-- =========================================================

CREATE OR ALTER PROCEDURE util.sp_publish_event
    @p_event_type NVARCHAR(100),
    @p_source_table NVARCHAR(100) = NULL,
    @p_record_id NVARCHAR(100) = NULL,
    @p_actor_id NVARCHAR(100) = NULL,
    @p_actor_role NVARCHAR(50) = NULL,
    @p_event_data NVARCHAR(MAX) = NULL,
    @p_priority NVARCHAR(20) = 'Normal'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Log the event
        INSERT INTO oltp.event_log (event_type, source_table, record_id, actor_id, actor_role, event_data, priority)
        VALUES (@p_event_type, @p_source_table, @p_record_id, @p_actor_id, @p_actor_role, @p_event_data, @p_priority);

        DECLARE @v_event_id BIGINT = SCOPE_IDENTITY();

        -- Send via Service Broker (asynchronous)
        DECLARE @v_xml_body NVARCHAR(MAX) =
            N'<Event>' +
            N'<EventID>' + CAST(@v_event_id AS NVARCHAR(20)) + N'</EventID>' +
            N'<EventType>' + ISNULL(@p_event_type, N'') + N'</EventType>' +
            N'<SourceTable>' + ISNULL(@p_source_table, N'') + N'</SourceTable>' +
            N'<RecordID>' + ISNULL(@p_record_id, N'') + N'</RecordID>' +
            N'<ActorID>' + ISNULL(@p_actor_id, N'') + N'</ActorID>' +
            N'<ActorRole>' + ISNULL(@p_actor_role, N'') + N'</ActorRole>' +
            N'<Priority>' + ISNULL(@p_priority, N'Normal') + N'</Priority>' +
            N'<CreatedAt>' + CONVERT(NVARCHAR(30), SYSUTCDATETIME(), 126) + N'</CreatedAt>' +
            N'</Event>';

        DECLARE @v_dialog_handle UNIQUEIDENTIFIER;
        BEGIN DIALOG CONVERSATION @v_dialog_handle
            FROM SERVICE [//LMS/EventService]
            TO SERVICE N'//LMS/EventService'
            ON CONTRACT [//LMS/Event/Contract]
            WITH ENCRYPTION = OFF;

        SEND ON CONVERSATION @v_dialog_handle
            MESSAGE TYPE [//LMS/Event/Message] (CAST(@v_xml_body AS XML));

        END CONVERSATION @v_dialog_handle;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        -- Log to event_log even on broker failure (mark as not dispatched)
        INSERT INTO oltp.event_log (event_type, source_table, record_id, actor_id, actor_role, event_data, priority)
        VALUES (@p_event_type, @p_source_table, @p_record_id, @p_actor_id, @p_actor_role, @p_event_data, @p_priority);
    END CATCH
END;
GO

-- =========================================================
-- 12.8 EVENT PROCESSING PROCEDURE (Queue Reader)
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.sp_process_events
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_message_body XML;
    DECLARE @v_dialog_handle UNIQUEIDENTIFIER;
    DECLARE @v_event_id BIGINT;
    DECLARE @v_event_type NVARCHAR(100);
    DECLARE @v_record_id NVARCHAR(100);

    -- Receive a message from the queue
    WAITFOR (
        RECEIVE TOP (1)
            @v_message_body = message_body,
            @v_dialog_handle = conversation_handle
        FROM oltp.EventQueue
    ), TIMEOUT 1000;

    IF @v_message_body IS NULL
        RETURN;

    -- Parse event
    SELECT
        @v_event_id = @v_message_body.value('(/Event/EventID)[1]', 'BIGINT'),
        @v_event_type = @v_message_body.value('(/Event/EventType)[1]', 'NVARCHAR(100)'),
        @v_record_id = @v_message_body.value('(/Event/RecordID)[1]', 'NVARCHAR(100)');

    BEGIN TRY
        -- =====================================================
        -- EVENT HANDLERS: Process each event type
        -- =====================================================

        -- OVERDUE_REMINDER: Send reminder notifications to students with overdue books
        IF @v_event_type = 'OVERDUE_REMINDER'
        BEGIN
            INSERT INTO oltp.notifications (student_id, message, notification_type)
            SELECT
                s.student_id,
                'Reminder: You have overdue book(s). Please return them to avoid further fines.',
                'General'
            FROM oltp.issued_book ib
            INNER JOIN oltp.student s ON ib.student_id = s.student_id
            WHERE ib.is_returned = 0
              AND CAST(GETDATE() AS DATE) > ib.due_date
              AND s.restriction_status = 'Normal';
        END

        -- RESTRICTION_THRESHOLD_EXCEEDED: Auto-restrict students
        IF @v_event_type = 'RESTRICTION_THRESHOLD_EXCEEDED'
        BEGIN
            DECLARE @v_threshold INT = util.fn_get_setting_int('RESTRICTION_THRESHOLD');
            UPDATE oltp.student
            SET restriction_status = 'Restricted'
            WHERE student_id = TRY_CAST(@v_record_id AS INT)
              AND util.fn_student_unpaid_fines(TRY_CAST(@v_record_id AS INT)) >= @v_threshold;
        END

        -- STUDENT_REGISTERED: Send welcome notification
        IF @v_event_type = 'STUDENT_REGISTERED'
        BEGIN
            INSERT INTO oltp.notifications (student_id, message, notification_type)
            SELECT TRY_CAST(@v_record_id AS INT),
                   'Welcome to the Library Management System! Your account has been created.',
                   'General'
            WHERE @v_record_id IS NOT NULL;
        END

        -- LOGIN_FAILED: Log security alert if repeated failures
        IF @v_event_type = 'LOGIN_FAILED'
        BEGIN
            DECLARE @v_user NVARCHAR(100);
            DECLARE @v_count INT;
            SELECT @v_user = actor_id FROM oltp.event_log WHERE event_id = @v_event_id;
            SELECT @v_count = COUNT(*)
            FROM oltp.login_log
            WHERE user_id = @v_user AND status = 'FAILED'
              AND [timestamp] > DATEADD(MINUTE, -15, GETDATE());

            IF @v_count >= 3
            BEGIN
                INSERT INTO oltp.audit_trail (table_name, record_id, action_type, new_values, performed_at)
                VALUES ('login_log', @v_user, 'INSERT',
                        'WARNING: ' + CAST(@v_count AS NVARCHAR(10)) + ' failed login attempts in 15 minutes',
                        SYSUTCDATETIME());
            END
        END

        -- Mark event as dispatched
        UPDATE oltp.event_log SET is_dispatched = 1, dispatched_at = SYSUTCDATETIME()
        WHERE event_id = @v_event_id;

        -- Send response and end conversation
        SEND ON CONVERSATION @v_dialog_handle
            MESSAGE TYPE [//LMS/Event/Response] (N'<Response><Status>Processed</Status></Response>');
        END CONVERSATION @v_dialog_handle;
    END TRY
    BEGIN CATCH
        -- End conversation on error
        END CONVERSATION @v_dialog_handle;
    END CATCH
END;
GO

-- =========================================================
-- 12.9 EVENT ACTIVATION PROCEDURE (Auto-triggered by Queue)
-- =========================================================

CREATE OR ALTER PROCEDURE oltp.sp_event_activation
AS
BEGIN
    SET NOCOUNT ON;
    EXEC oltp.sp_process_events;
END;
GO

-- Enable activation on the event queue (auto-process events)
ALTER QUEUE oltp.EventQueue
    WITH ACTIVATION (
        STATUS = ON,
        PROCEDURE_NAME = oltp.sp_event_activation,
        MAX_QUEUE_READERS = 4,
        EXECUTE AS OWNER
    );
GO

-- =========================================================
-- 12.10 EVENT-DRIVEN TRIGGERS (Publish events to Service Broker)
-- =========================================================

-- TRIGGER: Publish event on student signup
CREATE OR ALTER TRIGGER oltp.trg_evt_student_signup
ON oltp.student
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_sid INT;
    DECLARE @v_name NVARCHAR(150);
    DECLARE @v_enr NVARCHAR(50);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_sid = student_id, @v_name = name, @v_enr = enrollment_no FROM inserted;

    IF @v_sid IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_sid AS NVARCHAR(100));
        SET @v_event_data = N'<Student><ID>' + CAST(@v_sid AS NVARCHAR(20)) + N'</ID><Name>' + ISNULL(@v_name, N'') + N'</Name><Enrollment>' + ISNULL(@v_enr, N'') + N'</Enrollment></Student>';
        EXEC util.sp_publish_event
            @p_event_type = 'STUDENT_REGISTERED',
            @p_source_table = 'oltp.student',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on student delete
CREATE OR ALTER TRIGGER oltp.trg_evt_student_delete
ON oltp.student
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_sid INT;
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);
    SELECT TOP 1 @v_sid = student_id FROM deleted;
    IF @v_sid IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_sid AS NVARCHAR(100));
        SET @v_event_data = N'<Student><ID>' + CAST(@v_sid AS NVARCHAR(20)) + N'</ID></Student>';
        EXEC util.sp_publish_event
            @p_event_type = 'STUDENT_DELETED',
            @p_source_table = 'oltp.student',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
    END
END;
GO

-- TRIGGER: Publish event on student restriction change
CREATE OR ALTER TRIGGER oltp.trg_evt_student_restriction
ON oltp.student
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(restriction_status)
    BEGIN
        DECLARE @v_sid INT;
        DECLARE @v_old_status NVARCHAR(20);
        DECLARE @v_new_status NVARCHAR(20);
        DECLARE @v_record_id NVARCHAR(100);
        DECLARE @v_event_data NVARCHAR(MAX);

        SELECT @v_sid = i.student_id,
               @v_old_status = d.restriction_status,
               @v_new_status = i.restriction_status
        FROM inserted i INNER JOIN deleted d ON i.student_id = d.student_id;

        IF @v_old_status <> @v_new_status
        BEGIN
            SET @v_record_id = CAST(@v_sid AS NVARCHAR(100));
            SET @v_event_data = N'<Student><ID>' + CAST(@v_sid AS NVARCHAR(20)) + N'</ID></Student>';
            IF @v_new_status = 'Restricted'
                EXEC util.sp_publish_event @p_event_type = 'STUDENT_RESTRICTED',
                    @p_source_table = 'oltp.student',
                    @p_record_id = @v_record_id,
                    @p_event_data = @v_event_data,
                    @p_priority = 'High';
            ELSE
                EXEC util.sp_publish_event @p_event_type = 'STUDENT_UNRESTRICTED',
                    @p_source_table = 'oltp.student',
                    @p_record_id = @v_record_id,
                    @p_event_data = @v_event_data,
                    @p_priority = 'Normal';
        END
    END
END;
GO

-- TRIGGER: Publish event on book issue
CREATE OR ALTER TRIGGER oltp.trg_evt_book_issue
ON oltp.issued_book
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_issue_id INT;
    DECLARE @v_student_id INT;
    DECLARE @v_book_id INT;
    DECLARE @v_copy_id INT;
    DECLARE @v_issue_date DATE;
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_issue_id = issue_id, @v_student_id = student_id,
                 @v_book_id = book_id, @v_copy_id = copy_id, @v_issue_date = issue_date
    FROM inserted;

    IF @v_issue_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_issue_id AS NVARCHAR(100));
        SET @v_event_data = N'<Issue><IssueID>' + CAST(@v_issue_id AS NVARCHAR(20)) + N'</IssueID><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID><BookID>' + CAST(@v_book_id AS NVARCHAR(20)) + N'</BookID><CopyID>' + CAST(@v_copy_id AS NVARCHAR(20)) + N'</CopyID><IssueDate>' + ISNULL(CONVERT(NVARCHAR(30), @v_issue_date, 126), N'') + N'</IssueDate></Issue>';
        EXEC util.sp_publish_event
            @p_event_type = 'BOOK_ISSUED',
            @p_source_table = 'oltp.issued_book',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on book return (late or on time)
CREATE OR ALTER TRIGGER oltp.trg_evt_book_return
ON oltp.returned_book
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_return_id INT;
    DECLARE @v_student_id INT;
    DECLARE @v_book_id INT;
    DECLARE @v_days_late INT;
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_return_id = return_id, @v_student_id = student_id,
                 @v_book_id = book_id, @v_days_late = ISNULL(days_late, 0)
    FROM inserted;

    IF @v_return_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_return_id AS NVARCHAR(100));
        IF @v_days_late > 0
        BEGIN
            SET @v_event_data = N'<Return><ReturnID>' + CAST(@v_return_id AS NVARCHAR(20)) + N'</ReturnID><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID><BookID>' + CAST(@v_book_id AS NVARCHAR(20)) + N'</BookID><DaysLate>' + CAST(@v_days_late AS NVARCHAR(10)) + N'</DaysLate></Return>';
            EXEC util.sp_publish_event
                @p_event_type = 'BOOK_RETURNED_LATE',
                @p_source_table = 'oltp.returned_book',
                @p_record_id = @v_record_id,
                @p_event_data = @v_event_data,
                @p_priority = 'Normal';
        END
        ELSE
        BEGIN
            SET @v_event_data = N'<Return><ReturnID>' + CAST(@v_return_id AS NVARCHAR(20)) + N'</ReturnID><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID><BookID>' + CAST(@v_book_id AS NVARCHAR(20)) + N'</BookID></Return>';
            EXEC util.sp_publish_event
                @p_event_type = 'BOOK_RETURNED_ON_TIME',
                @p_source_table = 'oltp.returned_book',
                @p_record_id = @v_record_id,
                @p_event_data = @v_event_data,
                @p_priority = 'Normal';
        END
    END
END;
GO

-- TRIGGER: Publish event on fine assessment
CREATE OR ALTER TRIGGER oltp.trg_evt_fine_assessed
ON oltp.issue_fine
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_fine_id INT;
    DECLARE @v_student_id INT;
    DECLARE @v_fine_amount DECIMAL(10,2);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_fine_id = fine_id, @v_student_id = student_id,
                 @v_fine_amount = fine_amount
    FROM inserted;

    IF @v_fine_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_fine_id AS NVARCHAR(100));
        SET @v_event_data = N'<Fine><FineID>' + CAST(@v_fine_id AS NVARCHAR(20)) + N'</FineID><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID><Amount>' + CAST(@v_fine_amount AS NVARCHAR(20)) + N'</Amount></Fine>';
        EXEC util.sp_publish_event
            @p_event_type = 'FINE_ASSESSED',
            @p_source_table = 'oltp.issue_fine',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
    END
END;
GO

-- TRIGGER: Publish event on fine payment
CREATE OR ALTER TRIGGER oltp.trg_evt_fine_paid
ON oltp.fine_payment_records
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_payment_id INT;
    DECLARE @v_fine_id INT;
    DECLARE @v_amount DECIMAL(10,2);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_payment_id = payment_id, @v_fine_id = fine_id,
                 @v_amount = amount_paid
    FROM inserted;

    IF @v_payment_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_payment_id AS NVARCHAR(100));
        SET @v_event_data = N'<Payment><PaymentID>' + CAST(@v_payment_id AS NVARCHAR(20)) + N'</PaymentID><FineID>' + CAST(@v_fine_id AS NVARCHAR(20)) + N'</FineID><Amount>' + CAST(@v_amount AS NVARCHAR(20)) + N'</Amount></Payment>';
        EXEC util.sp_publish_event
            @p_event_type = 'FINE_PAID',
            @p_source_table = 'oltp.fine_payment_records',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on book request
CREATE OR ALTER TRIGGER oltp.trg_evt_book_request
ON oltp.requested_book
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_request_id INT;
    DECLARE @v_student_id INT;
    DECLARE @v_book_id INT;
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_request_id = request_id, @v_student_id = student_id,
                 @v_book_id = book_id
    FROM inserted;

    IF @v_request_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_request_id AS NVARCHAR(100));
        SET @v_event_data = N'<Request><RequestID>' + CAST(@v_request_id AS NVARCHAR(20)) + N'</RequestID><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID><BookID>' + CAST(@v_book_id AS NVARCHAR(20)) + N'</BookID></Request>';
        EXEC util.sp_publish_event
            @p_event_type = 'BOOK_REQUESTED',
            @p_source_table = 'oltp.requested_book',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on book request approval/rejection
CREATE OR ALTER TRIGGER oltp.trg_evt_book_request_status
ON oltp.requested_book
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(request_status)
    BEGIN
        DECLARE @v_request_id INT;
        DECLARE @v_old_status NVARCHAR(20);
        DECLARE @v_new_status NVARCHAR(20);
        DECLARE @v_record_id NVARCHAR(100);

        SELECT @v_request_id = i.request_id,
               @v_old_status = d.request_status,
               @v_new_status = i.request_status
        FROM inserted i INNER JOIN deleted d ON i.request_id = d.request_id
        WHERE i.request_status <> d.request_status;

        SET @v_record_id = CAST(@v_request_id AS NVARCHAR(100));
        IF @v_new_status = 'Approved'
            EXEC util.sp_publish_event
                @p_event_type = 'BOOK_REQUEST_APPROVED',
                @p_source_table = 'oltp.requested_book',
                @p_record_id = @v_record_id,
                @p_priority = 'Normal';
        ELSE IF @v_new_status = 'Rejected'
            EXEC util.sp_publish_event
                @p_event_type = 'BOOK_REQUEST_REJECTED',
                @p_source_table = 'oltp.requested_book',
                @p_record_id = @v_record_id,
                @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on admin creation
CREATE OR ALTER TRIGGER oltp.trg_evt_admin_created
ON oltp.admin
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_admin_id INT;
    DECLARE @v_name NVARCHAR(150);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);
    SELECT TOP 1 @v_admin_id = admin_id, @v_name = name FROM inserted;
    IF @v_admin_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_admin_id AS NVARCHAR(100));
        SET @v_event_data = N'<Admin><ID>' + CAST(@v_admin_id AS NVARCHAR(20)) + N'</ID><Name>' + ISNULL(@v_name, N'') + N'</Name></Admin>';
        EXEC util.sp_publish_event
            @p_event_type = 'ADMIN_CREATED',
            @p_source_table = 'oltp.admin',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
    END
END;
GO

-- TRIGGER: Publish event on librarian creation
CREATE OR ALTER TRIGGER oltp.trg_evt_librarian_created
ON oltp.librarian
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_lib_id INT;
    DECLARE @v_name NVARCHAR(150);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);
    SELECT TOP 1 @v_lib_id = librarian_id, @v_name = name FROM inserted;
    IF @v_lib_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_lib_id AS NVARCHAR(100));
        SET @v_event_data = N'<Librarian><ID>' + CAST(@v_lib_id AS NVARCHAR(20)) + N'</ID><Name>' + ISNULL(@v_name, N'') + N'</Name></Librarian>';
        EXEC util.sp_publish_event
            @p_event_type = 'LIBRARIAN_CREATED',
            @p_source_table = 'oltp.librarian',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
    END
END;
GO

-- TRIGGER: Publish event on login attempt
CREATE OR ALTER TRIGGER oltp.trg_evt_login
ON oltp.login_log
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_user_id NVARCHAR(100);
    DECLARE @v_role NVARCHAR(20);
    DECLARE @v_status NVARCHAR(20);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT TOP 1 @v_user_id = user_id, @v_role = role, @v_status = status FROM inserted;

    SET @v_event_data = N'<Login><User>' + ISNULL(@v_user_id, N'') + N'</User><Role>' + ISNULL(@v_role, N'') + N'</Role></Login>';
    IF @v_status = 'SUCCESS'
        EXEC util.sp_publish_event
            @p_event_type = 'LOGIN_SUCCESS',
            @p_source_table = 'oltp.login_log',
            @p_actor_id = @v_user_id,
            @p_actor_role = @v_role,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    ELSE
        EXEC util.sp_publish_event
            @p_event_type = 'LOGIN_FAILED',
            @p_source_table = 'oltp.login_log',
            @p_actor_id = @v_user_id,
            @p_actor_role = @v_role,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
END;
GO

-- TRIGGER: Publish event on session start
CREATE OR ALTER TRIGGER oltp.trg_evt_session_start
ON oltp.active_session
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_user NVARCHAR(100);
    DECLARE @v_role NVARCHAR(20);
    DECLARE @v_event_data NVARCHAR(MAX);
    SELECT TOP 1 @v_user = user_id, @v_role = role FROM inserted;
    IF @v_user IS NOT NULL
    BEGIN
        SET @v_event_data = N'<Session><User>' + ISNULL(@v_user, N'') + N'</User><Role>' + ISNULL(@v_role, N'') + N'</Role></Session>';
        EXEC util.sp_publish_event
            @p_event_type = 'SESSION_STARTED',
            @p_source_table = 'oltp.active_session',
            @p_actor_id = @v_user,
            @p_actor_role = @v_role,
            @p_event_data = @v_event_data,
            @p_priority = 'Low';
    END
END;
GO

-- TRIGGER: Publish event on session end
CREATE OR ALTER TRIGGER oltp.trg_evt_session_end
ON oltp.active_session
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(session_status)
    BEGIN
        DECLARE @v_user NVARCHAR(100);
        DECLARE @v_old_status NVARCHAR(20);
        DECLARE @v_new_status NVARCHAR(20);
        DECLARE @v_event_data NVARCHAR(MAX);

        SELECT @v_user = i.user_id,
               @v_old_status = d.session_status,
               @v_new_status = i.session_status
        FROM inserted i INNER JOIN deleted d ON i.session_id = d.session_id
        WHERE i.session_status <> d.session_status;

        IF @v_old_status = 'Active' AND @v_new_status <> 'Active'
        BEGIN
            SET @v_event_data = N'<Session><User>' + ISNULL(@v_user, N'') + N'</User></Session>';
            EXEC util.sp_publish_event
                @p_event_type = 'SESSION_ENDED',
                @p_source_table = 'oltp.active_session',
                @p_actor_id = @v_user,
                @p_event_data = @v_event_data,
                @p_priority = 'Low';
        END
    END
END;
GO

-- TRIGGER: Publish event on book add
CREATE OR ALTER TRIGGER oltp.trg_evt_book_added
ON oltp.book_info
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_book_id INT;
    DECLARE @v_title NVARCHAR(255);
    DECLARE @v_author NVARCHAR(200);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_event_data NVARCHAR(MAX);
    SELECT TOP 1 @v_book_id = book_id, @v_title = title, @v_author = author FROM inserted;
    IF @v_book_id IS NOT NULL
    BEGIN
        SET @v_record_id = CAST(@v_book_id AS NVARCHAR(100));
        SET @v_event_data = N'<Book><ID>' + CAST(@v_book_id AS NVARCHAR(20)) + N'</ID><Title>' + ISNULL(@v_title, N'') + N'</Title><Author>' + ISNULL(@v_author, N'') + N'</Author></Book>';
        EXEC util.sp_publish_event
            @p_event_type = 'BOOK_ADDED',
            @p_source_table = 'oltp.book_info',
            @p_record_id = @v_record_id,
            @p_event_data = @v_event_data,
            @p_priority = 'Normal';
    END
END;
GO

-- TRIGGER: Publish event on book removal
CREATE OR ALTER TRIGGER oltp.trg_evt_book_removed
ON oltp.book_info
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(is_active)
    BEGIN
        DECLARE @v_book_id INT;
        DECLARE @v_record_id NVARCHAR(100);
        SELECT TOP 1 @v_book_id = book_id FROM inserted WHERE is_active = 0;
        IF @v_book_id IS NOT NULL
        BEGIN
            SET @v_record_id = CAST(@v_book_id AS NVARCHAR(100));
            EXEC util.sp_publish_event
                @p_event_type = 'BOOK_REMOVED',
                @p_source_table = 'oltp.book_info',
                @p_record_id = @v_record_id,
                @p_priority = 'High';
        END
    END
END;
GO

-- TRIGGER: Publish event on system setting change
CREATE OR ALTER TRIGGER oltp.trg_evt_setting_changed
ON oltp.system_settings
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_key NVARCHAR(100);
    DECLARE @v_old_val NVARCHAR(255);
    DECLARE @v_new_val NVARCHAR(255);
    DECLARE @v_event_data NVARCHAR(MAX);

    SELECT @v_key = i.setting_key,
           @v_old_val = d.setting_value,
           @v_new_val = i.setting_value
    FROM inserted i INNER JOIN deleted d ON i.setting_key = d.setting_key
    WHERE i.setting_value <> d.setting_value;

    IF @v_key IS NOT NULL
    BEGIN
        SET @v_event_data = N'<Setting><Key>' + ISNULL(@v_key, N'') + N'</Key><OldValue>' + ISNULL(@v_old_val, N'') + N'</OldValue><NewValue>' + ISNULL(@v_new_val, N'') + N'</NewValue></Setting>';
        EXEC util.sp_publish_event
            @p_event_type = 'SYSTEM_SETTING_CHANGED',
            @p_source_table = 'oltp.system_settings',
            @p_record_id = @v_key,
            @p_event_data = @v_event_data,
            @p_priority = 'High';
    END
END;
GO

PRINT 'Event-driven triggers created successfully.';
GO

-- =========================================================
-- 12.11 EVENT MANAGEMENT PROCEDURES
-- =========================================================

-- View all events (for admin dashboard)
CREATE OR ALTER PROCEDURE oltp.sp_get_events
    @p_event_type NVARCHAR(100) = NULL,
    @p_is_dispatched BIT = NULL,
    @p_priority NVARCHAR(20) = NULL,
    @p_top INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@p_top)
        event_id, event_type, source_table, record_id,
        actor_id, actor_role, event_data,
        priority, is_dispatched, dispatched_at, created_at
    FROM oltp.event_log
    WHERE (@p_event_type IS NULL OR event_type = @p_event_type)
      AND (@p_is_dispatched IS NULL OR is_dispatched = @p_is_dispatched)
      AND (@p_priority IS NULL OR priority = @p_priority)
    ORDER BY event_id DESC;
END;
GO

-- View event subscriptions
CREATE OR ALTER PROCEDURE oltp.sp_get_event_subscriptions
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM oltp.event_subscription WHERE is_active = 1 ORDER BY subscriber_name;
END;
GO

-- Retry undelivered events
CREATE OR ALTER PROCEDURE oltp.sp_retry_failed_events
    @p_max_retries INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_event_id BIGINT;
    DECLARE @v_event_type NVARCHAR(100);
    DECLARE @v_source_table NVARCHAR(100);
    DECLARE @v_record_id NVARCHAR(100);
    DECLARE @v_actor_id NVARCHAR(100);
    DECLARE @v_actor_role NVARCHAR(50);
    DECLARE @v_event_data NVARCHAR(MAX);
    DECLARE @v_priority NVARCHAR(20);

    DECLARE event_cursor CURSOR FOR
        SELECT TOP (@p_max_retries)
            event_id, event_type, source_table, record_id,
            actor_id, actor_role, event_data, priority
        FROM oltp.event_log
        WHERE is_dispatched = 0
        ORDER BY created_at ASC;

    OPEN event_cursor;
    FETCH NEXT FROM event_cursor INTO
        @v_event_id, @v_event_type, @v_source_table, @v_record_id,
        @v_actor_id, @v_actor_role, @v_event_data, @v_priority;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Re-send via Service Broker
        BEGIN TRY
            DECLARE @v_xml XML = N'<Retry><EventID>' + CAST(@v_event_id AS NVARCHAR(20)) + N'</EventID></Retry>';
            DECLARE @v_retry_dialog UNIQUEIDENTIFIER;
            BEGIN DIALOG CONVERSATION @v_retry_dialog
                FROM SERVICE [//LMS/EventService]
                TO SERVICE N'//LMS/EventService'
                ON CONTRACT [//LMS/Event/Contract]
                WITH ENCRYPTION = OFF;

            SEND ON CONVERSATION @v_retry_dialog
                MESSAGE TYPE [//LMS/Event/Message] (@v_xml);

            END CONVERSATION @v_retry_dialog;

            UPDATE oltp.event_log SET is_dispatched = 1, dispatched_at = SYSUTCDATETIME()
            WHERE event_id = @v_event_id;
        END TRY
        BEGIN CATCH
            -- Skip on error, continue with next
        END CATCH

        FETCH NEXT FROM event_cursor INTO
            @v_event_id, @v_event_type, @v_source_table, @v_record_id,
            @v_actor_id, @v_actor_role, @v_event_data, @v_priority;
    END

    CLOSE event_cursor;
    DEALLOCATE event_cursor;
END;
GO

-- Generate overdue reminder events (scheduled job calls this)
CREATE OR ALTER PROCEDURE oltp.sp_generate_overdue_reminders
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_student_id INT;
    DECLARE overdue_cursor CURSOR FOR
        SELECT DISTINCT s.student_id
        FROM oltp.issued_book ib
        INNER JOIN oltp.student s ON ib.student_id = s.student_id
        WHERE ib.is_returned = 0
          AND CAST(GETDATE() AS DATE) > ib.due_date
          AND s.restriction_status = 'Normal';

    OPEN overdue_cursor;
    FETCH NEXT FROM overdue_cursor INTO @v_student_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @v_overdue_record_id NVARCHAR(100) = CAST(@v_student_id AS NVARCHAR(100));
        DECLARE @v_overdue_data NVARCHAR(MAX) = N'<Overdue><StudentID>' + CAST(@v_student_id AS NVARCHAR(20)) + N'</StudentID></Overdue>';
        EXEC util.sp_publish_event
            @p_event_type = 'OVERDUE_REMINDER',
            @p_source_table = 'oltp.issued_book',
            @p_record_id = @v_overdue_record_id,
            @p_event_data = @v_overdue_data,
            @p_priority = 'Normal';

        FETCH NEXT FROM overdue_cursor INTO @v_student_id;
    END

    CLOSE overdue_cursor;
    DEALLOCATE overdue_cursor;
END;
GO

PRINT 'Event management procedures created successfully.';
GO

-- ==================================================================
-- SECTION 13: VIEWS (Reporting & BI Layer)
-- ==================================================================

CREATE OR ALTER VIEW reporting.vw_student_dashboard
AS
SELECT
    s.student_id, s.enrollment_no, s.name, s.email, s.phone,
    s.address, s.course, s.semester, d.department_name,
    s.status, s.restriction_status,
    util.fn_student_active_issues(s.student_id) AS active_issued_books,
    util.fn_student_unpaid_fines(s.student_id) AS total_unpaid_fines,
    (SELECT COUNT(*) FROM oltp.notifications n
     WHERE n.student_id = s.student_id AND n.is_read = 0) AS unread_notifications,
    s.created_at AS registration_date
FROM oltp.student s
LEFT JOIN oltp.department d ON s.department_id = d.department_id
WHERE s.is_active = 1;
GO

CREATE OR ALTER VIEW reporting.vw_book_availability
AS
SELECT
    bi.book_id, bi.title, bi.author, p.publisher_name, bc.category_name,
    bi.isbn, bi.edition, bi.language, bi.year_published,
    util.fn_book_total_quantity(bi.book_id) AS total_copies,
    util.fn_book_available_copies(bi.book_id) AS available_copies,
    util.fn_book_total_quantity(bi.book_id) - util.fn_book_available_copies(bi.book_id) AS issued_copies,
    CASE WHEN util.fn_book_available_copies(bi.book_id) > 0 THEN 'Available' ELSE 'Not Available' END AS availability_status,
    bi.is_active
FROM oltp.book_info bi
LEFT JOIN oltp.publisher p ON bi.publisher_id = p.publisher_id
LEFT JOIN oltp.book_category bc ON bi.category_id = bc.category_id;
GO

CREATE OR ALTER VIEW reporting.vw_overdue_books
AS
SELECT
    ib.issue_id, s.student_id, s.enrollment_no, s.name AS student_name,
    s.email AS student_email, s.phone AS student_phone,
    bi.book_id, bi.title AS book_title, bi.author AS book_author,
    ib.issue_date, ib.due_date,
    DATEDIFF(DAY, ib.due_date, CAST(GETDATE() AS DATE)) AS days_overdue,
    DATEDIFF(DAY, ib.due_date, CAST(GETDATE() AS DATE)) *
        TRY_CAST(util.fn_get_setting('FINE_PER_DAY') AS DECIMAL(10,2)) AS estimated_fine
FROM oltp.issued_book ib
INNER JOIN oltp.student s ON ib.student_id = s.student_id
INNER JOIN oltp.book_info bi ON ib.book_id = bi.book_id
WHERE ib.is_returned = 0 AND CAST(GETDATE() AS DATE) > ib.due_date;
GO

CREATE OR ALTER VIEW reporting.vw_fine_summary
AS
SELECT
    f.fine_id, s.student_id, s.enrollment_no, s.name AS student_name,
    bi.title AS book_title, f.due_date, f.return_date, f.days_late,
    f.fine_amount, f.payment_status, f.fine_per_day,
    ISNULL((SELECT SUM(amount_paid) FROM oltp.fine_payment_records WHERE fine_id = f.fine_id), 0) AS amount_paid,
    f.fine_amount - ISNULL((SELECT SUM(amount_paid) FROM oltp.fine_payment_records WHERE fine_id = f.fine_id), 0) AS remaining_balance,
    f.created_at AS fine_date
FROM oltp.issue_fine f
INNER JOIN oltp.student s ON f.student_id = s.student_id
INNER JOIN oltp.book_info bi ON f.book_id = bi.book_id;
GO

CREATE OR ALTER VIEW reporting.vw_issue_history
AS
SELECT
    ib.issue_id, s.student_id, s.enrollment_no, s.name AS student_name,
    d.department_name, bi.book_id, bi.title AS book_title, bi.author AS book_author,
    bc.copy_id, bc.copy_number, ib.issue_date, ib.issue_days, ib.due_date,
    ib.is_returned, rb.return_date,
    DATEDIFF(DAY, ib.due_date, ISNULL(rb.return_date, GETDATE())) AS days_late,
    ib.issued_by, ib.issued_role, ib.created_at
FROM oltp.issued_book ib
INNER JOIN oltp.student s ON ib.student_id = s.student_id
INNER JOIN oltp.book_info bi ON ib.book_id = bi.book_id
INNER JOIN oltp.book_copy bc ON ib.copy_id = bc.copy_id
LEFT JOIN oltp.department d ON s.department_id = d.department_id
LEFT JOIN oltp.returned_book rb ON rb.issue_id = ib.issue_id;
GO

CREATE OR ALTER VIEW reporting.vw_returned_books
AS
SELECT
    rb.return_id, s.student_id, s.enrollment_no, s.name AS student_name,
    bi.title AS book_title, bc.copy_number, ib.issue_date, rb.return_date,
    rb.days_late, ib.due_date,
    CASE WHEN rb.days_late > 0 THEN 'Late' ELSE 'On Time' END AS return_status,
    rb.returned_by, rb.returned_role
FROM oltp.returned_book rb
INNER JOIN oltp.student s ON rb.student_id = s.student_id
INNER JOIN oltp.book_info bi ON rb.book_id = bi.book_id
INNER JOIN oltp.book_copy bc ON rb.copy_id = bc.copy_id
INNER JOIN oltp.issued_book ib ON rb.issue_id = ib.issue_id;
GO

CREATE OR ALTER VIEW reporting.vw_book_requests
AS
SELECT
    rb.request_id, s.student_id, s.enrollment_no, s.name AS student_name,
    bi.title AS book_title, bi.author AS book_author,
    rb.request_date, rb.request_status, rb.remarks,
    rb.processed_by, rb.processed_date,
    DATEDIFF(DAY, rb.request_date, ISNULL(rb.processed_date, GETDATE())) AS days_pending
FROM oltp.requested_book rb
INNER JOIN oltp.student s ON rb.student_id = s.student_id
INNER JOIN oltp.book_info bi ON rb.book_id = bi.book_id;
GO

CREATE OR ALTER VIEW reporting.vw_active_sessions
AS
SELECT
    session_id, user_id, role, login_time,
    GETDATE() AS server_time,
    DATEDIFF(MINUTE, login_time, GETDATE()) AS session_duration_minutes,
    ip_address
FROM oltp.active_session
WHERE session_status = 'Active';
GO

CREATE OR ALTER VIEW reporting.vw_restricted_students
AS
SELECT
    s.student_id, s.enrollment_no, s.name, s.email, s.phone,
    s.restriction_status,
    util.fn_student_unpaid_fines(s.student_id) AS total_unpaid_fines,
    util.fn_student_active_issues(s.student_id) AS active_issues,
    s.created_at
FROM oltp.student s
WHERE s.restriction_status = 'Restricted' AND s.is_active = 1;
GO

CREATE OR ALTER VIEW reporting.vw_department_statistics
AS
WITH student_stats AS (
    SELECT
        d.department_id, d.department_name,
        s.student_id,
        s.status,
        s.restriction_status,
        CASE WHEN EXISTS (
            SELECT 1 FROM oltp.issued_book ib
            WHERE ib.student_id = s.student_id AND ib.is_returned = 0
        ) THEN 1 ELSE 0 END AS has_book,
        ISNULL(f.unpaid_total, 0) AS unpaid_total
    FROM oltp.department d
    LEFT JOIN oltp.student s ON d.department_id = s.department_id AND s.is_active = 1
    OUTER APPLY (
        SELECT SUM(fine_amount) AS unpaid_total
        FROM oltp.issue_fine f
        WHERE f.student_id = s.student_id AND f.payment_status = 'UNPAID'
    ) f
)
SELECT
    department_id,
    department_name,
    COUNT(DISTINCT student_id) AS total_students,
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active_students,
    SUM(CASE WHEN restriction_status = 'Restricted' THEN 1 ELSE 0 END) AS restricted_students,
    SUM(CASE WHEN has_book = 1 THEN 1 ELSE 0 END) AS students_with_books,
    SUM(unpaid_total) AS total_unpaid_fines_dept
FROM student_stats
GROUP BY department_id, department_name;
GO

CREATE OR ALTER VIEW reporting.vw_login_audit
AS
SELECT
    ll.log_id, ll.user_id, ll.role, ll.status, ll.ip_address,
    ll.[timestamp],
    DATEDIFF(DAY, ll.[timestamp], GETDATE()) AS days_ago
FROM oltp.login_log ll;
GO

-- =========================================================
-- 12.1 DATA WAREHOUSE VIEWS (Star Schema - BI Layer)
-- =========================================================

-- Daily issue summary by date
CREATE OR ALTER VIEW reporting.vw_dw_daily_issue_summary
AS
SELECT
    dd.date_key, dd.full_date, dd.month_name, dd.year,
    COUNT(DISTINCT fi.issue_id) AS total_issues,
    COUNT(DISTINCT fi.student_key) AS unique_students,
    COUNT(DISTINCT fi.book_key) AS unique_books
FROM dw.fact_book_issue fi
INNER JOIN dw.dim_date dd ON fi.issue_date_key = dd.date_key
GROUP BY dd.date_key, dd.full_date, dd.month_name, dd.year;
GO

-- Monthly fine summary
CREATE OR ALTER VIEW reporting.vw_dw_monthly_fine_summary
AS
SELECT
    dd.year, dd.month_name, dd.year_month_key,
    SUM(ff.fine_amount) AS total_fine_amount,
    SUM(CASE WHEN ff.payment_status = 'PAID' THEN ff.fine_amount ELSE 0 END) AS collected_amount,
    SUM(CASE WHEN ff.payment_status = 'UNPAID' THEN ff.fine_amount ELSE 0 END) AS outstanding_amount,
    COUNT(DISTINCT ff.student_key) AS students_with_fines,
    COUNT(*) AS total_fines
FROM dw.fact_fine ff
INNER JOIN dw.dim_date dd ON ff.fine_date_key = dd.date_key
GROUP BY dd.year, dd.month_name, dd.year_month_key;
GO

-- Book popularity (star schema: fact + dim_book directly)
CREATE OR ALTER VIEW reporting.vw_dw_book_popularity
AS
SELECT
    db.book_key, db.title, db.author, db.publisher_name, db.category_name,
    COUNT(fi.issue_id) AS total_issues,
    COUNT(DISTINCT fi.student_key) AS unique_borrowers,
    MAX(dd.full_date) AS last_issued_date
FROM dw.fact_book_issue fi
INNER JOIN dw.dim_book db ON fi.book_key = db.book_key
INNER JOIN dw.dim_date dd ON fi.issue_date_key = dd.date_key
GROUP BY db.book_key, db.title, db.author, db.publisher_name, db.category_name;
GO

-- Student engagement (star schema: fact + dim_student directly)
CREATE OR ALTER VIEW reporting.vw_dw_student_engagement
AS
SELECT
    ds.student_key, ds.enrollment_no, ds.full_name,
    ds.department_name, ds.department_code,
    COUNT(DISTINCT fi.issue_id) AS total_issues,
    COUNT(DISTINCT fr.return_id) AS total_returns,
    COUNT(DISTINCT CASE WHEN fr.days_late > 0 THEN fr.return_id END) AS late_returns,
    ISNULL(SUM(ff.fine_amount), 0) AS total_fines,
    ISNULL(SUM(CASE WHEN ff.payment_status = 'PAID' THEN ff.amount_paid ELSE 0 END), 0) AS total_paid,
    ISNULL(SUM(CASE WHEN ff.payment_status = 'UNPAID' THEN ff.fine_amount ELSE 0 END), 0) AS unpaid_fines
FROM dw.dim_student ds
LEFT JOIN dw.fact_book_issue fi ON ds.student_key = fi.student_key
LEFT JOIN dw.fact_book_return fr ON ds.student_key = fr.student_key
LEFT JOIN dw.fact_fine ff ON ds.student_key = ff.student_key
WHERE ds.is_current = 1
GROUP BY ds.student_key, ds.enrollment_no, ds.full_name, ds.department_name, ds.department_code;
GO

-- Department-wise issue analysis (star schema: fact + dim_student + dim_department)
CREATE OR ALTER VIEW reporting.vw_dw_department_issue_analysis
AS
SELECT
    dp.department_key, dp.department_name,
    COUNT(DISTINCT fi.issue_id) AS total_issues,
    COUNT(DISTINCT ds.student_key) AS unique_students,
    AVG(fi.issue_days) AS avg_issue_days,
    SUM(CASE WHEN fi.is_returned = 1 THEN 1 ELSE 0 END) AS total_returns,
    SUM(CASE WHEN fi.is_returned = 0 THEN 1 ELSE 0 END) AS currently_issued
FROM dw.fact_book_issue fi
INNER JOIN dw.dim_student ds ON fi.student_key = ds.student_key
INNER JOIN dw.dim_department dp ON ds.department_name = dp.department_name
WHERE ds.is_current = 1
GROUP BY dp.department_key, dp.department_name;
GO

PRINT 'Views created successfully.';
GO

-- ==================================================================
-- SECTION 13: ETL / DATA WAREHOUSE POPULATION PROCEDURES
-- ==================================================================

-- =========================================================
-- 13.1 POPULATE DATE DIMENSION (Flat - all attributes inline)
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_date_dimension
    @start_date DATE = '2020-01-01',
    @end_date DATE = '2035-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dw.dim_date;

    DECLARE @current_date DATE = @start_date;

    WHILE @current_date <= @end_date
    BEGIN
        DECLARE @date_key INT = YEAR(@current_date) * 10000 + MONTH(@current_date) * 100 + DAY(@current_date);
        DECLARE @day_of_week INT = ((DATEPART(WEEKDAY, @current_date) + @@DATEFIRST - 1) % 7);
        IF @day_of_week = 0 SET @day_of_week = 7;

        DECLARE @is_weekend BIT = CASE WHEN DATEPART(WEEKDAY, @current_date) IN (1, 7) THEN 1 ELSE 0 END;
        DECLARE @quarter INT = CASE
            WHEN MONTH(@current_date) IN (1,2,3) THEN 1
            WHEN MONTH(@current_date) IN (4,5,6) THEN 2
            WHEN MONTH(@current_date) IN (7,8,9) THEN 3
            ELSE 4
        END;
        DECLARE @fiscal_year INT = CASE
            WHEN MONTH(@current_date) >= 4 THEN YEAR(@current_date)
            ELSE YEAR(@current_date) - 1
        END;
        DECLARE @fiscal_month INT = CASE
            WHEN MONTH(@current_date) >= 4 THEN MONTH(@current_date) - 3
            ELSE MONTH(@current_date) + 9
        END;
        DECLARE @fiscal_quarter INT = CASE
            WHEN @fiscal_month IN (1,2,3) THEN 1
            WHEN @fiscal_month IN (4,5,6) THEN 2
            WHEN @fiscal_month IN (7,8,9) THEN 3
            ELSE 4
        END;

        INSERT INTO dw.dim_date (
            date_key, full_date, date_name, day_of_week, day_name,
            day_of_month, day_of_year, week_of_month, week_of_year,
            iso_week, month_number, month_name, month_name_short,
            quarter, quarter_name, year, year_month_key, year_quarter_key,
            is_weekend, fiscal_year, fiscal_quarter, fiscal_month
        )
        VALUES (
            @date_key,
            @current_date,
            FORMAT(@current_date, 'dddd, MMMM dd, yyyy'),
            @day_of_week,
            FORMAT(@current_date, 'dddd'),
            DAY(@current_date),
            DATEPART(DAYOFYEAR, @current_date),
            DATEPART(WEEK, @current_date) - DATEPART(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, @current_date), 0)) + 1,
            DATEPART(ISO_WEEK, @current_date),
            DATEPART(ISO_WEEK, @current_date),
            MONTH(@current_date),
            FORMAT(@current_date, 'MMMM'),
            FORMAT(@current_date, 'MMM'),
            @quarter,
            'Q' + CAST(@quarter AS NVARCHAR(1)),
            YEAR(@current_date),
            YEAR(@current_date) * 100 + MONTH(@current_date),
            YEAR(@current_date) * 10 + @quarter,
            @is_weekend,
            @fiscal_year,
            @fiscal_quarter,
            @fiscal_month
        );

        SET @current_date = DATEADD(DAY, 1, @current_date);
    END
END;
GO

-- =========================================================
-- 13.2 POPULATE BOOK DIMENSION (SCD Type 2 - Flat)
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_book_dimension
AS
BEGIN
    SET NOCOUNT ON;

    -- Expire changed records
    UPDATE dw.dim_book
    SET is_current = 0,
        row_valid_to = SYSUTCDATETIME(),
        version_number = version_number + 1
    FROM dw.dim_book db
    INNER JOIN oltp.book_info bi ON db.book_id = bi.book_id
    WHERE db.is_current = 1
      AND (db.title <> bi.title OR db.author <> bi.author);

    -- Insert new/updated current rows (flat: publisher + category inline)
    INSERT INTO dw.dim_book (
        book_key, book_id, title, author, isbn, publisher_name, category_name,
        language, edition, year_published, is_current
    )
    SELECT
        bi.book_id,
        bi.book_id, bi.title, bi.author, bi.isbn,
        p.publisher_name, bc.category_name,
        bi.language, bi.edition, bi.year_published, 1
    FROM oltp.book_info bi
    LEFT JOIN oltp.publisher p ON bi.publisher_id = p.publisher_id
    LEFT JOIN oltp.book_category bc ON bi.category_id = bc.category_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_book db WHERE db.book_id = bi.book_id AND db.is_current = 1
    );
END;
GO

-- =========================================================
-- 13.3 POPULATE BOOK COPY DIMENSION (Flat)
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_book_copy_dimension
AS
BEGIN
    SET NOCOUNT ON;

    -- Expire changed copies
    UPDATE dw.dim_book_copy
    SET is_current = 0,
        row_valid_to = SYSUTCDATETIME()
    FROM dw.dim_book_copy dc
    INNER JOIN oltp.book_copy bc ON dc.copy_id = bc.copy_id
    WHERE dc.is_current = 1
      AND (dc.status <> bc.status OR dc.condition_rating <> bc.condition_rating);

    -- Insert new/updated current rows (flat: book_title + book_author inline)
    INSERT INTO dw.dim_book_copy (
        copy_key, copy_id, book_key, copy_number, book_title, book_author,
        condition_rating, status, is_current
    )
    SELECT
        bc.copy_id,
        bc.copy_id, bi.book_id, bc.copy_number, bi.title, bi.author,
        bc.condition_rating, bc.status, 1
    FROM oltp.book_copy bc
    INNER JOIN oltp.book_info bi ON bc.book_id = bi.book_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_book_copy dc WHERE dc.copy_id = bc.copy_id AND dc.is_current = 1
    );
END;
GO

-- =========================================================
-- 13.4 POPULATE STUDENT DIMENSION (SCD Type 2 - Flat)
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_student_dimension
AS
BEGIN
    SET NOCOUNT ON;

    -- Expire changed records
    UPDATE dw.dim_student
    SET is_current = 0,
        row_valid_to = SYSUTCDATETIME(),
        version_number = version_number + 1
    FROM dw.dim_student ds
    INNER JOIN oltp.student s ON ds.student_id = s.student_id
    WHERE ds.is_current = 1
      AND (ds.status <> s.status OR ds.restriction_status <> s.restriction_status
           OR ISNULL(ds.course, '') <> ISNULL(s.course, '')
           OR ISNULL(ds.semester, '') <> ISNULL(s.semester, ''));

    -- Insert new/updated current rows (flat: department_name inline)
    INSERT INTO dw.dim_student (
        student_key, student_id, enrollment_no, full_name, email, phone,
        department_name, department_code, course, semester, status,
        restriction_status, registration_date, is_current
    )
    SELECT
        s.student_id,
        s.student_id, s.enrollment_no, s.name, s.email, s.phone,
        d.department_name, d.department_code,
        s.course, s.semester, s.status, s.restriction_status, s.created_at, 1
    FROM oltp.student s
    LEFT JOIN oltp.department d ON s.department_id = d.department_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_student ds
        WHERE ds.student_id = s.student_id AND ds.is_current = 1
    );
END;
GO

-- =========================================================
-- 13.5 POPULATE STAFF DIMENSION (Flat)
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_staff_dimension
AS
BEGIN
    SET NOCOUNT ON;

    -- Expire changed records
    UPDATE dw.dim_staff
    SET is_current = 0,
        row_valid_to = SYSUTCDATETIME()
    FROM dw.dim_staff ds
    WHERE ds.is_current = 1
      AND NOT EXISTS (
          SELECT 1 FROM oltp.admin a WHERE ds.user_id = a.admin_id AND ds.user_type = 'Admin'
          UNION ALL
          SELECT 1 FROM oltp.librarian l WHERE ds.user_id = l.librarian_id AND ds.user_type = 'Librarian'
      );

    -- Insert new admin rows (flat)
    INSERT INTO dw.dim_staff (
        staff_key, user_id, user_type, userid, full_name, role, is_current
    )
    SELECT
        admin_id, admin_id, 'Admin', userid, name, NULL, 1
    FROM oltp.admin a
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_staff ds WHERE ds.user_id = a.admin_id AND ds.user_type = 'Admin' AND ds.is_current = 1
    );

    -- Insert new librarian rows (flat)
    INSERT INTO dw.dim_staff (
        staff_key, user_id, user_type, userid, full_name, role, is_current
    )
    SELECT
        librarian_id + 50000, librarian_id, 'Librarian', userid, name, role, 1
    FROM oltp.librarian l
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.dim_staff ds WHERE ds.user_id = l.librarian_id AND ds.user_type = 'Librarian' AND ds.is_current = 1
    );
END;
GO

-- =========================================================
-- 13.6 POPULATE DEPARTMENT DIMENSION
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_department_dimension
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dw.dim_department AS target
    USING oltp.department AS source
    ON target.department_id = source.department_id
    WHEN MATCHED THEN
        UPDATE SET target.department_name = source.department_name,
                   target.department_code = source.department_code,
                   target.faculty = source.faculty,
                   target.is_active = source.is_active
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (department_key, department_id, department_name, department_code, faculty, is_active)
        VALUES (source.department_id, source.department_id, source.department_name,
                source.department_code, source.faculty, source.is_active);
END;
GO

-- =========================================================
-- 13.7 POPULATE FACT TABLES
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_populate_fact_book_issue
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.fact_book_issue (
        issue_id, student_key, book_key, copy_key, staff_key,
        issue_date_key, issue_days, due_date_key, is_returned
    )
    SELECT
        ib.issue_id,
        ds.student_key,
        db.book_key,
        dc.copy_key,
        NULL AS staff_key,
        DATEPART(YEAR, ib.issue_date) * 10000 + DATEPART(MONTH, ib.issue_date) * 100 + DATEPART(DAY, ib.issue_date) AS issue_date_key,
        ib.issue_days,
        DATEPART(YEAR, ib.due_date) * 10000 + DATEPART(MONTH, ib.due_date) * 100 + DATEPART(DAY, ib.due_date) AS due_date_key,
        ib.is_returned
    FROM oltp.issued_book ib
    INNER JOIN dw.dim_student ds ON ib.student_id = ds.student_id AND ds.is_current = 1
    INNER JOIN dw.dim_book db ON ib.book_id = db.book_id AND db.is_current = 1
    INNER JOIN dw.dim_book_copy dc ON ib.copy_id = dc.copy_id AND dc.is_current = 1
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.fact_book_issue fbi WHERE fbi.issue_id = ib.issue_id
    );
END;
GO

CREATE OR ALTER PROCEDURE dw.sp_populate_fact_book_return
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.fact_book_return (
        return_id, issue_key, student_key, book_key, copy_key,
        return_date_key, due_date_key, days_late, fine_incurred
    )
    SELECT
        rb.return_id,
        fbi.issue_key,
        ds.student_key,
        db.book_key,
        dc.copy_key,
        DATEPART(YEAR, rb.return_date) * 10000 + DATEPART(MONTH, rb.return_date) * 100 + DATEPART(DAY, rb.return_date) AS return_date_key,
        DATEPART(YEAR, ib.due_date) * 10000 + DATEPART(MONTH, ib.due_date) * 100 + DATEPART(DAY, ib.due_date) AS due_date_key,
        ISNULL(rb.days_late, 0),
        ISNULL(f.fine_amount, 0)
    FROM oltp.returned_book rb
    INNER JOIN dw.dim_student ds ON rb.student_id = ds.student_id AND ds.is_current = 1
    INNER JOIN dw.dim_book db ON rb.book_id = db.book_id AND db.is_current = 1
    INNER JOIN dw.dim_book_copy dc ON rb.copy_id = dc.copy_id AND dc.is_current = 1
    INNER JOIN oltp.issued_book ib ON rb.issue_id = ib.issue_id
    LEFT JOIN dw.fact_book_issue fbi ON rb.issue_id = fbi.issue_id
    LEFT JOIN oltp.issue_fine f ON f.issue_id = rb.issue_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.fact_book_return fbr WHERE fbr.return_id = rb.return_id
    );
END;
GO

CREATE OR ALTER PROCEDURE dw.sp_populate_fact_fine
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.fact_fine (
        fine_id, issue_key, student_key, book_key, copy_key,
        fine_date_key, return_date_key, days_late,
        fine_per_day, fine_amount, amount_paid, payment_status
    )
    SELECT
        f.fine_id,
        fbi.issue_key,
        ds.student_key,
        db.book_key,
        dc.copy_key,
        DATEPART(YEAR, f.due_date) * 10000 + DATEPART(MONTH, f.due_date) * 100 + DATEPART(DAY, f.due_date) AS fine_date_key,
        DATEPART(YEAR, f.return_date) * 10000 + DATEPART(MONTH, f.return_date) * 100 + DATEPART(DAY, f.return_date) AS return_date_key,
        f.days_late,
        f.fine_per_day,
        f.fine_amount,
        ISNULL((SELECT SUM(amount_paid) FROM oltp.fine_payment_records WHERE fine_id = f.fine_id), 0),
        f.payment_status
    FROM oltp.issue_fine f
    INNER JOIN dw.dim_student ds ON f.student_id = ds.student_id AND ds.is_current = 1
    INNER JOIN dw.dim_book db ON f.book_id = db.book_id AND db.is_current = 1
    INNER JOIN dw.dim_book_copy dc ON f.copy_id = dc.copy_id AND dc.is_current = 1
    LEFT JOIN dw.fact_book_issue fbi ON f.issue_id = fbi.issue_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.fact_fine ff WHERE ff.fine_id = f.fine_id
    );
END;
GO

CREATE OR ALTER PROCEDURE dw.sp_populate_fact_book_request
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dw.fact_book_request (
        request_id, student_key, book_key, request_date_key,
        request_status, processed_date_key, staff_key, days_to_process
    )
    SELECT
        rb.request_id,
        ds.student_key,
        db.book_key,
        DATEPART(YEAR, rb.request_date) * 10000 + DATEPART(MONTH, rb.request_date) * 100 + DATEPART(DAY, rb.request_date) AS request_date_key,
        rb.request_status,
        CASE WHEN rb.processed_date IS NOT NULL THEN
            DATEPART(YEAR, rb.processed_date) * 10000 + DATEPART(MONTH, rb.processed_date) * 100 + DATEPART(DAY, rb.processed_date)
        END AS processed_date_key,
        NULL AS staff_key,
        CASE WHEN rb.processed_date IS NOT NULL THEN
            DATEDIFF(DAY, rb.request_date, rb.processed_date)
        END AS days_to_process
    FROM oltp.requested_book rb
    INNER JOIN dw.dim_student ds ON rb.student_id = ds.student_id AND ds.is_current = 1
    INNER JOIN dw.dim_book db ON rb.book_id = db.book_id AND db.is_current = 1
    WHERE NOT EXISTS (
        SELECT 1 FROM dw.fact_book_request fbr WHERE fbr.request_id = rb.request_id
    );
END;
GO

-- =========================================================
-- 13.8 MASTER ETL PROCEDURE
-- =========================================================

CREATE OR ALTER PROCEDURE dw.sp_run_full_etl
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Starting ETL process at ' + CAST(SYSUTCDATETIME() AS NVARCHAR(50));

    EXEC dw.sp_populate_date_dimension;
    PRINT 'Date dimension populated.';

    EXEC dw.sp_populate_department_dimension;
    PRINT 'Department dimension populated.';

    EXEC dw.sp_populate_book_dimension;
    PRINT 'Book dimension populated.';

    EXEC dw.sp_populate_book_copy_dimension;
    PRINT 'Book copy dimension populated.';

    EXEC dw.sp_populate_student_dimension;
    PRINT 'Student dimension populated.';

    EXEC dw.sp_populate_staff_dimension;
    PRINT 'Staff dimension populated.';

    EXEC dw.sp_populate_fact_book_issue;
    PRINT 'Fact book issue populated.';

    EXEC dw.sp_populate_fact_book_return;
    PRINT 'Fact book return populated.';

    EXEC dw.sp_populate_fact_fine;
    PRINT 'Fact fine populated.';

    EXEC dw.sp_populate_fact_book_request;
    PRINT 'Fact book request populated.';

    PRINT 'ETL process completed at ' + CAST(SYSUTCDATETIME() AS NVARCHAR(50));
END;
GO

PRINT 'ETL procedures created successfully.';
GO

-- ==================================================================
-- SECTION 14: SCHEDULED JOBS (SQL Server Agent)
-- ==================================================================

IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'LMS_Cleanup_Old_Logs'
)
BEGIN
    DECLARE @jobId BINARY(16);
    EXEC msdb.dbo.sp_add_job
        @job_name = N'LMS_Cleanup_Old_Logs',
        @description = N'Clean up login logs, session logs, and notifications older than 90 days',
        @enabled = 1, @job_id = @jobId OUTPUT;
    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @jobId, @step_name = N'Cleanup',
        @command = N'
            USE LibraryManagement_System;
            DELETE FROM oltp.login_log WHERE [timestamp] < DATEADD(DAY, -90, GETDATE());
            DELETE FROM oltp.session_log WHERE logout_time < DATEADD(DAY, -90, GETDATE());
            DELETE FROM oltp.notifications WHERE created_at < DATEADD(DAY, -90, GETDATE()) AND is_read = 1;
            DELETE FROM stg.stg_book_info WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
            DELETE FROM stg.stg_student WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
            DELETE FROM stg.stg_issued_book WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
            DELETE FROM stg.stg_returned_book WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
            DELETE FROM stg.stg_fine WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
            DELETE FROM stg.stg_login_log WHERE load_date < DATEADD(DAY, -30, GETDATE()) AND is_processed = 1;
        ',
        @database_name = N'LibraryManagement_System';
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Daily_2AM', @enabled = 1,
        @freq_type = 4, @freq_interval = 1, @active_start_time = 20000;
    DECLARE @scheduleId INT;
    SELECT @scheduleId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'Daily_2AM';
    EXEC msdb.dbo.sp_attach_schedule @job_id = @jobId, @schedule_id = @scheduleId;
    EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'LMS_Daily_ETL'
)
BEGIN
    DECLARE @etlJobId BINARY(16);
    EXEC msdb.dbo.sp_add_job
        @job_name = N'LMS_Daily_ETL',
        @description = N'Run daily ETL to populate data warehouse dimensions and facts',
        @enabled = 1, @job_id = @etlJobId OUTPUT;
    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @etlJobId, @step_name = N'Run ETL',
        @command = N'EXEC LibraryManagement_System.dw.sp_run_full_etl;',
        @database_name = N'LibraryManagement_System';
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Daily_3AM', @enabled = 1,
        @freq_type = 4, @freq_interval = 1, @active_start_time = 30000;
    DECLARE @etlScheduleId INT;
    SELECT @etlScheduleId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'Daily_3AM';
    EXEC msdb.dbo.sp_attach_schedule @job_id = @etlJobId, @schedule_id = @etlScheduleId;
    EXEC msdb.dbo.sp_add_jobserver @job_id = @etlJobId;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'LMS_Terminate_Expired_Sessions'
)
BEGIN
    DECLARE @sessionJobId BINARY(16);
    EXEC msdb.dbo.sp_add_job
        @job_name = N'LMS_Terminate_Expired_Sessions',
        @description = N'Terminate sessions that have exceeded the timeout limit',
        @enabled = 1, @job_id = @sessionJobId OUTPUT;
    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @sessionJobId, @step_name = N'Terminate expired sessions',
        @command = N'
            USE LibraryManagement_System;
            DECLARE @timeout_minutes INT = TRY_CAST(setting_value AS INT)
            FROM oltp.system_settings WHERE setting_key = ''SESSION_TIMEOUT_MINUTES'';
            IF @timeout_minutes IS NULL SET @timeout_minutes = 480;
            UPDATE oltp.active_session
            SET session_status = ''Expired'', logout_time = GETDATE()
            WHERE session_status = ''Active''
              AND login_time < DATEADD(MINUTE, -@timeout_minutes, GETDATE());
        ',
        @database_name = N'LibraryManagement_System';
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Hourly', @enabled = 1,
        @freq_type = 4, @freq_interval = 1, @freq_subday_type = 8, @freq_subday_interval = 1;
    DECLARE @hourlyScheduleId INT;
    SELECT @hourlyScheduleId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'Hourly';
    EXEC msdb.dbo.sp_attach_schedule @job_id = @sessionJobId, @schedule_id = @hourlyScheduleId;
    EXEC msdb.dbo.sp_add_jobserver @job_id = @sessionJobId;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'LMS_Database_Maintenance'
)
BEGIN
    DECLARE @maintJobId BINARY(16);
    EXEC msdb.dbo.sp_add_job
        @job_name = N'LMS_Database_Maintenance',
        @description = N'Weekly index rebuild, statistics update, and integrity check',
        @enabled = 1, @job_id = @maintJobId OUTPUT;
    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @maintJobId, @step_name = N'Update Statistics',
        @command = N'USE LibraryManagement_System; EXEC sp_updatestats;',
        @database_name = N'LibraryManagement_System';
    EXEC msdb.dbo.sp_add_jobstep
        @job_id = @maintJobId, @step_name = N'Integrity Check',
        @command = N'USE LibraryManagement_System; DBCC CHECKDB WITH NO_INFOMSGS;',
        @database_name = N'LibraryManagement_System';
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = N'Weekly_Sunday_1AM', @enabled = 1,
        @freq_type = 8, @freq_interval = 1, @active_start_time = 10000;
    DECLARE @weeklyScheduleId INT;
    SELECT @weeklyScheduleId = schedule_id FROM msdb.dbo.sysschedules WHERE name = N'Weekly_Sunday_1AM';
    EXEC msdb.dbo.sp_attach_schedule @job_id = @maintJobId, @schedule_id = @weeklyScheduleId;
    EXEC msdb.dbo.sp_add_jobserver @job_id = @maintJobId;
END
GO

PRINT 'Scheduled jobs created successfully.';
GO

-- ==================================================================
-- SECTION 15: SAMPLE DATA
-- ==================================================================

INSERT INTO oltp.department (department_name, department_code, faculty) VALUES
    ('Computer Science', 'CS', 'Faculty of Computing'),
    ('Information Technology', 'IT', 'Faculty of Computing'),
    ('Electronics & Communication', 'ECE', 'Faculty of Engineering'),
    ('Mechanical Engineering', 'ME', 'Faculty of Engineering'),
    ('Civil Engineering', 'CE', 'Faculty of Engineering'),
    ('Business Administration', 'BBA', 'Faculty of Management'),
    ('Mathematics', 'MATH', 'Faculty of Science'),
    ('Physics', 'PHY', 'Faculty of Science');
GO

INSERT INTO oltp.admin (userid, pass, name, is_active)
VALUES ('admin1', 'adminpass', 'Admin One', 1);
GO

INSERT INTO oltp.librarian (userid, pass, name, role, is_active)
VALUES ('lib1', 'libpass', 'Librarian One', 'Librarian', 1);
GO

INSERT INTO oltp.student (enrollment_no, name, email, phone, pass, address, course, semester, department_id, status, restriction_status)
VALUES
    ('ENR2025001', 'Ali Khan', 'ali@example.com', '9998887771', 'pass123', 'Street 1, City A', 'BCA', '1', 1, 'Active', 'Normal'),
    ('ENR2025002', 'Mira Patel', 'mira@example.com', '9898989898', 'pass123', 'Street 2, City B', 'BCA', '2', 1, 'Active', 'Normal'),
    ('ENR2025003', 'Rohan Sharma', 'rohan@example.com', '9876543210', 'pass123', 'Street 3, City C', 'B.Tech', '3', 1, 'Active', 'Normal'),
    ('ENR2025004', 'Priya Singh', 'priya@example.com', '9123456789', 'pass123', 'Street 4, City D', 'BBA', '1', 6, 'Active', 'Normal'),
    ('ENR2025005', 'Vikram Reddy', 'vikram@example.com', '9234567890', 'pass123', 'Street 5, City E', 'M.Tech', '1', 1, 'Active', 'Restricted');
GO

INSERT INTO oltp.publisher (publisher_name) VALUES
    ('TechPub'), ('DBPub'), ('Wiley'), ('Pearson'), ('McGraw-Hill'),
    ('Springer'), ('O''Reilly Media'), ('Packt Publishing');
GO

INSERT INTO oltp.book_category (category_name) VALUES
    ('Programming'), ('Database'), ('Web Development'), ('Networking'),
    ('Mathematics'), ('Business'), ('Data Science'), ('Cloud Computing'),
    ('Security'), ('Operating Systems');
GO

INSERT INTO oltp.book_info (title, author, publisher_id, isbn, book_quantity, language, edition)
VALUES
    ('Java Programming', 'Balaguruswamy', 1, 'ISBN-JAVA-001', 5, 'English', '6th'),
    ('Database Systems', 'Korth', 2, 'ISBN-DB-002', 3, 'English', '7th'),
    ('Web Development with HTML/CSS', 'Duckett', 3, 'ISBN-WEB-003', 4, 'English', '1st'),
    ('Computer Networks', 'Tanenbaum', 4, 'ISBN-NET-004', 2, 'English', '5th'),
    ('Introduction to Algorithms', 'Cormen', 5, 'ISBN-ALG-005', 6, 'English', '3rd'),
    ('Machine Learning', 'Mitchell', 6, 'ISBN-ML-006', 3, 'English', '2nd'),
    ('Clean Code', 'Martin', 7, 'ISBN-CC-007', 4, 'English', '1st'),
    ('Python for Data Science', 'VanderPlas', 7, 'ISBN-PY-008', 5, 'English', '1st');
GO

DECLARE @book_id INT;
DECLARE @qty INT;
DECLARE @i INT;

DECLARE book_cursor CURSOR FOR
    SELECT book_id, book_quantity FROM oltp.book_info;

OPEN book_cursor;
FETCH NEXT FROM book_cursor INTO @book_id, @qty;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @i = 1;
    WHILE @i <= @qty
    BEGIN
        INSERT INTO oltp.book_copy (book_id, copy_number, status)
        VALUES (@book_id, @i, 'Available');
        SET @i = @i + 1;
    END
    FETCH NEXT FROM book_cursor INTO @book_id, @qty;
END

CLOSE book_cursor;
DEALLOCATE book_cursor;
GO

PRINT 'Sample data inserted successfully.';
GO

-- ==================================================================
-- SECTION 16: PERMISSIONS & SECURITY
-- ==================================================================

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_reader' AND type = 'R')
    CREATE ROLE db_reader AUTHORIZATION dbo;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_writer' AND type = 'R')
    CREATE ROLE db_writer AUTHORIZATION dbo;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'db_executor' AND type = 'R')
    CREATE ROLE db_executor AUTHORIZATION dbo;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'dw_reader' AND type = 'R')
    CREATE ROLE dw_reader AUTHORIZATION dbo;
GO

GRANT SELECT ON SCHEMA::oltp TO db_reader;
GRANT SELECT ON SCHEMA::dw TO db_reader;
GRANT SELECT ON SCHEMA::reporting TO db_reader;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::oltp TO db_writer;
GO

GRANT EXECUTE ON SCHEMA::oltp TO db_executor;
GRANT EXECUTE ON SCHEMA::util TO db_executor;
GO

GRANT SELECT ON SCHEMA::dw TO dw_reader;
GRANT SELECT ON SCHEMA::reporting TO dw_reader;
GRANT EXECUTE ON SCHEMA::dw TO dw_reader;
GO

PRINT 'Permissions configured successfully.';
GO

-- ==================================================================
-- END OF DATABASE SCRIPT
-- ==================================================================
PRINT '============================================================';
PRINT 'Library Management System Database created successfully!';
PRINT 'Database: LibraryManagement_System';
PRINT 'Schema: Star Schema + Data Warehousing';
PRINT '============================================================';
GO
