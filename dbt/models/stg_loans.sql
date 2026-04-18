-- stg_loans.sql
-- Staging model — clean and rename columns from loans_raw
-- Rohit Mendhekar — Credit Risk Blind Spots Project

WITH source AS (
    SELECT * FROM {{ source('public', 'loans_raw') }}
),

staged AS (
    SELECT
        -- Loan details
        loan_amnt                           AS loan_amount,
        funded_amnt                         AS funded_amount,
        TRIM(term)                          AS loan_term,
        int_rate                            AS interest_rate,
        grade                               AS risk_grade,
        sub_grade                           AS risk_sub_grade,
        purpose                             AS loan_purpose,

        -- Borrower details
        COALESCE(emp_length, 'Unknown')     AS employment_years,
        home_ownership,
        annual_inc                          AS annual_income,
        verification_status,
        addr_state                          AS state,
        COALESCE(dti, 0)                    AS debt_to_income,
        COALESCE(revol_util, 0)             AS revolving_utilization,
        COALESCE(open_acc, 0)               AS open_accounts,
        COALESCE(pub_rec, 0)                AS public_records,
        COALESCE(mort_acc, 0)               AS mortgage_accounts,
        COALESCE(pub_rec_bankruptcies, 0)   AS bankruptcies,
        COALESCE(delinq_2yrs, 0)            AS delinquencies_2yr,
        COALESCE(total_acc, 0)              AS total_accounts,
        COALESCE(revol_bal, 0)              AS revolving_balance,

        -- Quality flags
        flag_emp_missing,
        flag_income_zero,
        flag_income_extreme,
        flag_revol_extreme,
        flag_dti_extreme,
        flag_dti_negative,
        flag_home_unknown,
        flag_null_any,
        total_issues,
        quality_label,

        -- Target
        is_default,
        loan_status
    FROM source
)

SELECT * FROM staged