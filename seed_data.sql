-- =============================================================================
-- seed_data.sql
-- Defense Workforce & Labor Analytics Database — Sample Data
--
-- Purpose:  Populates all 11 tables with realistic synthetic data to
--           demonstrate schema behavior and enable analytical queries.
--
-- Notes:    All data is fictional. Company names, program names, personnel,
--           and organizational structures are invented for demonstration
--           purposes. No real-world entities are represented.
--
-- Usage:    Run this script AFTER schema.sql against the DefenseWorkforce
--           database. Tables must exist and be empty.
-- =============================================================================

USE DefenseWorkforce;
GO

-- ---------------------------------------------------------------------------
-- skill_domains
-- ---------------------------------------------------------------------------
INSERT INTO skill_domains (domain_name, domain_type, description) VALUES
('Systems Engineering',   'Technical',   'Integration, architecture, and lifecycle engineering disciplines'),
('Software Engineering',  'Technical',   'Software development, DevSecOps, and application engineering'),
('Cybersecurity',         'Technical',   'Security engineering, compliance, and threat operations'),
('Data Analytics',        'Technical',   'Data engineering, analysis, and visualization'),
('Program Management',    'Management',  'Program leadership, scheduling, and delivery oversight'),
('Acquisition Support',   'Functional',  'Contracts, cost analysis, and acquisition lifecycle support'),
('Configuration Mgmt',    'Functional',  'CM, change control, and baseline integrity'),
('Financial Management',  'Functional',  'Budgeting, cost reporting, and financial controls');
GO

-- ---------------------------------------------------------------------------
-- organizations (top-down hierarchy)
-- ---------------------------------------------------------------------------
INSERT INTO organizations (org_name, org_code, org_type, parent_org_id) VALUES
('Mission Systems Directorate',       'MSD',      'Directorate', NULL),
('Enterprise Services Directorate',   'ESD',      'Directorate', NULL);
GO

INSERT INTO organizations (org_name, org_code, org_type, parent_org_id) VALUES
('Ground Systems Division',           'MSD-GS',   'Division',    1),
('Space Systems Division',            'MSD-SP',   'Division',    1),
('Data Services Division',            'ESD-DS',   'Division',    2),
('Acquisition Services Division',     'ESD-AS',   'Division',    2);
GO

INSERT INTO organizations (org_name, org_code, org_type, parent_org_id) VALUES
('Ground Engineering Branch',         'MSD-GS-E', 'Branch',      3),
('Ground Operations Branch',          'MSD-GS-O', 'Branch',      3),
('Analytics Branch',                  'ESD-DS-A', 'Branch',      5),
('Cost & Pricing Branch',             'ESD-AS-C', 'Branch',      6);
GO

-- ---------------------------------------------------------------------------
-- vendors
-- ---------------------------------------------------------------------------
INSERT INTO vendors (vendor_name, vendor_code, vendor_type, contract_vehicle, is_active) VALUES
('Arctic Fox Systems',       'AFOX',    'Large Business',   'GSA MAS',         1),
('Iron Falcon Group',        'IFGP',    'Large Business',   'SEWP VI',         1),
('Silver Otter Analytics',   'SOTR',    'Small Business',   'GSA MAS',         1),
('Timber Wolf Consulting',   'TWLF',    'SDVOSB',           'OASIS SB',        1),
('Copper Hawk Solutions',    'CHKS',    'Small Business',   'Alliant 2 SB',    1),
('Blue Heron Data',          'BHRN',    '8(a)',             'STARS III',       1);
GO

-- ---------------------------------------------------------------------------
-- programs
-- ---------------------------------------------------------------------------
INSERT INTO programs (program_name, program_code, contract_type, program_phase, start_date, end_date, is_active) VALUES
('Charizard',       'CHAR-2023',   'CPFF',  'Active',     '2023-10-01', '2028-09-30', 1),
('Blastoise',       'BLAS-2024',   'CPAF',  'Active',     '2024-04-01', '2029-03-31', 1),
('Venusaur',        'VENU-2024',   'FFP',   'Active',     '2024-01-15', '2027-01-14', 1),
('Gengar',          'GENG-2025',   'T&M',   'Active',     '2025-01-01', '2028-12-31', 1),
('Alakazam',        'ALAK-2023',   'IDIQ',  'Active',     '2023-07-01', '2028-06-30', 1),
('Snorlax',         'SNOR-2022',   'FFP',   'Close-Out',  '2022-01-01', '2026-06-30', 1);
GO

-- ---------------------------------------------------------------------------
-- locations
-- ---------------------------------------------------------------------------
INSERT INTO locations (location_name, city, state_code, site_type, is_scif) VALUES
('Riverside Campus',        'Portland',     'OR', 'Government', 1),
('Lakewood Office Park',    'Madison',      'WI', 'Contractor', 1),
('Summit Ridge Center',     'Boise',        'ID', 'Government', 1),
('Clearwater Annex',        'Savannah',     'GA', 'Contractor', 1),
('Remote',                  'Remote',       'VA', 'Remote',     0);
GO

-- ---------------------------------------------------------------------------
-- labor_categories
-- ---------------------------------------------------------------------------
INSERT INTO labor_categories (lcat_name, domain_id, labor_type, is_technical) VALUES
('Systems Engineer III',        1, 'Engineering',     1),
('Systems Engineer IV',         1, 'Engineering',     1),
('Senior Systems Architect',    1, 'Engineering',     1),
('Software Engineer II',        2, 'Engineering',     1),
('Senior Software Engineer',    2, 'Engineering',     1),
('DevSecOps Engineer',          2, 'Engineering',     1),
('Cyber Analyst II',            3, 'Analysis',        1),
('Senior Cyber Engineer',       3, 'Engineering',     1),
('Data Analyst II',             4, 'Analysis',        1),
('Senior Data Engineer',        4, 'Engineering',     1),
('Program Manager',             5, 'Management',      0),
('Deputy Program Manager',      5, 'Management',      0),
('Cost Analyst II',             6, 'Analysis',        0),
('Senior Cost Analyst',         6, 'Analysis',        0),
('Configuration Manager',       7, 'Technical',       0),
('Financial Analyst III',       8, 'Analysis',        0);
GO

-- ---------------------------------------------------------------------------
-- cost_centers
-- ---------------------------------------------------------------------------
INSERT INTO cost_centers (cost_center_code, cost_center_name, charge_type, program_id, is_active) VALUES
('CC-CHAR-DIR',   'Charizard Direct Labor',       'Direct',   1, 1),
('CC-CHAR-OH',    'Charizard Overhead',            'Overhead', 1, 1),
('CC-BLAS-DIR',   'Blastoise Direct Labor',        'Direct',   2, 1),
('CC-BLAS-OH',    'Blastoise Overhead',            'Overhead', 2, 1),
('CC-VENU-DIR',   'Venusaur Direct Labor',         'Direct',   3, 1),
('CC-GENG-DIR',   'Gengar Direct Labor',           'Direct',   4, 1),
('CC-ALAK-DIR',   'Alakazam Direct Labor',         'Direct',   5, 1),
('CC-ALAK-GA',    'Alakazam G&A',                  'G&A',      5, 1),
('CC-SNOR-DIR',   'Snorlax Direct Labor',          'Direct',   6, 1),
('CC-ENT-BP',     'Enterprise B&P',                'B&P',      3, 1);
GO

INSERT INTO employees (first_name, last_name, lcat_id, org_id, vendor_id, location_id, cost_center_id, hire_date, labor_grade, clearance_level, is_billable, labor_type, employment_type, is_active) VALUES
('Alexander',  'Hamilton',     1,  7, 1, 1, 1, '2022-03-15', 'G11', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Ada',        'Lovelace',     2,  7, 1, 1, 1, '2021-09-01', 'G12', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Leonardo',   'DaVinci',      3,  7, 2, 2, 1, '2020-05-20', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Marie',      'Curie',        4,  9, 3, 3, 5, '2023-01-10', 'G09', 'TS',     1, 'Direct', 'Full-Time', 1),
('Alan',       'Turing',       5,  9, 3, 3, 5, '2019-11-05', 'G12', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Nikola',     'Tesla',        6,  9, 2, 2, 5, '2023-07-18', 'G11', 'TS',     1, 'Direct', 'Full-Time', 1),
('Sun',        'Tzu',          7,  7, 4, 1, 1, '2022-06-01', 'G10', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Florence',   'Nightingale',  8,  7, 4, 1, 6, '2020-02-12', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Galileo',    'Galilei',      9,  9, 3, 3, 5, '2024-03-01', 'G09', 'TS',     1, 'Direct', 'Full-Time', 1),
('Isaac',      'Newton',      10,  9, 6, 5, 5, '2021-08-15', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Julius',     'Caesar',      11,  8, 5, 1, 3, '2018-04-01', 'G14', 'TS/SCI', 0, 'Indirect', 'Full-Time', 1),
('Cleopatra',  'Ptolemy',     12,  8, 5, 2, 3, '2020-10-10', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Benjamin',   'Franklin',    13, 10, 3, 1, 7, '2022-11-07', 'G11', 'Secret', 1, 'Direct', 'Full-Time', 1),
('Eleanor',    'Roosevelt',   14, 10, 1, 1, 7, '2019-01-22', 'G13', 'TS',     1, 'Direct', 'Full-Time', 1),
('Harriet',    'Tubman',      15, 10, 2, 1, 8, '2021-03-30', 'G12', 'Secret', 0, 'Indirect', 'Full-Time', 1),
('Marcus',     'Aurelius',    16, 10, 5, 1, 8, '2023-05-15', 'G11', 'Secret', 0, 'Indirect', 'Full-Time', 1),
('Amelia',     'Earhart',      1,  8, 1, 4, 1, '2023-09-11', 'G11', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Charles',    'Darwin',       2,  8, 2, 4, 1, '2020-07-07', 'G12', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Rosalind',   'Franklin',     4, 10, 5, 5, 5, '2024-01-08', 'G09', 'TS',     1, 'Direct', 'Full-Time', 1),
('Hannibal',   'Barca',        7,  7, 4, 2, 6, '2022-02-28', 'G10', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Hypatia',    'Alexandria',   9,  9, 6, 5, 5, '2023-11-14', 'G10', 'TS',     1, 'Direct', 'Full-Time', 1),
('Socrates',   'Athens',      13, 10, 3, 1, 7, '2024-04-22', 'G10', 'Secret', 1, 'Direct', 'Full-Time', 1),
('Catherine',  'Medici',      14, 10, 1, 1, 7, '2018-06-01', 'G14', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Genghis',    'Khan',         5,  7, 2, 2, 1, '2021-05-19', 'G12', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Joan',       'Arc',          8,  8, 4, 4, 6, '2019-08-30', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Archimedes', 'Syracuse',    10, 10, 3, 3, 5, '2020-12-05', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Sitting',    'Bull',        11,  7, 5, 1, 1, '2017-09-18', 'G14', 'TS/SCI', 0, 'Indirect', 'Full-Time', 1),
('Simone',     'Bolivar',     15,  8, 5, 2, 3, '2021-10-04', 'G12', 'TS/SCI', 0, 'Indirect', 'Full-Time', 1),
('Ramesses',   'Thebes',      12,  9, 5, 3, 4, '2019-04-09', 'G13', 'TS/SCI', 1, 'Direct', 'Full-Time', 1),
('Confucius',  'Lu',           3,  8, 2, 4, 1, '2016-11-11', 'G14', 'TS/SCI', 1, 'Direct', 'Full-Time', 1);
GO

-- ---------------------------------------------------------------------------
-- program_assignments
-- ---------------------------------------------------------------------------
INSERT INTO program_assignments (employee_id, program_id, assignment_start, assignment_end, role_on_program, is_active) VALUES
(1,  1, '2023-10-01', NULL, 'Systems Engineer',          1),
(2,  1, '2023-10-01', NULL, 'Lead Systems Engineer',     1),
(3,  1, '2023-10-01', NULL, 'Chief Architect',           1),
(7,  1, '2023-10-01', NULL, 'Cyber Support',             1),
(20, 1, '2023-10-01', NULL, 'Cyber Analyst',             1),
(4,  3, '2024-01-15', NULL, 'Software Engineer',         1),
(5,  3, '2024-01-15', NULL, 'Lead Software Engineer',    1),
(6,  3, '2024-01-15', NULL, 'DevSecOps Lead',            1),
(9,  3, '2024-03-01', NULL, 'Data Analyst',              1),
(10, 3, '2024-01-15', NULL, 'Data Engineering Lead',     1),
(8,  4, '2025-01-01', NULL, 'Senior Cyber Engineer',     1),
(25, 4, '2025-01-01', NULL, 'Senior Cyber Engineer',     1),
(13, 5, '2023-07-01', NULL, 'Cost Analyst',              1),
(14, 5, '2023-07-01', NULL, 'Senior Cost Analyst',       1),
(22, 5, '2024-04-22', NULL, 'Cost Analyst',              1),
(23, 5, '2023-07-01', NULL, 'Senior Cost Analyst',       1),
(17, 2, '2024-04-01', NULL, 'Systems Engineer',          1),
(18, 2, '2024-04-01', NULL, 'Lead Systems Engineer',     1),
(30, 2, '2024-04-01', NULL, 'Chief Architect',           1),
(29, 6, '2022-01-01', '2026-06-30', 'Deputy PM',         1);
GO

-- ---------------------------------------------------------------------------
-- labor_rates
-- ---------------------------------------------------------------------------
INSERT INTO labor_rates (lcat_id, vendor_id, effective_date, expiration_date, hourly_rate, overtime_rate, rate_type) VALUES
-- Arctic Fox Systems (vendor_id 1) rates
(1,  1, '2023-10-01', NULL, 145.50, 218.25, 'Negotiated'),
(2,  1, '2023-10-01', NULL, 168.00, 252.00, 'Negotiated'),
(14, 1, '2023-07-01', NULL, 112.00, 168.00, 'Negotiated'),
-- Iron Falcon Group (vendor_id 2) rates
(3,  2, '2023-10-01', NULL, 192.75, 289.13, 'Negotiated'),
(7,  2, '2022-06-01', NULL, 128.00, 192.00, 'Negotiated'),
(8,  2, '2020-02-12', NULL, 178.50, 267.75, 'Negotiated'),
(15, 2, '2021-03-30', NULL, 118.00, 177.00, 'Negotiated'),
-- Silver Otter Analytics (vendor_id 3) rates
(4,  3, '2024-01-15', NULL, 118.00, 177.00, 'Negotiated'),
(5,  3, '2019-11-05', NULL, 165.25, 247.88, 'Negotiated'),
(9,  3, '2023-07-01', NULL, 105.00, 157.50, 'Negotiated'),
(13, 3, '2022-11-07', NULL, 108.00, 162.00, 'Negotiated'),
-- Timber Wolf Consulting (vendor_id 4) rates
(7,  4, '2022-06-01', NULL, 132.00, 198.00, 'Negotiated'),
(8,  4, '2020-02-12', NULL, 185.00, 277.50, 'Negotiated'),
-- Copper Hawk Solutions (vendor_id 5) rates
(11, 5, '2023-07-01', NULL, 215.00, NULL,   'Negotiated'),
(12, 5, '2023-07-01', NULL, 185.00, NULL,   'Negotiated'),
(16, 5, '2023-05-15', NULL, 115.00, 172.50, 'Negotiated'),
-- Blue Heron Data (vendor_id 6) rates
(10, 6, '2021-08-15', NULL, 175.00, 262.50, 'Negotiated'),
(9,  6, '2023-11-14', NULL, 102.00, 153.00, 'Negotiated'),
-- Competing rates for comparison queries
(4,  2, '2024-01-15', NULL, 124.50, 186.75, 'Proposed'),
(9,  2, '2024-01-01', NULL, 110.00, 165.00, 'Proposed'),
(13, 1, '2023-07-01', NULL, 115.00, 172.50, 'Proposed');
GO

-- ---------------------------------------------------------------------------
-- timesheets (covering FY24 and part of FY25)
-- ---------------------------------------------------------------------------
INSERT INTO timesheets (employee_id, program_id, cost_center_id, fiscal_year, fiscal_month, period_start_date, period_end_date, regular_hours, overtime_hours, billable_hours, non_billable_hours, hourly_rate, overtime_rate, is_billable, submitted_date, approved_date) VALUES
-- Q1 FY24 (Oct-Dec 2023) — Charizard program
(1,  1, 1, 2024, 1, '2023-10-01', '2023-10-31', 168.0,  8.0, 176.0, 0.0, 145.50, 218.25, 1, '2023-11-02', '2023-11-05'),
(2,  1, 1, 2024, 1, '2023-10-01', '2023-10-31', 168.0, 12.0, 180.0, 0.0, 168.00, 252.00, 1, '2023-11-02', '2023-11-05'),
(3,  1, 1, 2024, 1, '2023-10-01', '2023-10-31', 168.0,  0.0, 168.0, 0.0, 192.75, 289.13, 1, '2023-11-02', '2023-11-05'),
(1,  1, 1, 2024, 2, '2023-11-01', '2023-11-30', 160.0,  4.0, 164.0, 0.0, 145.50, 218.25, 1, '2023-12-02', '2023-12-05'),
(2,  1, 1, 2024, 2, '2023-11-01', '2023-11-30', 160.0, 16.0, 176.0, 0.0, 168.00, 252.00, 1, '2023-12-02', '2023-12-05'),
(3,  1, 1, 2024, 2, '2023-11-01', '2023-11-30', 160.0,  0.0, 160.0, 0.0, 192.75, 289.13, 1, '2023-12-02', '2023-12-05'),
-- Q2 FY24 — Venusaur program
(4,  3, 5, 2024, 4, '2024-01-15', '2024-01-31', 120.0,  0.0, 120.0, 0.0, 118.00, 177.00, 1, '2024-02-02', '2024-02-05'),
(5,  3, 5, 2024, 4, '2024-01-15', '2024-01-31', 120.0,  8.0, 128.0, 0.0, 165.25, 247.88, 1, '2024-02-02', '2024-02-05'),
(6,  3, 5, 2024, 4, '2024-01-15', '2024-01-31', 120.0,  0.0, 120.0, 0.0, 178.50, 267.75, 1, '2024-02-02', '2024-02-05'),
(10, 3, 5, 2024, 4, '2024-01-15', '2024-01-31', 120.0,  0.0, 120.0, 0.0, 175.00, 262.50, 1, '2024-02-02', '2024-02-05'),
-- Q3 FY24 — multiple programs
(1,  1, 1, 2024, 7, '2024-04-01', '2024-04-30', 168.0,  0.0, 168.0, 0.0, 145.50, 218.25, 1, '2024-05-02', '2024-05-05'),
(2,  1, 1, 2024, 7, '2024-04-01', '2024-04-30', 168.0, 20.0, 188.0, 0.0, 168.00, 252.00, 1, '2024-05-02', '2024-05-05'),
(4,  3, 5, 2024, 7, '2024-04-01', '2024-04-30', 168.0,  0.0, 168.0, 0.0, 118.00, 177.00, 1, '2024-05-02', '2024-05-05'),
(13, 5, 7, 2024, 7, '2024-04-01', '2024-04-30', 168.0,  0.0, 168.0, 0.0, 108.00, 162.00, 1, '2024-05-02', '2024-05-05'),
(14, 5, 7, 2024, 7, '2024-04-01', '2024-04-30', 168.0,  4.0, 172.0, 0.0, 112.00, 168.00, 1, '2024-05-02', '2024-05-05'),
-- FY25 Q1 (Oct-Dec 2024)
(1,  1, 1, 2025, 1, '2024-10-01', '2024-10-31', 168.0,  0.0, 168.0, 0.0, 145.50, 218.25, 1, '2024-11-02', '2024-11-05'),
(2,  1, 1, 2025, 1, '2024-10-01', '2024-10-31', 168.0,  8.0, 176.0, 0.0, 168.00, 252.00, 1, '2024-11-02', '2024-11-05'),
(4,  3, 5, 2025, 1, '2024-10-01', '2024-10-31', 168.0,  0.0, 168.0, 0.0, 118.00, 177.00, 1, '2024-11-02', '2024-11-05'),
(13, 5, 7, 2025, 1, '2024-10-01', '2024-10-31', 168.0,  0.0, 168.0, 0.0, 108.00, 162.00, 1, '2024-11-02', '2024-11-05'),
-- Gengar program starts FY25
(8,  4, 6, 2025, 4, '2025-01-01', '2025-01-31', 168.0,  8.0, 176.0, 0.0, 178.50, 267.75, 1, '2025-02-02', '2025-02-05'),
(25, 4, 6, 2025, 4, '2025-01-01', '2025-01-31', 168.0,  0.0, 168.0, 0.0, 185.00, 277.50, 1, '2025-02-02', '2025-02-05');
GO

-- ---------------------------------------------------------------------------
-- Verification: row counts
-- ---------------------------------------------------------------------------
SELECT 'skill_domains' AS table_name, COUNT(*) AS row_count FROM skill_domains 
UNION ALL
SELECT 'organizations', COUNT(*) FROM organizations 
UNION ALL
SELECT 'vendors', COUNT(*) FROM vendors
UNION ALL
SELECT 'programs', COUNT(*) FROM programs 
UNION ALL
SELECT 'locations', COUNT(*) FROM locations
UNION ALL
SELECT 'labor_categories', COUNT(*) FROM labor_categories
UNION ALL
SELECT 'cost_centers', COUNT(*) FROM cost_centers
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'program_assignments', COUNT(*) FROM program_assignments
UNION ALL
SELECT 'labor_rates', COUNT(*) FROM labor_rates
UNION ALL
SELECT 'timesheets', COUNT(*) FROM timesheets;
GO