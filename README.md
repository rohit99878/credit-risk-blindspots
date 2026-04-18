# Credit Risk Blind Spots
## How Data Quality Shapes Lending Decisions

**Analyst:** Rohit Mendhekar  
**Domain:** Consumer Credit | Data Quality Analytics  
**Dataset:** Lending Club Accepted Loans 2007–2018  
**Records Analysed:** 2.26M  

---

## The Problem

Credit bureaus and lending institutions process millions of loan applications every year. Before any lending decision is made, the underlying data must be accurate and complete.

In practice, it rarely is.

This project investigates a question that is almost never asked:

> *"What happens to lending decisions when the data that passes validation is still not good enough?"*

---

## Background

This project is informed by 2+ years of experience at TransUnion — one of the world's three largest credit bureaus — where real client datasets ranging from 50K to 20M+ rows were processed and validated daily.

Having operated at the data intake and validation layer of enterprise credit pipelines, this project asks the question that role never answered:

**What is the actual business cost of data quality blind spots in lending?**

---

## Key Findings

| Finding | Number |
|---|---|
| Records audited | 2,260,701 |
| Records with quality issues | 206,082 (9.16%) |
| SUSPECT record default rate | 15.74% |
| CLEAN record default rate | 12.69% |
| Excess default rate gap | +3.05 percentage points |
| Worst blind spot | revol_util anomalies at 18.58% default rate |
| Excess financial exposure | $73.5M (full dataset) |

---

## The Core Insight

> SUSPECT records — those with subtle, hard-to-detect quality gaps — default at **15.74%** vs **12.69%** for clean records. Meanwhile DIRTY records with obvious issues get extra scrutiny and actually default less. **The real blind spots are the subtle ones.**

---

## Project Architecture

```
Raw Data (2.26M records)
        ↓
Python — Data Quality Audit + EDA + Analysis
        ↓
PostgreSQL — Storage + Cleaning + SQL Analysis
        ↓
dbt — Staging + Mart Transformation Models
        ↓
Power BI — 3 Page Executive Dashboard
```

---

## Tech Stack

| Layer | Tool |
|---|---|
| Analysis | Python — Pandas, NumPy, Seaborn |
| Database | PostgreSQL |
| Transformation | dbt Core |
| Dashboard | Power BI |
| Version Control | Git + GitHub |

---

## Repository Structure

```
credit-risk-blindspots/
│
├── notebooks/
│   └── 01_data_quality_audit.ipynb
│
├── sql/
│   ├── 01_setup_cleaning.sql
│   ├── 02_analysis.sql
│   └── 03_views.sql
│
├── dbt/
│   ├── dbt_project.yml
│   └── models/
│       ├── sources.yml
│       ├── stg_loans.sql
│       └── mart_credit_risk.sql
│
└── README.md
```

---

## Dataset

**Source:** Lending Club Accepted Loans 2007–2018  
**Download:** kaggle.com/datasets/wordsforthewise/lending-club  
**File needed:** accepted_2007_to_2018Q4.csv  
**Place in:** /data/raw/ (not included — too large for GitHub)

---

## How To Run

**1. Clone the repo**
```bash
git clone https://github.com/rohit99878/credit-risk-blindspots.git
```

**2. Install dependencies**
```bash
pip install pandas numpy matplotlib seaborn
pip install dbt-postgres
```

**3. Run Python notebook**  
Open `notebooks/01_data_quality_audit.ipynb`

**4. Set up PostgreSQL**  
Run `sql/01_setup_cleaning.sql` in pgAdmin

**5. Run dbt models**
```bash
cd dbt
dbt run
```

**6. Connect Power BI**  
Connect to PostgreSQL views:
- vw_quality_default
- vw_regional_risk
- vw_grade_variance

---

## Contact

**Rohit Mendhekar**  
📧 rohitmendhekar77@gmail.com  
🔗 linkedin.com/in/rohit-mendhekar
