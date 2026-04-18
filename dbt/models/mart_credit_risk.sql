-- mart_credit_risk.sql
-- Mart model — business logic and risk segmentation
-- Rohit Mendhekar — Credit Risk Blind Spots Project

WITH staged AS (
    SELECT * FROM {{ ref('stg_loans') }}
),

enriched AS (
    SELECT
        -- All staged columns
        *,

        -- Risk band based on interest rate
        CASE
            WHEN interest_rate < 8  THEN 'Very Low Risk'
            WHEN interest_rate < 12 THEN 'Low Risk'
            WHEN interest_rate < 16 THEN 'Medium Risk'
            WHEN interest_rate < 20 THEN 'High Risk'
            ELSE                         'Very High Risk'
        END                             AS interest_rate_band,

        -- Income segment
        CASE
            WHEN annual_income < 30000  THEN 'Low Income'
            WHEN annual_income < 60000  THEN 'Lower Middle'
            WHEN annual_income < 100000 THEN 'Middle'
            WHEN annual_income < 150000 THEN 'Upper Middle'
            ELSE                             'High Income'
        END                             AS income_segment,

        -- DTI risk category
        CASE
            WHEN debt_to_income < 10 THEN 'Healthy'
            WHEN debt_to_income < 20 THEN 'Manageable'
            WHEN debt_to_income < 35 THEN 'Elevated'
            ELSE                          'Risky'
        END                             AS dti_category,

        -- Data quality severity label
        CASE
            WHEN quality_label = 'CLEAN'       THEN 1
            WHEN quality_label = 'MINOR_ISSUE' THEN 2
            WHEN quality_label = 'SUSPECT'     THEN 3
            WHEN quality_label = 'DIRTY'       THEN 4
        END                             AS quality_score,

        -- Expected loss estimate
        ROUND(loan_amount * is_default, 2) AS actual_loss,

        -- High risk flag
        CASE
            WHEN quality_label IN ('SUSPECT', 'DIRTY')
            AND is_default = 1
            THEN 1
            ELSE 0
        END                             AS quality_driven_default

    FROM staged
)

SELECT * FROM enriched