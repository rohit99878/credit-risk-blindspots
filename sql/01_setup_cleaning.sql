-- ============================================================
-- 01_setup_cleaning.sql
-- Credit Risk Blind Spots Project
-- Author: Rohit Mendhekar
-- Description: Table creation, data load, lookup tables,
--              and data cleaning
-- ============================================================


-- ============================================================
-- SECTION 1 — CREATE TABLES
-- ============================================================


-- Main table
CREATE TABLE loans_raw (
    loan_amnt               NUMERIC,
    funded_amnt             NUMERIC,
    term                    VARCHAR(20),
    int_rate                NUMERIC,
    grade                   VARCHAR(5),
    sub_grade               VARCHAR(5),
    emp_length              VARCHAR(20),
    home_ownership          VARCHAR(20),
    annual_inc              NUMERIC,
    verification_status     VARCHAR(50),
    loan_status             VARCHAR(100),
    purpose                 VARCHAR(50),
    addr_state              VARCHAR(5),
    dti                     NUMERIC,
    delinq_2yrs             NUMERIC,
    earliest_cr_line        VARCHAR(20),
    open_acc                NUMERIC,
    pub_rec                 NUMERIC,
    revol_bal               NUMERIC,
    revol_util              NUMERIC,
    total_acc               NUMERIC,
    mort_acc                NUMERIC,
    pub_rec_bankruptcies    NUMERIC,
    flag_emp_missing        INTEGER,
    flag_income_zero        INTEGER,
    flag_income_extreme     INTEGER,
    flag_revol_extreme      INTEGER,
    flag_dti_extreme        INTEGER,
    flag_dti_negative       INTEGER,
    flag_home_unknown       INTEGER,
    flag_null_any           INTEGER,
    total_issues            INTEGER,
    quality_label           VARCHAR(20),
    is_default              NUMERIC
);


-- State to region lookup table
CREATE TABLE state_region (
    addr_state      VARCHAR(5),
    state_name      VARCHAR(50),
    region          VARCHAR(30),
    region_group    VARCHAR(20)
);


-- Grade risk profile lookup table
CREATE TABLE grade_risk_profile (
    grade               VARCHAR(5),
    risk_category       VARCHAR(30),
    expected_rate       NUMERIC
);


-- Verify tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================
-- SECTION 2 — LOAD DATA
-- ============================================================

-- Load main dataset
COPY loans_raw
FROM 'D:/CDAC_DBDA/Analysis_Project_Resume/Project_2/loans_final_scored.csv'
DELIMITER ','
CSV HEADER;

-- Verify load
SELECT quality_label, COUNT(*) AS total_records
FROM loans_raw
GROUP BY quality_label
ORDER BY total_records DESC;



-- ============================================================
-- SECTION 3 — INSERT LOOKUP DATA
-- ============================================================

-- State to Region Mapping
INSERT INTO state_region (addr_state, state_name, region, region_group) VALUES
('CT', 'Connecticut',          'New England',      'Northeast'),
('ME', 'Maine',                'New England',      'Northeast'),
('MA', 'Massachusetts',        'New England',      'Northeast'),
('NH', 'New Hampshire',        'New England',      'Northeast'),
('RI', 'Rhode Island',         'New England',      'Northeast'),
('VT', 'Vermont',              'New England',      'Northeast'),
('NJ', 'New Jersey',           'Mid Atlantic',     'Northeast'),
('NY', 'New York',             'Mid Atlantic',     'Northeast'),
('PA', 'Pennsylvania',         'Mid Atlantic',     'Northeast'),
('IL', 'Illinois',             'East North Central','Midwest'),
('IN', 'Indiana',              'East North Central','Midwest'),
('MI', 'Michigan',             'East North Central','Midwest'),
('OH', 'Ohio',                 'East North Central','Midwest'),
('WI', 'Wisconsin',            'East North Central','Midwest'),
('IA', 'Iowa',                 'West North Central','Midwest'),
('KS', 'Kansas',               'West North Central','Midwest'),
('MN', 'Minnesota',            'West North Central','Midwest'),
('MO', 'Missouri',             'West North Central','Midwest'),
('NE', 'Nebraska',             'West North Central','Midwest'),
('ND', 'North Dakota',         'West North Central','Midwest'),
('SD', 'South Dakota',         'West North Central','Midwest'),
('DE', 'Delaware',             'South Atlantic',   'South'),
('FL', 'Florida',              'South Atlantic',   'South'),
('GA', 'Georgia',              'South Atlantic',   'South'),
('MD', 'Maryland',             'South Atlantic',   'South'),
('NC', 'North Carolina',       'South Atlantic',   'South'),
('SC', 'South Carolina',       'South Atlantic',   'South'),
('VA', 'Virginia',             'South Atlantic',   'South'),
('WV', 'West Virginia',        'South Atlantic',   'South'),
('DC', 'District of Columbia', 'South Atlantic',   'South'),
('AL', 'Alabama',              'East South Central','South'),
('KY', 'Kentucky',             'East South Central','South'),
('MS', 'Mississippi',          'East South Central','South'),
('TN', 'Tennessee',            'East South Central','South'),
('AR', 'Arkansas',             'West South Central','South'),
('LA', 'Louisiana',            'West South Central','South'),
('OK', 'Oklahoma',             'West South Central','South'),
('TX', 'Texas',                'West South Central','South'),
('AZ', 'Arizona',              'Mountain',         'West'),
('CO', 'Colorado',             'Mountain',         'West'),
('ID', 'Idaho',                'Mountain',         'West'),
('MT', 'Montana',              'Mountain',         'West'),
('NV', 'Nevada',               'Mountain',         'West'),
('NM', 'New Mexico',           'Mountain',         'West'),
('UT', 'Utah',                 'Mountain',         'West'),
('WY', 'Wyoming',              'Mountain',         'West'),
('AK', 'Alaska',               'Pacific',          'West'),
('CA', 'California',           'Pacific',          'West'),
('HI', 'Hawaii',               'Pacific',          'West'),
('OR', 'Oregon',               'Pacific',          'West'),
('WA', 'Washington',           'Pacific',          'West');

-- Verify
SELECT region_group, COUNT(*) AS states
FROM state_region
GROUP BY region_group
ORDER BY region_group;


-- Grade Risk Profile
INSERT INTO grade_risk_profile 
    (grade, risk_category, expected_rate) VALUES
('A', 'Very Low Risk',        5.0),
('B', 'Low Risk',             8.0),
('C', 'Medium Risk',          13.0),
('D', 'High Risk',            18.0),
('E', 'Very High Risk',       24.0),
('F', 'Speculative',          30.0),
('G', 'Highly Speculative',   35.0);

-- Verify
SELECT * FROM grade_risk_profile
ORDER BY expected_rate;






-- ============================================================
-- SECTION 4 — DATA CLEANING
-- ============================================================

-- Check counts before cleaning
SELECT 'Before Cleaning' AS stage,
    COUNT(*) AS total_records
FROM loans_raw;


-- CLEAN 1 — Standardize emp_length
-- Convert inconsistent strings to numeric values
UPDATE loans_raw
SET emp_length = CASE
    WHEN emp_length = '< 1 year'  THEN '0'
    WHEN emp_length = '1 year'    THEN '1'
    WHEN emp_length = '2 years'   THEN '2'
    WHEN emp_length = '3 years'   THEN '3'
    WHEN emp_length = '4 years'   THEN '4'
    WHEN emp_length = '5 years'   THEN '5'
    WHEN emp_length = '6 years'   THEN '6'
    WHEN emp_length = '7 years'   THEN '7'
    WHEN emp_length = '8 years'   THEN '8'
    WHEN emp_length = '9 years'   THEN '9'
    WHEN emp_length = '10+ years' THEN '10'
    WHEN emp_length IS NULL       THEN NULL
    ELSE NULL
END;

-- Verify
SELECT emp_length, COUNT(*) AS total
FROM loans_raw
GROUP BY emp_length
ORDER BY emp_length;


-- CLEAN 2 — Cap extreme annual_inc at 99th percentile
UPDATE loans_raw
SET annual_inc = (
    SELECT PERCENTILE_CONT(0.99)
    WITHIN GROUP (ORDER BY annual_inc)
    FROM loans_raw
    WHERE annual_inc IS NOT NULL
)
WHERE annual_inc > (
    SELECT PERCENTILE_CONT(0.99)
    WITHIN GROUP (ORDER BY annual_inc)
    FROM loans_raw
    WHERE annual_inc IS NOT NULL
);

-- Verify
SELECT 
    MIN(annual_inc)  AS min_income,
    MAX(annual_inc)  AS max_income,
    ROUND(AVG(annual_inc), 2) AS avg_income
FROM loans_raw;


-- CLEAN 3 — Cap impossible revol_util values
UPDATE loans_raw
SET revol_util = 100
WHERE revol_util > 100;

-- Verify
SELECT 
    MAX(revol_util) AS max_revol_util,
    COUNT(*) FILTER (WHERE revol_util > 100) AS still_over_100
FROM loans_raw;


-- CLEAN 4 — Fix negative dti values
UPDATE loans_raw
SET dti = NULL
WHERE dti < 0;

-- Verify
SELECT 
    MIN(dti) AS min_dti,
    COUNT(*) FILTER (WHERE dti < 0) AS negative_dti
FROM loans_raw;


-- CLEAN 5 — Standardize home_ownership
UPDATE loans_raw
SET home_ownership = 'OTHER'
WHERE home_ownership IN ('ANY', 'NONE');

-- Verify
SELECT home_ownership, COUNT(*) AS total
FROM loans_raw
GROUP BY home_ownership
ORDER BY total DESC;


-- CLEAN 6 — Simplify loan_status
UPDATE loans_raw
SET loan_status = 'Fully Paid'
WHERE loan_status = 
    'Does not meet the credit policy. Status:Fully Paid';

UPDATE loans_raw
SET loan_status = 'Charged Off'
WHERE loan_status = 
    'Does not meet the credit policy. Status:Charged Off';

-- Verify
SELECT loan_status, COUNT(*) AS total
FROM loans_raw
GROUP BY loan_status
ORDER BY total DESC;


-- Final check after all cleaning
SELECT 'After Cleaning' AS stage,
    COUNT(*) AS total_records
FROM loans_raw;