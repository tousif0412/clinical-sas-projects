# 📂 SDTM Domain: VS (Vital Signs)

This folder includes SAS code and datasets for building the **Vital Signs (VS)** SDTM domain following **CDISC SDTM guidelines**.

The VS domain records standardized subject vital sign measurements such as blood pressure, pulse, temperature, and weight.

---

## 📁 Files Included

| File Name       | Description |
|------------------|-------------|
| `vs.sas`         | SAS code to convert raw vital signs data into SDTM format. |
| `raw_vs.csv`     | Input file with raw vital signs data per subject. |
| `vs_final.csv`   | Output SDTM-compliant VS dataset. |
| `vs_mapping_spec.xlsx` | Variable mapping and transformation details. |
| `README.md`      | Overview of VS domain content. |

---

## 🔧 Key Variables in VS Domain

| Variable   | Description |
|------------|-------------|
| `STUDYID`  | Study Identifier |
| `USUBJID`  | Unique Subject Identifier |
| `VSTESTCD` | Vital Sign Test Code |
| `VSTEST`   | Vital Sign Test Name |
| `VSORRES`  | Original Result |
| `VSORRESU` | Original Units |
| `VSDTC`    | Date/Time of Measurement |

---

## 🔍 What This Program Demonstrates

✅ Use of `PROC TRANSPOSE` to pivot repeated measures  
✅ Handling units and conversion  
✅ Standardizing test names and codes  
✅ Producing a clean SDTM VS domain
