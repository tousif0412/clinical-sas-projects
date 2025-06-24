# 📂 SDTM Domain: AE (Adverse Events)

This folder contains SAS programming and mock data for creating the **Adverse Events (AE)** domain based on **CDISC SDTM standards**.

The AE domain captures details about any adverse events experienced by subjects during the clinical trial.

---

## 📁 Files Included

| File Name        | Description |
|------------------|-------------|
| `Programe`         | SAS program to transform raw AE data into SDTM AE format. |
| `raw_ae.xlsx`     | Mock raw adverse events data (event term, start date, severity, etc.). |
| `ae_final.csv`   | Output SDTM-compliant AE dataset. |
| `ae_mapping_spec.xlsx` | Mapping/specification file for AE domain creation. |
| `README.md`      | Description of the AE domain structure and files. |

---

## 🔧 Key Variables in AE Domain

| Variable   | Description |
|------------|-------------|
| `STUDYID`  | Study Identifier |
| `USUBJID`  | Unique Subject Identifier |
| `AETERM`   | Reported Term for the Adverse Event |
| `AESTDTC`  | Start Date/Time of AE |
| `AEENDTC`  | End Date/Time of AE |
| `AESEV`    | Severity of AE |
| `AESER`    | Serious Event Flag |
| `AEREL`    | Relationship to Study Treatment |

---

## 🔍 What This Program Demonstrates

✅ Merging raw AE and subject data  
✅ Deriving date formats and flags  
✅ Applying CDISC standard variable labels and formats  
✅ Creating a structured AE domain

