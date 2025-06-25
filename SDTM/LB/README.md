# 📂 SDTM Domain: LB (Laboratory)

This directory includes SAS scripts and mock lab data to generate the **Laboratory (LB)** domain in SDTM format per **CDISC standards**.

The LB domain summarizes laboratory test results for each subject at various time points during the study.

---

## 📁 Files Included

| File Name       | Description |
|------------------|-------------|
| `Program.sas`         | SAS script to process and transform lab data. |
| `raw_lb.csv`     | Raw lab test results. |
| `lb_final.csv`   | SDTM-formatted LB dataset. |
| `lb_spec.xlsx` | Variable transformation plan. |
| `README.md`      | This file. |

---

## 🔧 Key Variables in LB Domain

| Variable   | Description |
|------------|-------------|
| `STUDYID`  | Study Identifier |
| `USUBJID`  | Unique Subject Identifier |
| `LBTESTCD` | Lab Test Short Name |
| `LBTEST`   | Lab Test Full Name |
| `LBORRES`  | Original Result |
| `LBORRESU` | Original Units |
| `LBDTC`    | Date of Test |

---

## 🔍 What This Program Demonstrates

✅ Cleaning lab data with `IF-THEN` logic  
✅ Unit harmonization  
✅ Labeling and formatting to meet SDTM rules  
✅ Outputting final LB dataset
