-- =============================================================================
-- schema.sql
-- Defense Workforce & Labor Analytics Database
--
-- Dialect:  Microsoft SQL Server (T-SQL)
-- Author:   Seanpaul Coffey
-- Date:     April 2026
--
-- Purpose:  Models workforce, vendor, and program relationships for analyzing
--           labor utilization, cost performance, and staffing decisions on
--           defense contract programs. Designed to support analytical queries
--           for workforce planning, cost-center burn analysis, vendor rate
--           comparisons, and program staffing mix reporting.
--
-- Notes:    Uses T-SQL features including IDENTITY columns, BIT types, and
--           NVARCHAR. Schema is self-contained and can be run top-to-bottom
--           against a fresh SQL Server database.
--
-- CS50 SQL: This project was submitted as the final project for Harvard's
--           CS50 SQL (Introduction to Databases with SQL).
-- =============================================================================

USE DefenseWorkforce;
GO

-- -----------------------------------------------------------------------------
-- skill_domains
-- Reference table classifying labor categories into broad skill areas
-- (e.g., Engineering, Cybersecurity, Program Management). Used downstream
-- for workforce gap analysis and program staffing mix reporting.
-- -----------------------------------------------------------------------------
CREATE TABLE skill_domains (
    domain_id   INT     IDENTITY(1,1)   NOT NULL,
    domain_name     NVARCHAR(100)   NOT NULL,
    domain_type     NVARCHAR(50)    NOT NULL,
    description     NVARCHAR(500) NULL,

    CONSTRAINT PK_skill_domains PRIMARY KEY (domain_id),
    CONSTRAINT UQ_skill_domains_name UNIQUE (domain_name),
    CONSTRAINT CK_skill_domains_type CHECK(
        domain_type IN('Technical', 'Functional', 'Management')
    )
);
GO

-- -----------------------------------------------------------------------------
-- organizations
-- Represents the organizational hierarchy (directorates, divisions, branches,
-- teams). Self-referencing FK enables recursive CTE queries for roll-up
-- reporting across the org tree.
-- -----------------------------------------------------------------------------
CREATE TABLE organizations (
    org_id  INT     IDENTITY(1,1)   NOT NULL,
    org_name    NVARCHAR(150)   NOT NULL,
    org_code    NVARCHAR(20) NOT NULL,   
    org_type    NVARCHAR(50) NOT NULL,
    parent_org_id   INT     NULL,
    CONSTRAINT PK_organizations PRIMARY KEY (org_id),
    CONSTRAINT UQ_organizations_code UNIQUE (org_code),
    CONSTRAINT CK_organizations_type CHECK(
        org_type IN('Directorate', 'Division', 'Branch', 'Team', 'Office')
    )
);
GO

-- Self-referencing FK added via ALTER
ALTER TABLE organizations
    ADD CONSTRAINT FK_organizations_parent
    FOREIGN KEY (parent_org_id) REFERENCES organizations(org_id);
GO

-- -----------------------------------------------------------------------------
-- vendors
-- Contractor companies providing labor to defense programs. Tracks vendor
-- identity, contract vehicle, and active status for rate analysis and
-- vendor performance comparisons.
-- -----------------------------------------------------------------------------
CREATE TABLE vendors (
    vendor_id   INT     IDENTITY(1,1)    NOT NULL,
    venodr_name NVARCHAR(150)            NOT NULL,
    vendor_code NVARCHAR(20)             NOT NULL,
    vendor_type NVARCHAR(50)             NOT NULL,
    contract_vehicle    NVARCHAR(100)    NOT NULL,
    is_active   BIT                      NOT NULL DEFAULT 1,
    CONSTRAINT PK_vendors PRIMARY KEY (vendor_id),
    CONSTRAINT UQ_vendors_code UNIQUE (vendor_code),
    CONSTRAINT CK_vendors_type CHECK(
        vendor_type IN('Large Business', 'Small Business', 'SDVOSB', 'HUBZone', '8(a)', 'WOSB')
    )
);
GO

-- -----------------------------------------------------------------------------
-- programs
-- Contract programs that consume labor and generate cost. Each program has
-- a contract type, lifecycle phase, and period of performance. Central to
-- staffing analysis, burn-rate tracking, and cost projection queries.
-- -----------------------------------------------------------------------------
CREATE TABLE programs (
    program_id INT  IDENTITY(1,1)   NOT NULL,
    program_name NVARCHAR(150)  NOT NULL,
    program_code NVARCHAR(20)   NOT NULL,
    contract_type NVARCHAR(10)  NOT NULL,
    program_phase  NVARCHAR(20) NOT NULL,
    start_date  Date    NOT NULL,
    end_date    DATE NULL,
    is_active   BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_programs PRIMARY KEY (program_id),
    CONSTRAINT UQ_programs_code UNIQUE (program_code),
    CONSTRAINT CK_programs_contract_type CHECK(
        contract_type IN('FFP', 'CPFF', 'CPAF', 'CPIF', 'T&M', 'IDIQ', 'BPA')
    ),
    CONSTRAINT CK_programs_phase CHECK(
        program_phase IN('Pre-Award', 'Active', 'Close-Out', 'Completed')
    ),
    CONSTRAINT CK_programs_dates CHECK(
        end_date IS NULL OR end_date >= start_date
    )
);
GO

-- -----------------------------------------------------------------------------
-- locations
-- Physical work sites where employees are assigned. Tracks city, state,
-- facility type, and SCIF status. Supports location-based workforce
-- distribution analysis and facility utilization reporting.
-- -----------------------------------------------------------------------------
CREATE TABLE locations(
    location_id INT     IDENTITY(1,1)    NOT NULL,
    location_name NVARCHAR(150)          NOT NULL,
    city        NVARCHAR(100)            NOT NULL,
    state_code  CHAR(2)                  NOT NULL,
    site_type  NVARCHAR(50)             NOT NULL,
    is_scif     BIT                      NOT NULL DEFAULT 0,

    CONSTRAINT PK_locations PRIMARY KEY (location_id),
    CONSTRAINT CK_locations_site_type CHECK(
        site_type IN('Government', 'Contractor', 'FFRDC', 'Remote', 'Hybrid')
    )
);
GO

-- -----------------------------------------------------------------------------
-- labor_categories
-- Specific labor roles (e.g., Systems Engineer III, Cyber Analyst II)
-- classified under a parent skill domain. Links to labor rates and
-- employee assignments. The is_technical flag supports filtering for
-- technical vs. functional workforce mix analysis.
-- -----------------------------------------------------------------------------
CREATE TABLE labor_categories(
    lcat_id INT IDENTITY(1,1) NOT NULL,
    lcat_name NVARCHAR(150)  NOT NULL,
    domain_id   INT NOT NULL,
    labor_type NVARCHAR(50) NOT NULL,
    is_technical BIT    NOT NULL DEFAULT 1,

    CONSTRAINT PK_labor_categories PRIMARY KEY (lcat_id),
    CONSTRAINT FK_labor_categories_domain FOREIGN KEY (domain_id)
        REFERENCES skill_domains(domain_id),
    CONSTRAINT CK_labor_categories_type CHECK(
        labor_type IN('Engineering', 'Analysis', 'Management', 'Administrative', 'Techical')
    )
);
GO

-- -----------------------------------------------------------------------------
-- cost_centers
-- Charge codes tied to specific programs. Represents where labor hours
-- and costs are recorded. Supports burn-rate analysis, budget tracking,
-- and direct vs. indirect cost allocation reporting.
-- -----------------------------------------------------------------------------
CREATE TABLE cost_centers(
    cost_center_id INT  IDENTITY(1,1)    NOT NULL,
    cost_center_code    NVARCHAR(20)     NOT NULL,
    cost_center_name  NVARCHAR(150)      NOT NULL,
    charge_type NVARCHAR(20)             NOT NULL,
    program_id  INT                      NOT NULL,
    is_active   BIT                      NOT NULL DEFAULT 1,

    CONSTRAINT PK_cost_centers PRIMARY KEY (cost_center_id),
    CONSTRAINT UQ_cost_centers_code UNIQUE (cost_center_code),
    CONSTRAINT FK_cost_centers_program FOREIGN KEY(program_id)
        REFERENCES programs(program_id),
    CONSTRAINT CK_cost_centers_charge_type CHECK(
        charge_type IN('Direct', 'Indirect', 'Overhead', 'G&A', 'B&P', 'IR&D')
    )
);
GO

-- -----------------------------------------------------------------------------
-- employees
-- Individual workers assigned to organizations, vendors, locations, labor
-- categories, and cost centers. Central fact table for workforce analytics.
-- Tracks clearance level, billability, labor type, and employment status.
-- Most analytical queries join through this table.
-- -----------------------------------------------------------------------------
CREATE TABLE employees(
    employee_id INT IDENTITY(1,1) NOT NULL,
    first_name NVARCHAR(100)     NOT NULL,
    last_name NVARCHAR(100)     NOT NULL,
    lcat_id INT NOT NULL,
    org_id INT NOT NULL,
    vendor_id INT NOT NULL,
    location_id INT NOT NULL,
    cost_center_id INT NOT NULL,
    hire_date DATE NOT NULL,
    labor_grade NVARCHAR(10) NULL,
    clearance_level NVARCHAR(20)  NOT NULL,
    is_billable BIT NOT NULL DEFAULT 1,
    labor_type NVARCHAR(20) NOT NULL,
    employment_type NVARCHAR(20) NOT NULL,
    is_active BIT  NOT NULL DEFAULT 1,

    CONSTRAINT PK_employees PRIMARY KEY(employee_id),
    CONSTRAINT FK_employees_lcat FOREIGN KEY(lcat_id)
        REFERENCES labor_categories(lcat_id),
    CONSTRAINT FK_employees_org FOREIGN KEY(org_id)
        REFERENCES organizations(org_id),
    CONSTRAINT FK_employees_vendor FOREIGN KEY (vendor_id)
        REFERENCES vendors(vendor_id),
    CONSTRAINT FK_employees_location FOREIGN KEY (location_id)
        REFERENCES locations(location_id),
    CONSTRAINT FK_employees_cost_center FOREIGN KEY (cost_center_id)
        REFERENCES cost_centers(cost_center_id),
    CONSTRAINT CK_employees_clearance CHECK(
        clearance_level IN('None', 'Secret', 'TS', 'TS/SCI')
    ),
    CONSTRAINT CK_employees_labor_type CHECK(
        labor_type IN('Direct', 'Indirect', 'Overhead')
    ),
    CONSTRAINT CK_employees_employment_type CHECK(
        employment_type IN('Full-Time', 'Part-Time', 'Consultant')
    )
);
GO

-- -----------------------------------------------------------------------------
-- program_assignments
-- Many-to-many relationship between employees and programs. An employee
-- can be assigned to multiple programs simultaneously; a program can have
-- many employees. Tracks role on program, assignment dates, and active
-- status for staffing mix and utilization analysis.
-- -----------------------------------------------------------------------------
CREATE TABLE program_assignments(
    assignment_id   INT     IDENTITY(1,1)    NOT NULL,
    employee_id     INT                      NOT NULL,
    program_id      INT                      NOT NULL,
    assignment_start  DATE                  NOT NULL,
    assignment_end    DATE                       NULL,
    role_on_program     NVARCHAR(100)        NOT NULL,
    is_active   BIT  NOT NULL DEFAULT 1,

    CONSTRAINT PK_program_assignments PRIMARY KEY(assignment_id),
    CONSTRAINT FK_assignments_employee FOREIGN KEY(employee_id)
        REFERENCES employees(employee_id),
    CONSTRAINT FK_assignments_program FOREIGN KEY(program_id)
        REFERENCES programs(program_id),
    CONSTRAINT CK_assignments_dates CHECK(
        assignment_end IS NULL OR assignment_end >= assignment_start
    )
);
GO

-- -----------------------------------------------------------------------------
-- labor_rates
-- Vendor-specific billing rates by labor category. Tracks effective and
-- expiration dates to support historical rate analysis and escalation
-- trending. Multiple rate types allow comparison of proposed vs.
-- negotiated vs. ceiling rates across vendors and labor categories.
-- -----------------------------------------------------------------------------
CREATE TABLE labor_rates(
    rate_id     INT     IDENTITY(1,1)   NOT NULL,
    lcat_id     INT                     NOT NULL,
    vendor_id   INT                     NOT NULL,
    effective_date  DATE                NOT NULL,
    expiration_date  DATE                   NULL,
    hourly_rate DECIMAL(10,2)           NOT NULL,
    overtime_rate DECIMAL(10,2)             NULL,
    rate_type NVARCHAR(20)              NOT NULL,

    CONSTRAINT PK_labor_rates PRIMARY KEY(rate_id),
    CONSTRAINT FK_labor_rates_lcat FOREIGN KEY(lcat_id)
        REFERENCES labor_categories(lcat_id),
    CONSTRAINT FK_labor_rates_vendor FOREIGN KEY(vendor_id)
        REFERENCES vendors(vendor_id),
    CONSTRAINT CK_labor_rates_type CHECK(
        rate_type IN('Base', 'Escelated', 'Calling', 'Proposed', 'Negotiated')
    ),
    CONSTRAINT CK_labor_rates_hourly CHECK(hourly_rate>0),
    CONSTRAINT CK_labor_rates_overtime CHECK(
        overtime_rate IS NULL OR overtime_rate >= hourly_rate
    ),
    CONSTRAINT CK_labor_rates_dates CHECK(
        expiration_date IS NULL OR expiration_date >= effective_date
    )
);
GO

-- -----------------------------------------------------------------------------
-- timesheets
-- Periodic time and cost records for each employee against a program and
-- cost center. Captures regular/overtime hours, billable/non-billable
-- splits, and applied rates. Primary source for utilization calculations,
-- burn-rate analysis, and labor cost reporting.
-- -----------------------------------------------------------------------------
CREATE TABLE timesheets(
    timesheet_id INT                NOT NULL,
    employee_id INT                  NOT NULL,
    program_id  INT                 NOT NULL,
    cost_center_id INT              NOT NULL,
    fiscal_year INT                 NOT NULL,
    fiscal_month    INT              NOT NULL,
    period_start_date    DATE       NOT NULL,
    period_end_date     DATE         NOT NULL,
    regular_hours DECIMAL(6,2)       NOT NULL DEFAULT 0,
    overtime_hours DECIMAL(6,2)      NOT NULL DEFAULT 0,
    billable_hours  DECIMAL(6,2)     NOT NULL DEFAULT 0,
    non_billable_hours DECIMAL(6,2)  NOT NULL DEFAULT 0,
    hourly_rate DECIMAL(10,2)       NOT NULL,
    overtime_rate DECIMAL(10,2)     NULL,
    is_billable     BIT             NOT NULL DEFAULT 1,
    submitted_date  DATE            NULL,
    approved_date   DATE            NULL,
    
    CONSTRAINT PK_timesheets PRIMARY KEY(timesheet_id),
    CONSTRAINT FK_timesheets_employee FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id),
    CONSTRAINT FK_timesheets_program FOREIGN KEY(program_id)
        REFERENCES programs(program_id),
    CONSTRAINT FK_timesheets_cost_center FOREIGN KEY(cost_center_id)
        REFERENCES cost_centers(cost_center_id),
    CONSTRAINT CK_timesheets_fiscal_month CHECK(
        fiscal_month BETWEEN 1 AND 12
    ),
    CONSTRAINT CK_timesheets_hours_nonneg CHECK(
        regular_hours >= 0
        AND overtime_hours >= 0
        AND billable_hours >= 0
        AND non_billable_hours >= 0
    ),
    CONSTRAINT CK_timesheets_hourly CHECK(hourly_rate>0),
    CONSTRAINT CK_timesheets_dates CHECK(
        period_end_date >= period_start_date
    ),
    CONSTRAINT CK_timesheets_approved CHECK(
        approved_date IS NULL OR submitted_date IS NOT NULL
    )
);
GO