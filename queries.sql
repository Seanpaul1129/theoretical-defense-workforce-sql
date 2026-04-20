-- =============================================================================
-- queries.sql
-- Defense Workforce & Labor Analytics Database — Representative Queries
--
-- Dialect:  Microsoft SQL Server (T-SQL)
-- Author:   Seanpaul Coffey
-- Date:     April 2026
--
-- Purpose:  Demonstrates analytical SELECT queries commonly run against the
--           database, plus representative INSERT, UPDATE, and DELETE
--           operations for typical workforce management transactions.
--
-- Notes:    All queries assume seed_data.sql has been executed. Results
--           reference fictional entities only.
-- =============================================================================

USE DefenseWorkforce;
GO

-- =============================================================================
-- ANALYTICAL SELECT QUERIES
-- =============================================================================

-- ------------------------------------------------------------------------------
-- Q1: Active billable workforce roster
-- Returns a full roster of all active, billable employees with their labor
-- category, vendor, and work location. Used by division chiefs for headcount
-- visibility and staffing reviews.
-- Concepts Used: basic join, filter, ORDER BY
-- ------------------------------------------------------------------------------
SELECT
    e.first_name + ' ' + e.last_name AS full_name,
    lc.lcat_name                     AS job_title,
    v.vendor_name                    AS vendor_company,
    l.location_name
FROM employees e
    INNER JOIN labor_categories lc ON e.lcat_id = lc.lcat_id
    INNER JOIN vendors v           ON e.vendor_id = v.vendor_id
    INNER JOIN locations l         ON e.location_id = l.location_id
WHERE e.is_active = 1
    AND e.is_billable = 1
ORDER BY e.last_name ASC
;

-- ------------------------------------------------------------------------------
-- Q2: Total labor cost by program and fiscal year
-- Aggregates billable hours and labor cost (billable hours x hourly rate) per
-- program per fiscal year. Used by finance directors for annual cost reporting
-- and budget-to-actual comparisons.
-- Concepts Used: aggregation, join, GROUP BY
-- ------------------------------------------------------------------------------
SELECT
    p.program_name,
    t.fiscal_year,
    COALESCE(SUM(t.billable_hours), 0)                AS total_billable_hours,
    COALESCE(SUM(t.billable_hours * t.hourly_rate),0) AS total_labor_cost
FROM programs p
    LEFT JOIN timesheets t ON p.program_id = t.program_id
GROUP BY 
    p.program_name,
    t.fiscal_year
ORDER BY p.program_name ASC, t.fiscal_year ASC
;

-- ------------------------------------------------------------------------------
-- Q3: Vendors with more than 3 active employees
-- Identifies vendors with significant workforce presence. Used by workforce
-- planning leads to understand vendor concentration and dependency risk.
-- Concepts Used: aggregation, GROUP BY, HAVING
-- ------------------------------------------------------------------------------
SELECT
    v.vendor_name,
    COUNT(e.employee_id) AS employee_count
FROM vendors v
    LEFT JOIN employees e ON v.vendor_id = e.vendor_id
WHERE e.is_active = 1
GROUP BY v.vendor_id, v.vendor_name
HAVING COUNT(e.employee_id) > 3
ORDER BY employee_count DESC
;

-- ------------------------------------------------------------------------------
-- Q4: Labor categories with rates from multiple vendors
-- Finds labor categories where competitive rate comparison is possible. Used
-- by contracts managers to identify opportunities for rate benchmarking
-- during proposal evaluations.
-- Concepts Used: JOIN with aggregation, HAVING
-- ------------------------------------------------------------------------------
SELECT
    lc.lcat_name,
    COUNT(DISTINCT v.vendor_id) AS distinct_vendors
FROM labor_categories lc
    INNER JOIN labor_rates lr ON lc.lcat_id = lr.lcat_id
    INNER JOIN vendors v      ON lr.vendor_id = v.vendor_id
GROUP BY lc.lcat_id, lc.lcat_name
HAVING COUNT(DISTINCT v.vendor_id) >= 2
;

-- ------------------------------------------------------------------------------
-- Q5: Employee hourly rate ranking within each skill domain
-- Ranks employees from highest to lowest hourly rate within their skill
-- domain. Used by cost analysts to identify rate outliers and inform
-- rate reasonableness assessments.
-- Concepts Used: window function — RANK, multi-table join
-- ------------------------------------------------------------------------------
SELECT
    sd.domain_name,
    e.first_name + ' ' + e.last_name                                    AS full_name,
    v.vendor_name,
    lr.hourly_rate,
    RANK() OVER(PARTITION BY sd.domain_id ORDER BY lr.hourly_rate DESC) AS rate_rank
FROM employees e
    INNER JOIN labor_categories lc ON e.lcat_id = lc.lcat_id
    INNER JOIN skill_domains sd    ON lc.domain_id = sd.domain_id
    INNER JOIN vendors v           ON e.vendor_id = v.vendor_id
    INNER JOIN labor_rates lr      ON v.vendor_id = lr.vendor_id 
        AND lr.lcat_id = lc.lcat_id 
WHERE e.is_active = 1
;

-- ------------------------------------------------------------------------------

-- Q6: Current Charizard program team roster
-- Lists everyone currently assigned to the Charizard program with their
-- role, vendor, and assignment start date. Used by the program manager
-- for team visibility and staffing coordination.
-- Concepts Used: multi-table join, date filter
-- ------------------------------------------------------------------------------
SELECT
    e.first_name + ' ' + e.last_name AS full_name,
    pa.role_on_program,
    v.vendor_name,
    pa.assignment_start
FROM program_assignments pa
    INNER JOIN employees e  ON pa.employee_id = e.employee_id
    INNER JOIN vendors v    ON e.vendor_id = v.vendor_id
    INNER JOIN programs p   ON pa.program_id = p.program_id
WHERE p.program_name = 'Charizard' 
    AND (pa.assignment_end IS NULL OR pa.assignment_end >= GETDATE())
;

-- ------------------------------------------------------------------------------
-- Q7: Clearance level breakdown across active workforce
-- Shows headcount and percentage of total for each clearance level among
-- active employees. Used by the security office for compliance reporting
-- and clearance pipeline planning.
-- Concepts Used: aggregation, CASE WHEN or CAST for percentage
-- ------------------------------------------------------------------------------
SELECT
    clearance_level,
    COUNT(employee_id) AS number_of_employees,
    CAST(COUNT(employee_id) AS DECIMAL(5,2)) * 100 / (
                        SELECT COUNT(employee_id) 
                        FROM employees 
                        WHERE is_active = 1
                      ) AS percent_of_employees
FROM employees
WHERE is_active = 1
GROUP BY clearance_level
;

-- ------------------------------------------------------------------------------
-- Q8: Month-over-month labor cost trend for Charizard
-- Shows each fiscal period's labor cost alongside the previous period's
-- cost and the dollar change between them. Used by the CFO to monitor
-- spending trajectory and flag unexpected cost spikes.
-- Concepts Used: window function — LAG, join, non-recursive CTE, ORDER BY
-- ------------------------------------------------------------------------------
WITH monthly_cost AS(
    SELECT  
        t.fiscal_year,
        t.fiscal_month,
        SUM((t.regular_hours * t.hourly_rate)+(t.overtime_hours * ISNULL(t.overtime_rate, 0))) AS total_cost
    FROM timesheets t
        INNER JOIN programs p ON t.program_id = p.program_id
    WHERE p.program_name = 'Charizard'
    GROUP BY 
        t.fiscal_year,
        t.fiscal_month
    )

SELECT
    fiscal_year,
    fiscal_month,
    total_cost,
    LAG(total_cost) OVER(ORDER BY fiscal_year, fiscal_month)              AS prev_month_cost,
    total_cost - LAG(total_cost) OVER(ORDER BY fiscal_year, fiscal_month) AS month_change
FROM monthly_cost
;

-- ------------------------------------------------------------------------------
-- Q9: Full organizational hierarchy
-- Displays every organization from directorate down to branch with its
-- parent org name and hierarchy level. Used by the deputy director to
-- visualize the org structure and validate reporting chains.
-- Concepts Used: recursive CTE
-- ------------------------------------------------------------------------------
WITH org_tree AS(
    SELECT
        org_id,
        org_name,
        org_type,
        parent_org_id,
        1 AS level
    FROM organizations
    WHERE parent_org_id IS NULL

    UNION ALL

    SELECT
        o.org_id,
        o.org_name,
        o.org_type,
        o.parent_org_id,
        ot.level + 1
    FROM organizations o
        INNER JOIN org_tree ot ON o.parent_org_id = ot.org_id
)

SELECT
    ot.org_id,
    ot.org_name,
    ot.org_type,
    ot.parent_org_id,
    ot.level,
    o.org_name AS parent_org_name
FROM org_tree ot
    LEFT JOIN organizations o ON ot.parent_org_id = o.org_id
ORDER BY ot.level, ot.org_name
;

-- ------------------------------------------------------------------------------
-- Q10: Negotiated vs. proposed rate comparison
-- Side-by-side comparison of negotiated and proposed rates for the same
-- labor category across different vendors. Used by procurement analysts
-- to assess whether proposed rates are reasonable relative to existing
-- negotiated benchmarks.
-- Concepts Used: complex join, comparison
-- ------------------------------------------------------------------------------
SELECT
    lc.lcat_name                        AS labor_category,
    v_n.vendor_name                     AS negotiated_vendor,
    v_p.vendor_name                     AS proposed_vendor,
    lr_n.hourly_rate                    AS negotiated_rate,
    lr_p.hourly_rate                    AS proposed_rate,
    lr_n.hourly_rate - lr_p.hourly_rate AS rate_difference
FROM labor_rates lr_n
    INNER JOIN labor_rates lr_p     ON lr_n.lcat_id = lr_p.lcat_id
        AND lr_n.vendor_id <> lr_p.vendor_id
    INNER JOIN vendors v_n          ON lr_n.vendor_id = v_n.vendor_id
    INNER JOIN  vendors v_p         ON lr_p.vendor_id = v_p.vendor_id
    INNER JOIN labor_categories lc  ON lr_n.lcat_id = lc.lcat_id
WHERE lr_n.rate_type = 'Negotiated'
    AND lr_p.rate_type = 'Proposed'
;

-- ------------------------------------------------------------------------------
-- Q11: Employee utilization report with underutilization flag
-- Calculates average monthly billable hours per employee and flags anyone
-- averaging under 140 hours as underutilized. Used by workforce planning
-- directors to identify staffing inefficiencies and reallocation opportunities.
-- Concepts Used: aggregation, multiple joins, CASE WHEN
-- ------------------------------------------------------------------------------
SELECT
    e.first_name + ' ' + e.last_name AS full_name,
    v.vendor_name,
    AVG(t.billable_hours)            AS avg_billable_hours,
    CASE
        WHEN AVG(t.billable_hours) >= 140 THEN 'On Track' ELSE 'Underutilized'
        END                          AS utilization_flag
FROM employees e
    INNER JOIN timesheets t ON e.employee_id = t.employee_id
    INNER JOIN vendors v    ON e.vendor_id = v.vendor_id
WHERE e.is_billable = 1
    AND e.is_active = 1
GROUP BY 
    e.first_name + ' ' + e.last_name, 
    v.vendor_name
ORDER BY AVG(t.billable_hours) DESC
;

-- ------------------------------------------------------------------------------
-- Q12: Active employees with no program assignment
-- Identifies employees on the payroll who have never been assigned to any
-- program. These may be overhead-only staff, new hires pending assignment,
-- or potential staffing gaps. Used by the HR lead for workforce alignment.
-- Concepts Used: correlated subquery or NOT EXISTS
-- ------------------------------------------------------------------------------
SELECT
    e.first_name + ' ' + e.last_name AS full_name,
    v.vendor_name,
    o.org_name,
    e.hire_date
FROM employees e
    INNER JOIN vendors v       ON e.vendor_id = v.vendor_id
    INNER JOIN organizations o ON e.org_id = o.org_id
WHERE e.is_active = 1
    AND NOT EXISTS (
                    SELECT 1
                    FROM program_assignments pa
                    WHERE pa.employee_id = e.employee_id
                    )
;

-- =============================================================================
-- INSERT STATEMENTS
-- Representative business transactions for adding new records.
-- =============================================================================

-- ------------------------------------------------------------------------------
-- I1: New employee onboarding
-- Aristotle Stagira was just hired as a Software Engineer II (lcat_id 4),
-- assigned to the Analytics Branch (org_id 9), working for Silver Otter
-- Analytics (vendor_id 3), at Summit Ridge Center (location_id 3), charging
-- to Venusaur Direct Labor (cost_center_id 5). TS clearance, grade G10,
-- billable, direct, full-time, active. Start date is today.
-- ------------------------------------------------------------------------------
INSERT INTO employees (first_name, last_name, lcat_id, org_id, vendor_id, location_id, cost_center_id, hire_date, labor_grade, clearance_level, is_billable, labor_type, employment_type, is_active) VALUES
('Aristotle', 'Stagira', 4, 9, 3, 3, 5, '2026-04-19', 'G10', 'TS', 1, 'Direct', 'Full-Time', 1 )
;

-- ------------------------------------------------------------------------------
-- I2: New vendor labor rate submission
-- Silver Otter Analytics submitted a new proposed rate for the Software
-- Engineer II labor category (lcat_id 4). Proposed hourly rate is $125.00,
-- overtime rate is $187.50, effective today, no expiration. Rate type is
-- 'Proposed'.
-- ------------------------------------------------------------------------------
INSERT INTO labor_rates (lcat_id, vendor_id, effective_date, expiration_date, hourly_rate, overtime_rate, rate_type) VALUES
(4, 3, '2026-04-19', NULL, 125.00, 187.50, 'Proposed')
;

-- ------------------------------------------------------------------------------
-- I3: Program assignment for new employee
-- Aristotle Stagira (employee_id 31 — the employee just inserted in I1)
-- is assigned to the Venusaur program (program_id 3) starting today.
-- Role is 'Software Engineer'. Assignment is active with no end date.
-- ------------------------------------------------------------------------------
INSERT INTO program_assignments (employee_id, program_id, assignment_start, assignment_end, role_on_program, is_active) VALUES
(31, 3, '2026-04-19', NULL, 'Software Engineer', 1)
;

-- ------------------------------------------------------------------------------
-- I4: First timesheet submission
-- Aristotle Stagira submitted his first timesheet for the current fiscal
-- period on the Venusaur program (program_id 3), charging to cost center 5.
-- Fiscal year 2026, fiscal month 7 (April). Period: April 1-30, 2026.
-- 168 regular hours, 0 overtime, 168 billable, 0 non-billable.
-- Hourly rate $125.00, no overtime rate. Billable. Submitted today,
-- not yet approved.
-- ------------------------------------------------------------------------------
INSERT INTO timesheets (employee_id, program_id, cost_center_id, fiscal_year, fiscal_month, period_start_date, period_end_date, regular_hours, overtime_hours, billable_hours, non_billable_hours, hourly_rate, overtime_rate, is_billable, submitted_date, approved_date) VALUES
(31, 3, 5, 2026, 07, '2026-04-01', '2026-04-30', 168, 0, 168, 0, 125.00, NULL, 1, '2026-04-19', NULL)
;

-- =============================================================================
-- UPDATE STATEMENTS
-- Representative business transactions for modifying existing records.
-- =============================================================================

-- ------------------------------------------------------------------------------
-- U1: Program completion
-- The Snorlax program has finished its close-out phase. Update its
-- program_phase to 'Completed' and set is_active to 0.
-- ------------------------------------------------------------------------------
UPDATE programs
    SET program_phase = 'Completed', 
        is_active = 0 
    WHERE program_name = 'Snorlax'
;

-- ------------------------------------------------------------------------------
-- U2: Vendor rate escalation
-- Blue Heron Data's contract rates are being escalated by 3.5%. Increase
-- all of their active (non-expired) hourly rates and overtime rates by
-- 3.5%, rounded to 2 decimal places.
-- ------------------------------------------------------------------------------
UPDATE labor_rates
    SET hourly_rate = ROUND(hourly_rate * 1.035, 2),
        overtime_rate = ROUND(overtime_rate *1.035, 2)
    WHERE vendor_id = (SELECT vendor_id FROM vendors WHERE vendor_name = 'Blue Heron Data')
        AND (expiration_date IS NULL OR expiration_date >= CAST(GETDATE() AS DATE))
;

-- ------------------------------------------------------------------------------
-- U3: Timesheet approval
-- Aristotle Stagira's timesheet from I4 was just approved. Set the
-- approved_date to today. Only update timesheets for that employee
-- where submitted_date is not null and approved_date is still null.
-- ------------------------------------------------------------------------------
UPDATE timesheets
    SET approved_date = '2026-04-19'
    WHERE employee_id = (SELECT employee_id FROM employees WHERE first_name = 'Aristotle' AND last_name = 'Stagira')
        AND submitted_date IS NOT NULL
        AND approved_date IS NULL
;

-- =============================================================================
-- DELETE STATEMENTS
-- In production systems, soft deletes (setting is_active = 0) are generally
-- preferred over hard deletes to preserve audit trails and historical
-- reporting integrity. These examples demonstrate DELETE syntax as required.
-- =============================================================================

-- ------------------------------------------------------------------------------
-- D1: Remove erroneous labor rate record
-- A test labor rate record was accidentally inserted. Delete the last
-- proposed rate in the seed data (rate_id 21). In production, this record
-- would instead be flagged as invalid rather than permanently removed.
-- ------------------------------------------------------------------------------
DELETE FROM labor_rates 
WHERE rate_id = 21
;

-- ------------------------------------------------------------------------------
-- D2: Remove completed program assignments
-- Clean up program assignments for the Snorlax program (program_id 6),
-- which was marked Completed in U1. In production, these would be soft
-- deleted by setting is_active = 0 to preserve assignment history for
-- audit and reporting purposes.
-- ------------------------------------------------------------------------------
DELETE FROM program_assignments 
WHERE program_id = (SELECT program_id FROM programs WHERE program_name = 'Snorlax')
;