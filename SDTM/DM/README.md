# 📂 SDTM Domain: DM (Demographics)

This folder contains SAS programming and mock data for the creation of the **Demographics (DM)** domain as per **CDISC SDTM standards**.

The DM domain provides subject-level data such as age, sex, race, and other key baseline demographic characteristics from a mock clinical trial dataset.

---

## 📁 Files Included

| File Name              | Description |
|------------------------|-------------|
| `dm.sas`               | SAS program to transform raw subject-level data into SDTM-compliant DM dataset. |
| `raw_dm.csv`           | Mock raw dataset used as input, containing subject IDs, birth dates, sex, race, etc. |
| `dm_final.csv`         | Output dataset in SDTM format (preview version). |
| `dm_mapping_spec.xlsx` | (Optional) Mapping/spec document showing how raw variables were transformed to SDTM variables. |
| `README.md`            | Overview of the DM domain and file explanations. |

---

## 🔧 Key Variables in DM Domain

| Variable   | Description |
|------------|-------------|
| `STUDYID`  | Study Identifier |
| `USUBJID`  | Unique Subject Identifier |
| `SUBJID`   | Subject ID |
| `RFSTDTC`  | Reference Start Date and Time|
| `RFENDTC`     | Reference End Date and Time |
| `BRTHDTC`  | Birth Date |
| `AGE`      | Age at Screening |
| `AGEU`      | Age units |
| `SEX`      | Sex |
| `RACE`     | Race |
| `ETHINIC`      | Ethinicity|
| `COUNTRY`      | Country|

---

## 🔍 What This Program Demonstrates

✅ Importing raw data using `PROC IMPORT`  
✅ Variable transformation and formatting  
✅ Assigning labels and SDTM-compliant formats  
✅ Creating a final SDTM domain with validated
