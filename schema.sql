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