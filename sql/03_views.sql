-- ============================================================
-- 03_views.sql
-- Credit Risk Blind Spots Project
-- Author: Rohit Mendhekar
-- Description: 3 views for Power BI dashboard
-- ============================================================

DROP VIEW IF EXISTS vw_quality_default;
DROP VIEW IF EXISTS vw_regional_risk;
DROP VIEW IF EXISTS vw_grade_variance;


-- ============================================================
-- VIEW 1 — vw_quality_default
-- Powers: Main overview page in Power BI
-- ============================================================

CREATE VIEW vw_quality_default AS
SELECT
    quality_label,
    COUNT(*)                                AS total_loans,
    SUM(is_default)                         AS total_defaults,
    ROUND(AVG(is_default) * 100, 2)         AS default_rate,
    ROUND(SUM(loan_amnt), 2)                AS total_exposure,
    ROUND(AVG(loan_amnt), 2)                AS avg_loan_amount,
    ROUND(AVG(int_rate), 2)                 AS avg_interest_rate,
    ROUND(AVG(dti), 2)                      AS avg_dti,
    SUM(flag_emp_missing)                   AS emp_missing_count,
    SUM(flag_revol_extreme)                 AS revol_extreme_count,
    SUM(flag_income_zero)                   AS income_zero_count,
    SUM(flag_income_extreme)                AS income_extreme_count,
    ROUND(
        SUM(loan_amnt) * (
            AVG(is_default) - 0.1279
        ), 2
    )                                       AS excess_loss
FROM loans_raw
WHERE is_default IS NOT NULL
GROUP BY quality_label;


-- ============================================================
-- VIEW 2 — vw_regional_risk
-- Powers: Geographic page in Power BI
-- ============================================================

CREATE VIEW vw_regional_risk AS
SELECT
    sr.region,
    sr.region_group,
    l.quality_label,
    COUNT(*)                                AS total_loans,
    ROUND(AVG(l.is_default) * 100, 2)       AS default_rate,
    ROUND(SUM(l.loan_amnt), 2)              AS total_exposure,
    ROUND(AVG(l.loan_amnt), 2)              AS avg_loan_amount,
    ROUND(AVG(l.total_issues), 2)           AS avg_quality_issues,
    SUM(l.flag_null_any)                    AS null_flag_count
FROM loans_raw l
JOIN state_region sr
    ON l.addr_state = sr.addr_state
WHERE l.is_default IS NOT NULL
GROUP BY
    sr.region,
    sr.region_group,
    l.quality_label;


-- ============================================================
-- VIEW 3 — vw_grade_variance
-- Powers: Risk grade page in Power BI
-- ============================================================

CREATE VIEW vw_grade_variance AS
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
        SUM(l.loan_amnt) * (
            AVG(l.is_default) - g.expected_rate / 100
        ), 2
    )                                       AS excess_loss
FROM loans_raw l
JOIN grade_risk_profile g
    ON l.grade = g.grade
WHERE l.is_default IS NOT NULL
GROUP BY
    g.grade,
    g.risk_category,
    g.expected_rate,
    l.quality_label;


-- ============================================================
-- VERIFY — All views created
-- ============================================================

SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================
-- PREVIEW — Quick check each view
-- ============================================================

SELECT * FROM vw_quality_default
ORDER BY default_rate DESC;

SELECT * FROM vw_regional_risk
ORDER BY default_rate DESC
LIMIT 10;

SELECT * FROM vw_grade_variance
ORDER BY variance DESC
LIMIT 10;