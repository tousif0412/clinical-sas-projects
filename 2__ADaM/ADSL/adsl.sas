/*******************************************************************                                               
* Program: ADSL.SAS  
*
* Program Type: ADAM          
*
* Author: Tousif
* Date Created: 27-JUN-2025
*******************************************************************/          
libname sdtm '/home/u63925560/CL/sdtm';

/*to delete all datasets from work library*/
PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

/*to convert all variables to upper case*/
OPTION VALIDVARNAME=UPCASE;

/*COPY ALL THE VARIABLES FROM DM AND SUPPDM*/

DATA DM1;
   SET SDTM.DM;
RUN;

/*we need variables from supplimentary DM dataset also*/
DATA SUPPDM;
   SET SDTM.SUPPDM;
RUN;

/*Transpose SUPPDM 'by subject' to get one record per subject*/
PROC TRANSPOSE DATA=SUPPDM OUT=SUPPDM_TRANS;
   BY USUBJID;
   ID QNAM;
   VAR QVAL;
   IDLABEL QLABEL;
RUN;
/*join suppdm with main DM*/
DATA DM2;
   MERGE DM1 (IN=A) SUPPDM_TRANS (IN=B);
   BY USUBJID;
   IF A ;
RUN;
/*Transpose of suppdm dataset also create many variables like MFUV, VCYN , VCNUM, HOSPCOFL */
/*this variables are optional - if not present in suppdm then may come in future*/


/* ASSIGNED */;

DATA DM3;
   SET DM2;
   LENGTH AGEGR1 $40.;
   IF AGE NE . THEN DO;
      IF AGE LT 40 THEN AGEGR1='< 40 years old';
      ELSE IF AGE GE 40 THEN AGEGR1='>= 40 years old';
   END;

   IF SEX='M' THEN SEXN=1;
   ELSE IF SEX='F' THEN SEXN=2;


   if RACE = "AMERICAN INDIAN OR ALASKA NATIVE" then RACEN=1;
   else if RACE = "ASIAN" then RACEN=2;
   else if RACE = "BLACK OR AFRICAN AMERICAN" then RACEN=3;
   else if RACE = "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER" then RACEN=4;
   else if RACE = "WHITE" then RACEN=5;
   else if RACE = "OTHER" then RACEN=6;
   else if RACE = "NOT REPORTED" then RACEN=7;else if RACE = " " then RACEN=8;

   if ETHNIC="HISPANIC OR LATINO" then ETHNICN=1;
   else if ETHNIC="NOT HISPANIC OR LATINO" then ETHNICN=2;
   else if ETHNIC="UNKNOWN" then ETHNICN=3;
   else if ETHNIC="NOT REPORTED" then ETHNICN=4;

   IF ARMCD='TQ' THEN DO;
      TRT01P='Tafenoquine';
      TRT01PN=1;
   END;

   IF ARMCD='PLACEBO' THEN DO;
      TRT01P='Placebo';
      TRT01PN=2;
   END;


   IF ACTARMCD='TQ' THEN DO;
      TRT01A='Tafenoquine';
      TRT01AN=1;
   END;

   IF ACTARMCD='PLACEBO' THEN DO;
      TRT01A='Placebo';
      TRT01AN=2;
   END;


   if RFXSTDTC NE '' AND LENGTH (RFXSTDTC) >10 THEN TRTSDTM= INPUT (RFXSTDTC,IS8601DT.);
   FORMAT TRTSDTM DATETIME19.;

   IF TRTSDTM NE . THEN   TRTSDT= DATEPART (TRTSDTM);
   FORMAT TRTSDT DATE9.;

   IF RFXENDTC NE '' AND LENGTH (RFXENDTC) >10 THEN TRTEDTM= INPUT (RFXENDTC,IS8601DT.);

   IF RFXENDTC NE '' THEN TRTEDT= INPUT (RFXENDTC,IS8601DA.);
   FORMAT TRTEDT DATE9.;

   IF TRTEDT NE . AND TRTSDT NE . THEN  TRTDURD=(TRTEDT - TRTSDT)+1;

   IF RFICDTC NE '' THEN SCRNFL="Y";
   IF RFXSTDTC NE '' THEN SAFFL='Y';
RUN;

/*to calculate BMI , height and weight to be captured in seperate variables*/
DATA VS;
   SET SDTM.VS;
   IF VSTESTCD IN ("HEIGHT" "WEIGHT" ) AND VISIT EQ 'Screening/Day -4 to -1';

   KEEP USUBJID VSTESTCD VSSTRESN;
RUN;
PROC TRANSPOSE DATA=VS OUT=VS_TRANS;
   BY USUBJID;
   VAR VSSTRESN;
   ID VSTESTCD;
RUN;
DATA VS_TRANS;
   SET VS_TRANS;
/*   conversion factor of cm to meter^2*/
   BMI= (WEIGHT/(HEIGHT)**2)*10000;
   RENAME BMI=BBMISI HEIGHT=BHGHTSI WEIGHT=BWGHTSI;
RUN;


DATA EO;
   SET SDTM.DS;
   LENGTH EOSSTT $200.;
   IF DSCAT = "DISPOSITION EVENT" AND DSSCAT = "END OF STUDY/EARLY TERMINATION"   THEN DO;

      IF DSDECOD = "COMPLETED" THEN EOSSTT ='Completed';
      IF DSDECOD ^= "COMPLETED" THEN EOSSTT ='Discontinued';
      IF DSDECOD ^= "COMPLETED" and DSDECOD NE '' THEN DCSREAS=DSDECOD;
      IF DSDECOD ='OTHER' THEN DCSREASP=DSTERM;

   END;

   IF DSCAT = "DISPOSITION EVENT" AND DSSCAT = "SCREEN FAILURE"   THEN DO;

      IF DSDECOD ^= " " THEN EOSSTT ='Screen Failure';
      DCSREAS='';

   END;


   IF DSCAT = "DISPOSITION EVENT" AND DSSTDTC NE '' THEN DO;
      EOSDT=INPUT (SCAN(DSSTDTC,1,"T"),IS8601DA.);
      FORMAT EOSDT DATE9.;
   END;

   IF EOSSTT NE '';
   KEEP USUBJID EOSSTT EOSDT DCSREAS DCSREASP DSSTDTC;
RUN;





DATA RAND;
   SET SDTM.DS;
   IF DSDECOD='RANDOMIZED';
   IF DSDECOD='RANDOMIZED'  AND DSSTDTC NE '' THEN DO;


      RANDDT= INPUT (SCAN(DSSTDTC,1,"T"),IS8601DA.);

      FORMAT RANDDT DATE9.;
      RANDFL="Y";
      ITTFL='Y';
   END;
   KEEP USUBJID RANDDT RANDFL ITTFL;
RUN;

DATA PP;
   SET SDTM.SV;
   IF VISITNUM EQ 15;
   PPROTFL1="Y";
   KEEP USUBJID PPROTFL1;
RUN;

PROC SORT NODUPKEY;BY USUBJID;RUN;


DATA FA1;
   SET SDTM.FACE;
   IF UPCASE (FAOBJ) IN ('COUGH' 'SHORTNESS OF BREATH (DIFFICULTY BREATHING)') AND VISITNUM LE 15;
   COVD14FL="Y";
   KEEP USUBJID COVD14FL;
RUN;
PROC SORT NODUPKEY; BY USUBJID COVD14FL;RUN;


DATA FA2;
   SET SDTM.FACE;
   IF UPCASE (FAOBJ) IN ('COUGH' 'SHORTNESS OF BREATH (DIFFICULTY BREATHING)') AND VISITNUM LE 29;
   COVD28FL="Y";
   KEEP USUBJID COVD28FL;
RUN;
PROC SORT NODUPKEY; BY USUBJID COVD28FL;RUN;





DATA DM4;
   MERGE DM3 (IN=A) VS_TRANS (IN=B) EO (IN=C) RAND PP FA1 FA2;
   BY USUBJID;
   IF A ;

   if EOSSTT = " " and TRTSDT ne . then EOSSTT = "Ongoing";
   IF ITTFL EQ 'Y' AND PPROTFL1 EQ 'Y' THEN PPROTFL='Y';
   IF COVD14FL EQ '' THEN COVD14FL='N';
   IF COVD28FL EQ '' THEN COVD28FL='N';
   IF RANDFL EQ '' THEN RANDFL='N';
   IF ITTFL EQ '' THEN ITTFL='N';
   IF PPROTFL EQ '' THEN PPROTFL='N';
   IF SAFFL EQ '' THEN SAFFL = 'N';
RUN;


DATA DM5;
SET DM4;
KEEP
STUDYID
USUBJID
SUBJID
RFSTDTC
RFENDTC
RFXSTDTC
RFXENDTC
RFICDTC
RFPENDTC
DTHDTC
DTHFL
SITEID
BRTHDTC
AGE
AGEU
AGEGR1
SEX
SEXN
RACE
RACEN
ETHNIC
ETHNICN
ARMCD
ARM
ACTARMCD
ACTARM
COUNTRY
RANDFL
RANDDT
SCRNFL
SAFFL
ITTFL
PPROTFL
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDTM
TRTSDT
TRTEDTM
TRTEDT
TRTDURD
EOSSTT
EOSDT
DCSREAS
DCSREASP
BBMISI
BHGHTSI
BWGHTSI
MFUV
VCYN
VCNUM
COVD14FL
COVD28FL
HOSPCOFL
;
RUN;


PROC SQL NOPRINT;
CREATE TABLE FINAL AS
SELECT
STUDYID  LABEL="Study Identifier"         ,
USUBJID  LABEL="Unique Subject Identifier"         ,
SUBJID   LABEL="Subject Identifier for the Study"        ,
RFSTDTC  LABEL="Subject Reference Start Date/Time"       ,
RFENDTC  LABEL="Subject Reference End Date/Time"         ,
RFXSTDTC LABEL="Date/Time of First Study Treatment"         ,
RFXENDTC LABEL="Date/Time of Last Study Treatment"       ,
RFICDTC  LABEL="Date/Time of Informed Consent"        ,
RFPENDTC LABEL="Date/Time of End of Participation"       ,
DTHDTC   LABEL="Date/Time of Death"       ,
DTHFL LABEL="Subject Death Flag"       ,
SITEID   LABEL="Study Site Identifier"       ,
BRTHDTC  LABEL="Date/Time of Birth"       ,
AGE   LABEL="Age"       ,
AGEU  LABEL="Age Units"       ,
AGEGR1   LABEL="Pooled Age Group 1"       ,
SEX   LABEL="Sex"       ,
SEXN  LABEL="Sex (N)"         ,
RACE  LABEL="Race"      ,
RACEN LABEL="Race (N)"        ,
ETHNIC   LABEL="Ethnicity"       ,
ETHNICN  LABEL="Ethnicity (N)"         ,
ARMCD LABEL="Planned Arm Code"         ,
ARM   LABEL="Description of Planned Arm"        ,
ACTARMCD LABEL="Actual Arm Code"       ,
ACTARM   LABEL="Description of Actual Arm"         ,
COUNTRY  LABEL="Country"         ,
RANDFL   LABEL="Randomization Flag" LENGTH=  1  ,
RANDDT   LABEL="Date of Randomization" LENGTH=  8  ,
SCRNFL   LABEL="Screened Population Flag" LENGTH=  1  ,
SAFFL LABEL="Safety Population Flag" LENGTH= 1  ,
ITTFL LABEL="Intent-To-Treat Population Flag" LENGTH= 1  ,
PPROTFL  LABEL="Per-protocol Population Flag" LENGTH= 1  ,
TRT01P   LABEL="Planned Treatment for Period 01" LENGTH= 40 ,
TRT01PN  LABEL="Planned Treatment for Period 01 (N)" LENGTH=   8  ,
TRT01A   LABEL="Actual Treatment for Period 01" LENGTH=  40 ,
TRT01AN  LABEL="Actual Treatment for Period 01 (N)" LENGTH= 8  ,
TRTSDTM  LABEL="Datetime of First Exposure to Treatment" LENGTH=  8  ,
TRTSDT   LABEL="Date of First Exposure to Treatment" LENGTH=   8  ,
TRTEDTM  LABEL="Datetime of Last Exposure to Treatment" LENGTH=   8  ,
TRTEDT   LABEL="Date of Last Exposure to Treatment" LENGTH= 8  ,
TRTDURD  LABEL="Total Treatment Duration (minutes)" LENGTH= 8  ,
EOSSTT   LABEL="End of Study Status" LENGTH= 200   ,
EOSDT LABEL="End of Study Date" LENGTH=   8  ,
DCSREAS  LABEL="Reason for Discontinuation from Study" LENGTH= 200   ,
DCSREASP LABEL="Reason Spec for Discont from Study" LENGTH= 200   ,
BBMISI   LABEL="Baseline BMI (kg/m2)" LENGTH=   8  ,
BHGHTSI  LABEL="Baseline Height (cm)" LENGTH=   8  ,
BWGHTSI  LABEL="Baseline Weight (kg)" LENGTH=   8  ,
MFUV  LABEL="Medical Follow-up Visit" LENGTH=   8  ,
VCYN  LABEL="Did the subject get a COVID-19 vaccine?" LENGTH=  200   ,
VCNUM LABEL="How many doses?" LENGTH=  8  ,
COVD14FL LABEL="Clinical recovery on Day 14 Flag" LENGTH=   200   ,
COVD28FL LABEL="Clinical recovery on Day28 Flag" LENGTH=   200   ,
HOSPCOFL LABEL="Hospitalized due to COVID-19" LENGTH= 200   
FROM DM5;
QUIT;

DATA ADSL (LABEL="Subject Level Analysis Dataset");
   SET FINAL;
RUN;



