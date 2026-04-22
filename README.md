# Theoretical Defense Workforce & Labor Analytics Database

A normalized relational database modeling defense program labor analytics,
built in Microsoft SQL Server (T-SQL). Designed to support workforce
utilization analysis, cost-center burn tracking, vendor rate comparisons,
and program staffing decisions.

> Submitted as the final project for Harvard's CS50 SQL
> (Introduction to Databases with SQL).

## Status

✅ Schema complete — 11 tables, 20 indexes, 4 analytical views  
✅ Seed data complete — all 11 tables populated with synthetic data  
✅ Queries complete — 12 analytical SELECTs, 4 INSERTs, 3 UPDATEs, 2 DELETEs  
✅ Design documentation complete  

## Tech Stack

- Microsoft SQL Server (T-SQL)
- SQL Server Management Studio (SSMS)

## Repository Structure

| File | Description |
|------|-------------|
| `schema.sql` | CREATE TABLE, CREATE INDEX, and CREATE VIEW statements |
| `seed_data.sql` | INSERT statements populating all 11 tables with synthetic data |
| `queries.sql` | 21 representative analytical and operational queries |
| `DESIGN.md` | Technical design document with ERD and video overview |
| `diagram.png` | Entity relationship diagram |

## Database Schema

The database contains 11 normalized tables:

| Table | Purpose |
|-------|---------|
| `skill_domains` | Broad skill classifications (Engineering, Cybersecurity, etc.) |
| `labor_categories` | Specific labor roles mapped to skill domains |
| `organizations` | Hierarchical org structure (Directorate → Division → Branch) |
| `vendors` | Contractor companies providing labor |
| `programs` | Contract programs consuming labor |
| `locations` | Physical work sites |
| `cost_centers` | Charge codes tied to programs |
| `employees` | Individual workers with full assignment context |
| `program_assignments` | Many-to-many mapping of employees to programs |
| `labor_rates` | Vendor-specific billing rates by labor category |
| `timesheets` | Periodic time and cost recording |

## Analytical Views

| View | Purpose |
|------|---------|
| `v_active_billable_workforce` | Denormalized roster of the active billable workforce |
| `v_program_burn_rate` | Monthly labor cost rollups per program |
| `v_vendor_rate_comparison` | Current vendor pricing by labor category |
| `v_skill_domain_coverage` | Active headcount and clearance coverage by skill domain |

## Quick Start

```sql
-- 1. Create the database
CREATE DATABASE DefenseWorkforce;
GO

-- 2. Run schema.sql against the new database
-- 3. Run seed_data.sql to populate sample data
-- 4. Query the views
SELECT * FROM v_active_billable_workforce;
SELECT * FROM v_program_burn_rate ORDER BY fiscal_year, fiscal_month;
SELECT * FROM v_vendor_rate_comparison ORDER BY lcat_name, hourly_rate;
SELECT * FROM v_skill_domain_coverage ORDER BY active_headcount DESC;
```

## Data Disclaimer

All data in `seed_data.sql` is fictional and synthetic. Company names,
program names, personnel, and organizational structures are invented for
demonstration purposes. No real-world entities are represented.

## License

MIT