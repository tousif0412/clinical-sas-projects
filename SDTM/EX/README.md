# 📂 SDTM Domain: EX (Exposure)

This folder contains programs and mock datasets to generate the **Exposure (EX)** domain, according to **CDISC SDTM** guidelines.

The EX domain describes study treatment exposure: what dose was given, when, and how.

---

## 📁 Files Included

| File Name       | Description |
|------------------|-------------|
| `ex.sas`         | SAS script to transform dosing records into SDTM EX format. |
| `raw_ex.csv`     | Raw dosing data for each subject. |
| `ex_final.csv`   | Output EX dataset in SDTM format. |
| `ex_mapping_spec.xlsx` | Variable mapping specifications. |
| `README.md`      | EX domain file guide. |

---

## 🔧 Key Variables in EX Domain

| Variable   | Description |
|------------|-------------|
| `STUDYID`  | Study Identifier |
| `USUBJID`  | Unique Subject Identifier |
| `EXTRT`    | Name of Treatment |
| `EXDOSE`   | Dose Given |
| `EXDOSU`   | Dose Units |
| `EXROUTE`  | Route of Administration |
| `EXDTC`    | Start Date/Time of Exposure |

---

## 🔍 What This Program Demonstrates

✅ Parsing and cleaning raw dose data  
✅ Handling missing dose dates or units  
✅ Applying labels and formats  
✅ Finalizing a compliant EX domain
