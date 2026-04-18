-- ============================================================
-- 02_analysis.sql
-- Credit Risk Blind Spots Project
-- Author: Rohit Mendhekar
-- Description: 5 business analysis queries covering all
--              core SQL concepts
-- ============================================================


-- ============================================================
-- QUERY 1 — NULL HANDLING + GROUP BY
-- Business Question: How does missing employment data
-- impact default rates across loan grades?
-- ============================================================

SELECT
    COALESCE(emp_length, 'Not Provided')    AS employment_years,
    grade,
    COUNT(*)                                AS total_loans,
    SUM(is_default)                         AS total_defaults,
    ROUND(AVG(is_default) * 100, 2)         AS default_rate,
    ROUND(AVG(loan_amnt), 2)                AS avg_loan_amount
FROM loans_raw
WHERE is_default IS NOT NULL
GROUP BY
    COALESCE(emp_length, 'Not Provided'),
    grade
HAVING COUNT(*) > 50
ORDER BY
    default_rate DESC,
    total_loans DESC;


-- ============================================================
-- QUERY 2 — CTE
-- Business Question: Which states have both high data
-- quality issues AND above average default rates?
-- These are the true blind spot regions.
-- ============================================================

WITH state_quality AS (
    SELECT
        addr_state,
        COUNT(*)                                AS total_loans,
        ROUND(AVG(total_issues), 2)             AS avg_quality_issues,
        SUM(flag_null_any)                      AS total_null_flags,
        ROUND(AVG(is_default) * 100, 2)         AS default_rate,
        ROUND(SUM(loan_amnt), 2)                AS total_exposure
    FROM loans_raw
    WHERE is_default IS NOT NULL
    GROUP BY addr_state
),
national_avg AS (
    SELECT
        ROUND(AVG(default_rate), 2)             AS national_default_rate,
        ROUND(AVG(avg_quality_issues), 2)       AS national_avg_issues
    FROM state_quality
)
SELECT
    sq.addr_state,
    sq.total_loans,
    sq.avg_quality_issues,
    sq.total_null_flags,
    sq.default_rate,
    na.national_default_rate,
    ROUND(sq.default_rate -
        na.national_default_rate, 2)            AS deviation_from_national,
    sq.total_exposure
FROM state_quality sq
CROSS JOIN national_avg na
WHERE sq.default_rate > na.national_default_rate
AND sq.avg_quality_issues > na.national_avg_issues
ORDER BY deviation_from_national DESC;


-- ============================================================
-- QUERY 3 — SUBQUERY + JOIN
-- Business Question: By region, how do data quality issues
-- drive default rates above the national average?
-- ============================================================

SELECT
    sr.region,
    sr.region_group,
    l.quality_label,
    COUNT(*)                                AS total_loans,
    ROUND(AVG(l.is_default) * 100, 2)       AS default_rate,
    ROUND(SUM(l.loan_amnt), 2)              AS total_exposure,
    ROUND(AVG(l.loan_amnt), 2)              AS avg_loan_amount,
    ROUND(AVG(l.total_issues), 2)           AS avg_quality_issues
FROM loans_raw l
JOIN state_region sr
    ON l.addr_state = sr.addr_state
WHERE l.is_default IS NOT NULL
GROUP BY
    sr.region,
    sr.region_group,
    l.quality_label
HAVING AVG(l.is_default) * 100 > (
    SELECT AVG(is_default) * 100
    FROM loans_raw
    WHERE is_default IS NOT NULL
)
ORDER BY
    default_rate DESC,
    total_exposure DESC;


-- ============================================================
-- QUERY 4 — WINDOW FUNCTIONS + RANK
-- Business Question: Within each quality label, how do
-- loan grades rank by default rate and what is the
-- cumulative financial exposure?
-- ============================================================

SELECT
    quality_label,
    grade,
    COUNT(*)                                AS total_loans,
    ROUND(AVG(is_default) * 100, 2)         AS default_rate,
    ROUND(SUM(loan_amnt), 2)                AS total_exposure,
    RANK() OVER (
        PARTITION BY quality_label
        ORDER BY AVG(is_default) DESC
    )                                       AS risk_rank,
    ROUND(SUM(SUM(loan_amnt)) OVER (
        PARTITION BY quality_label
        ORDER BY AVG(is_default) DESC
    ), 2)                                   AS cumulative_exposure,
    ROUND(AVG(int_rate), 2)                 AS avg_interest_rate,
    ROUND(AVG(dti), 2)                      AS avg_dti
FROM loans_raw
WHERE is_default IS NOT NULL
GROUP BY quality_label, grade
HAVING COUNT(*) > 30
ORDER BY quality_label, risk_rank;


-- ============================================================
-- QUERY 5 — JOIN + NTILE
-- Business Question: Where does actual default rate deviate
-- most from expected rate by risk grade — and is data
-- quality the cause of that deviation?
-- ============================================================

SELECT
    g.grade,
    g.risk_category,
    g.expected_rate,
    l.quality_label,
    COUNT(*)                                AS total_loans,
    ROUND(AVG(l.is_default) * 100, 2)       AS actual_rate,
    ROUND(
        AVG(l.is_default) * 100
        - g.expected_rate, 2
    )                                       AS variance,
    ROUND(SUM(l.loan_amnt), 2)              AS total_exposure,
    ROUND(
        SUM(l.loan_amnt) *
        (AVG(l.is_default) - g.expected_rate/100)
    , 2)                                    AS excess_loss,
    NTILE(4) OVER (
        ORDER BY AVG(l.is_default) * 100
        - g.expected_rate DESC
    )                                       AS risk_quartile
FROM loans_raw l
JOIN grade_risk_profile g
    ON l.grade = g.grade
WHERE l.is_default IS NOT NULL
GROUP BY
    g.grade,
    g.risk_category,
    g.expected_rate,
    l.quality_label
HAVING COUNT(*) > 30
ORDER BY variance DESC;


-- ============================================================
-- QUERY 6 — CASE WHEN + GROUP BY
-- Business Question: How do loan purposes behave
-- differently across quality labels — are certain
-- purposes more prone to data quality issues?
-- ============================================================

SELECT
    purpose,
    quality_label,
    COUNT(*)                                AS total_loans,
    ROUND(AVG(is_default) * 100, 2)         AS default_rate,
    ROUND(SUM(loan_amnt), 2)                AS total_exposure,
    CASE
        WHEN AVG(is_default) * 100 >= 20 THEN 'HIGH RISK'
        WHEN AVG(is_default) * 100 >= 13 THEN 'MEDIUM RISK'
        ELSE                                   'LOW RISK'
    END                                     AS risk_category,
    ROUND(AVG(int_rate), 2)                 AS avg_interest_rate
FROM loans_raw
WHERE is_default IS NOT NULL
GROUP BY purpose, quality_label
HAVING COUNT(*) > 30
ORDER BY default_rate DESC;


-- ============================================================
-- QUERY 7 — LAG + RUNNING TOTAL
-- Business Question: How has the volume of data quality
-- issues and defaults trended year over year?
-- ============================================================

SELECT
    EXTRACT(YEAR FROM
        TO_DATE(earliest_cr_line, 'Mon-YYYY'))  AS credit_year,
    quality_label,
    COUNT(*)                                    AS total_loans,
    ROUND(AVG(is_default) * 100, 2)             AS default_rate,
    ROUND(AVG(is_default) * 100, 2) -
        LAG(ROUND(AVG(is_default) * 100, 2))
        OVER (
            PARTITION BY quality_label
            ORDER BY EXTRACT(YEAR FROM
                TO_DATE(earliest_cr_line, 'Mon-YYYY'))
        )                                       AS yoy_change,
    SUM(COUNT(*)) OVER (
        PARTITION BY quality_label
        ORDER BY EXTRACT(YEAR FROM
            TO_DATE(earliest_cr_line, 'Mon-YYYY'))
    )                                           AS running_total
FROM loans_raw
WHERE is_default IS NOT NULL
AND earliest_cr_line IS NOT NULL
GROUP BY
    EXTRACT(YEAR FROM
        TO_DATE(earliest_cr_line, 'Mon-YYYY')),
    quality_label
ORDER BY credit_year, quality_label;