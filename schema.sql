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