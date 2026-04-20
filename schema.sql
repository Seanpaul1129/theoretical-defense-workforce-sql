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
    domain_name NVARCHAR(100)           NOT NULL,
    domain_type NVARCHAR(50)            NOT NULL,
    description NVARCHAR(500)               NULL,

    CONSTRAINT PK_skill_domains      PRIMARY KEY (domain_id),
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
    org_id        INT     IDENTITY(1,1)   NOT NULL,
    org_name      NVARCHAR(150)           NOT NULL,
    org_code      NVARCHAR(20)            NOT NULL,   
    org_type      NVARCHAR(50)            NOT NULL,
    parent_org_id INT                         NULL,
    CONSTRAINT PK_organizations      PRIMARY KEY (org_id),
    CONSTRAINT UQ_organizations_code UNIQUE (org_code),
    CONSTRAINT CK_organizations_type CHECK(
        org_type IN('Directorate', 'Division', 'Branch', 'Team', 'Office')
    )
);
GO

-- Self-referencing FK added via ALTER
ALTER TABLE organizations
    ADD CONSTRAINT FK_organizations_parent FOREIGN KEY (parent_org_id) 
        REFERENCES organizations(org_id);
GO

-- -----------------------------------------------------------------------------
-- vendors
-- Contractor companies providing labor to defense programs. Tracks vendor
-- identity, contract vehicle, and active status for rate analysis and
-- vendor performance comparisons.
-- -----------------------------------------------------------------------------
CREATE TABLE vendors (
    vendor_id        INT     IDENTITY(1,1)    NOT NULL,
    vendor_name      NVARCHAR(150)            NOT NULL,
    vendor_code      NVARCHAR(20)             NOT NULL,
    vendor_type      NVARCHAR(50)             NOT NULL,
    contract_vehicle NVARCHAR(100)                NULL,
    is_active        BIT                      NOT NULL DEFAULT 1,
    CONSTRAINT PK_vendors      PRIMARY KEY (vendor_id),
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
    program_id    INT     IDENTITY(1,1)   NOT NULL,
    program_name  NVARCHAR(150)           NOT NULL,
    program_code  NVARCHAR(20)            NOT NULL,
    contract_type NVARCHAR(10)            NOT NULL,
    program_phase NVARCHAR(20)            NOT NULL,
    start_date    DATE                    NOT NULL,
    end_date      DATE                        NULL,
    is_active     BIT                      NOT NULL DEFAULT 1,

    CONSTRAINT PK_programs               PRIMARY KEY (program_id),
    CONSTRAINT UQ_programs_code          UNIQUE (program_code),
    CONSTRAINT CK_programs_contract_type CHECK(
        contract_type IN('FFP', 'CPFF', 'CPAF', 'CPIF', 'T&M', 'IDIQ', 'BPA')
    ),
    CONSTRAINT CK_programs_phase         CHECK(
        program_phase IN('Pre-Award', 'Active', 'Close-Out', 'Completed')
    ),
    CONSTRAINT CK_programs_dates         CHECK(
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
    location_id   INT     IDENTITY(1,1)    NOT NULL,
    location_name NVARCHAR(150)            NOT NULL,
    city          NVARCHAR(100)            NOT NULL,
    state_code    CHAR(2)                  NOT NULL,
    site_type     NVARCHAR(50)             NOT NULL,
    is_scif       BIT                      NOT NULL DEFAULT 0,

    CONSTRAINT PK_locations           PRIMARY KEY (location_id),
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
    lcat_id      INT    IDENTITY(1,1)    NOT NULL,
    lcat_name    NVARCHAR(150)           NOT NULL,
    domain_id    INT                     NOT NULL,
    labor_type   NVARCHAR(50)            NOT NULL,
    is_technical BIT                     NOT NULL DEFAULT 1,

    CONSTRAINT PK_labor_categories        PRIMARY KEY (lcat_id),
    CONSTRAINT FK_labor_categories_domain FOREIGN KEY (domain_id)
        REFERENCES skill_domains(domain_id),
    CONSTRAINT CK_labor_categories_type   CHECK(
        labor_type IN('Engineering', 'Analysis', 'Management', 'Administrative', 'Technical')
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
    cost_center_id   INT    IDENTITY(1,1)    NOT NULL,
    cost_center_code NVARCHAR(20)            NOT NULL,
    cost_center_name NVARCHAR(150)           NOT NULL,
    charge_type      NVARCHAR(20)            NOT NULL,
    program_id       INT                     NOT NULL,
    is_active        BIT                     NOT NULL DEFAULT 1,

    CONSTRAINT PK_cost_centers             PRIMARY KEY (cost_center_id),
    CONSTRAINT UQ_cost_centers_code        UNIQUE (cost_center_code),
    CONSTRAINT FK_cost_centers_program     FOREIGN KEY(program_id)
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
    employee_id     INT     IDENTITY(1,1)   NOT NULL,
    first_name      NVARCHAR(100)           NOT NULL,
    last_name       NVARCHAR(100)           NOT NULL,
    lcat_id         INT                     NOT NULL,
    org_id          INT                     NOT NULL,
    vendor_id       INT                     NOT NULL,
    location_id     INT                     NOT NULL,
    cost_center_id  INT                     NOT NULL,
    hire_date       DATE                    NOT NULL,
    labor_grade     NVARCHAR(10)                NULL,
    clearance_level NVARCHAR(20)            NOT NULL,
    is_billable     BIT                     NOT NULL DEFAULT 1,
    labor_type      NVARCHAR(20)            NOT NULL,
    employment_type NVARCHAR(20)            NOT NULL,
    is_active       BIT                     NOT NULL DEFAULT 1,

    CONSTRAINT PK_employees                 PRIMARY KEY(employee_id),
    CONSTRAINT FK_employees_lcat            FOREIGN KEY(lcat_id)
        REFERENCES labor_categories(lcat_id),
    CONSTRAINT FK_employees_org             FOREIGN KEY(org_id)
        REFERENCES organizations(org_id),
    CONSTRAINT FK_employees_vendor          FOREIGN KEY (vendor_id)
        REFERENCES vendors(vendor_id),
    CONSTRAINT FK_employees_location        FOREIGN KEY (location_id)
        REFERENCES locations(location_id),
    CONSTRAINT FK_employees_cost_center     FOREIGN KEY (cost_center_id)
        REFERENCES cost_centers(cost_center_id),
    CONSTRAINT CK_employees_clearance       CHECK(
        clearance_level IN('None', 'Secret', 'TS', 'TS/SCI')
    ),
    CONSTRAINT CK_employees_labor_type      CHECK(
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
    assignment_id    INT     IDENTITY(1,1)    NOT NULL,
    employee_id      INT                      NOT NULL,
    program_id       INT                      NOT NULL,
    assignment_start DATE                     NOT NULL,
    assignment_end   DATE                         NULL,
    role_on_program  NVARCHAR(100)            NOT NULL,
    is_active        BIT                      NOT NULL DEFAULT 1,

    CONSTRAINT PK_program_assignments  PRIMARY KEY(assignment_id),
    CONSTRAINT FK_assignments_employee FOREIGN KEY(employee_id)
        REFERENCES employees(employee_id),
    CONSTRAINT FK_assignments_program  FOREIGN KEY(program_id)
        REFERENCES programs(program_id),
    CONSTRAINT CK_assignments_dates    CHECK(
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
    rate_id         INT     IDENTITY(1,1)   NOT NULL,
    lcat_id         INT                     NOT NULL,
    vendor_id       INT                     NOT NULL,
    effective_date  DATE                    NOT NULL,
    expiration_date DATE                        NULL,
    hourly_rate     DECIMAL(10,2)           NOT NULL,
    overtime_rate   DECIMAL(10,2)               NULL,
    rate_type       NVARCHAR(20)            NOT NULL,

    CONSTRAINT PK_labor_rates          PRIMARY KEY(rate_id),
    CONSTRAINT FK_labor_rates_lcat     FOREIGN KEY(lcat_id)
        REFERENCES labor_categories(lcat_id),
    CONSTRAINT FK_labor_rates_vendor   FOREIGN KEY(vendor_id)
        REFERENCES vendors(vendor_id),
    CONSTRAINT CK_labor_rates_type     CHECK(
        rate_type IN('Base', 'Escalated', 'Ceiling', 'Proposed', 'Negotiated')
    ),
    CONSTRAINT CK_labor_rates_hourly   CHECK(hourly_rate>0),
    CONSTRAINT CK_labor_rates_overtime CHECK(
        overtime_rate IS NULL OR overtime_rate >= hourly_rate
    ),
    CONSTRAINT CK_labor_rates_dates    CHECK(
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
    timesheet_id       INT      IDENTITY(1,1)   NOT NULL,
    employee_id        INT                      NOT NULL,
    program_id         INT                      NOT NULL,
    cost_center_id     INT                      NOT NULL,
    fiscal_year        INT                      NOT NULL,
    fiscal_month       INT                      NOT NULL,
    period_start_date  DATE                     NOT NULL,
    period_end_date    DATE                     NOT NULL,
    regular_hours      DECIMAL(6,2)             NOT NULL DEFAULT 0,
    overtime_hours     DECIMAL(6,2)             NOT NULL DEFAULT 0,
    billable_hours     DECIMAL(6,2)             NOT NULL DEFAULT 0,
    non_billable_hours DECIMAL(6,2)             NOT NULL DEFAULT 0,
    hourly_rate        DECIMAL(10,2)            NOT NULL,
    overtime_rate      DECIMAL(10,2)                NULL,
    is_billable        BIT                      NOT NULL DEFAULT 1,
    submitted_date     DATE                         NULL,
    approved_date      DATE                         NULL,
    
    CONSTRAINT PK_timesheets              PRIMARY KEY(timesheet_id),
    CONSTRAINT FK_timesheets_employee     FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id),
    CONSTRAINT FK_timesheets_program      FOREIGN KEY(program_id)
        REFERENCES programs(program_id),
    CONSTRAINT FK_timesheets_cost_center  FOREIGN KEY(cost_center_id)
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
    CONSTRAINT CK_timesheets_hourly       CHECK(hourly_rate>0),
    CONSTRAINT CK_timesheets_dates        CHECK(
        period_end_date >= period_start_date
    ),
    CONSTRAINT CK_timesheets_approved     CHECK(
        approved_date IS NULL OR submitted_date IS NOT NULL
    )
);
GO

-- =============================================================================
-- INDEXES
-- Strategic indexes on foreign key columns and common analytical filter
-- columns. Each index includes a comment explaining its purpose.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Foreign key indexes
-- SQL Server does not automatically index FK columns. Adding these prevents
-- full table scans on JOINs across the schema's many analytical queries.
-- ---------------------------------------------------------------------------

-- labor_categories → skill_domains
CREATE INDEX IX_labor_categories_domain_id
    ON labor_categories(domain_id);
GO

-- organizations → organizations (self-reference)
CREATE INDEX IX_organizations_parent_org_id
    ON organizations(parent_org_id);
GO

-- cost_centers → programs
CREATE INDEX IX_cost_centers_program_id
    ON cost_centers(program_id);
GO

-- employees → all five parents
CREATE INDEX IX_employees_lcat_id
    ON employees(lcat_id);
GO

CREATE INDEX IX_employees_org_id
    ON employees(org_id);
GO

CREATE INDEX IX_employees_vendor_id
    ON employees(vendor_id);
GO

CREATE INDEX IX_employees_location_id
    ON employees(location_id);
GO

CREATE INDEX IX_employees_cost_center_id
    ON employees(cost_center_id);
GO

-- program_assignments → employees, programs
CREATE INDEX IX_assignments_employee_id
    ON program_assignments(employee_id);
GO

CREATE INDEX IX_assignments_program_id
    ON program_assignments(program_id);
GO

-- labor_rates → labor_categories, vendors
CREATE INDEX IX_labor_rates_lcat_id
    ON labor_rates(lcat_id);
GO

CREATE INDEX IX_labor_rates_vendor_id
    ON labor_rates(vendor_id);
GO

-- timesheets → employees, programs, cost_centers
CREATE INDEX IX_timesheets_employee_id
    ON timesheets(employee_id);
GO

CREATE INDEX IX_timesheets_program_id
    ON timesheets(program_id);
GO

CREATE INDEX IX_timesheets_cost_center_id
    ON timesheets(cost_center_id);
GO

-- ---------------------------------------------------------------------------
-- Analytical filter indexes
-- Columns frequently used in WHERE clauses across reporting queries.
-- ---------------------------------------------------------------------------

-- Active employee filter (very common across utilization queries)
CREATE INDEX IX_employees_is_active
    ON employees(is_active);
GO

-- Billable vs. non-billable filter for utilization analysis
CREATE INDEX IX_employees_is_billable
    ON employees(is_billable);
GO

-- Fiscal period filters on timesheets (most common analytical filter)
CREATE INDEX IX_timesheets_fiscal_year_month
    ON timesheets(fiscal_year, fiscal_month);
GO

-- Labor rate lookup by effective date (for historical rate queries)
CREATE INDEX IX_labor_rates_effective_date
    ON labor_rates(effective_date);
GO

-- Program phase filter (active vs. completed program reporting)
CREATE INDEX IX_programs_phase
    ON programs(program_phase);
GO

-- =============================================================================
-- VIEWS
-- Analytical views representing common reporting outputs. Each view answers
-- a specific business question. Views are used to simplify queries for
-- end users and to enforce consistent analytical logic across reports.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- v_active_billable_workforce
-- All active, billable employees with their core assignments denormalized.
-- Most common starting point for utilization and staffing queries.
-- ---------------------------------------------------------------------------

CREATE VIEW v_active_billable_workforce AS
SELECT
    e.employee_id,
    e.first_name + ' '+ e.last_name AS full_name,
    e.hire_date,
    e.clearance_level,
    e.labor_grade,
    lc.lcat_name,
    sd.domain_name                  AS skill_domain,
    o.org_name,
    v.vendor_name,
    l.location_name,
    l.city,
    l.state_code,
    cc.cost_center_code,
    cc.cost_center_name,
    p.program_name
FROM employees e
    INNER JOIN labor_categories lc ON e.lcat_id = lc.lcat_id
    INNER JOIN skill_domains sd    ON lc.domain_id = sd.domain_id
    INNER JOIN organizations o     ON e.org_id = o.org_id
    INNER JOIN vendors v           ON e.vendor_id = v.vendor_id
    INNER JOIN locations l         ON e.location_id = l.location_id
    INNER JOIN cost_centers cc     ON e.cost_center_id = cc.cost_center_id
    INNER JOIN programs p          ON cc.program_id = p.program_id
WHERE e.is_active = 1
    AND e.is_billable = 1;
GO

-- ---------------------------------------------------------------------------
-- v_program_burn_rate
-- Labor cost burn-rate per program per fiscal period. Calculated as total
-- billable hours times the applied hourly rate. Supports burn-rate vs.
-- plan analysis and program financial health reporting.
-- ---------------------------------------------------------------------------
CREATE VIEW v_program_burn_rate AS
SELECT
    p.program_id,
    p.program_name,
    p.program_code,
    p.contract_type,
    t.fiscal_year,
    t.fiscal_month,
    SUM(t.billable_hours)                             AS total_billable_hours,
    SUM(t.regular_hours + t.overtime_hours)           AS total_hours,
    SUM(t.billable_hours * t.hourly_rate)             AS total_labor_cost,
    SUM(t.overtime_hours * ISNULL(t.overtime_rate,0)) AS total_overtime_cost,
    COUNT(DISTINCT t.employee_id)                     AS unique_employees
FROM timesheets t
    INNER JOIN programs p ON t.program_id = p.program_id
GROUP BY 
    p.program_id,
    p.program_name,
    p.program_code,
    p.contract_type,
    t.fiscal_year,
    t.fiscal_month;
GO

-- ---------------------------------------------------------------------------
-- v_vendor_rate_comparison
-- Current (non-expired) hourly rate comparison across vendors for the same
-- labor category. Enables side-by-side vendor pricing analysis for sourcing
-- decisions and rate reasonableness assessments.
-- ---------------------------------------------------------------------------
CREATE VIEW v_vendor_rate_comparison AS
SELECT
    lc.lcat_id,
    lc.lcat_name,
    sd.domain_name,
    v.vendor_id,
    v.vendor_name,
    lr.rate_type,
    lr.effective_date,
    lr.expiration_date,
    lr.hourly_rate,
    lr.overtime_rate
FROM labor_rates lr
    INNER JOIN labor_categories lc ON lr.lcat_id = lc.lcat_id
    INNER JOIN skill_domains sd    ON lc.domain_id = sd.domain_id
    INNER JOIN vendors v           ON lr.vendor_id = v.vendor_id
WHERE (lr.expiration_date IS NULL OR lr.expiration_date >= CAST(GETDATE() AS DATE))
    AND v.is_active = 1;
GO

-- ---------------------------------------------------------------------------
-- v_skill_domain_coverage
-- Headcount of active, billable workforce by skill domain. Used to identify
-- workforce gaps and inform hiring or contracting priorities.
-- ---------------------------------------------------------------------------
CREATE VIEW v_skill_domain_coverage AS
SELECT
    sd.domain_id,
    sd.domain_name,
    sd.domain_type,
    COUNT(DISTINCT e.employee_id) AS active_headcount,
    COUNT(DISTINCT CASE WHEN e.clearance_level IN('TS', 'TS/SCI') THEN e.employee_id END
                    )             AS ts_cleared_headcount,
    COUNT(DISTINCT e.vendor_id)   AS vendor_count,
    COUNT(DISTINCT e.org_id)      AS org_count
FROM skill_domains sd
    LEFT JOIN labor_categories lc ON sd.domain_id = lc.domain_id
    LEFT JOIN employees e         ON lc.lcat_id = e.lcat_id 
        AND e.is_active = 1
        AND e.is_billable = 1
GROUP BY 
    sd.domain_id,
    sd.domain_name,
    sd.domain_type;
GO