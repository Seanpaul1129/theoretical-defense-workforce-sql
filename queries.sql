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
    CAST(COUNT(employee_id) AS DECIMAL(5,2) * 100 / (
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
-- (recursive CTE)
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
;