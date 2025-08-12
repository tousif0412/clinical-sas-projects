/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADVS.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADVS
* Usage Notes: 
*
* SAS� Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: Arjun
* Date Created: 15-JUL-2022
* Modification History:
*******************************************************************/          
libname sdtm '/home/u63925560/CL/sdtm';
libname adam '/home/u63925560/CL/adam';


PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

OPTION VALIDVARNAME=UPCASE;


/*COPY ALL THE VARIABLES FROM VS AND SUPPVS*/

DATA VS1;
   SET SDTM.VS;
RUN;
PROC SORT;BY USUBJID VSSEQ;RUN;

/*to get variables from ADSL and VS*/
DATA VS2;
   LENGTH STUDYID $20.;
   MERGE VS1 (IN=A DROP=ARM ACTARM) ADAM.ADSL (IN=B);
   BY USUBJID;
   IF A AND B;
RUN;


DATA VS3;
   SET VS2;
   AVISIT = VISIT;
   AVISITN =VISITNUM;
   /*   Set to Concatenation of VS.VSTEST and VS.VSSTRESU*/

   PARAM=STRIP (VSTEST)||" ("|| STRIP (VSSTRESU)||")";

   PARAMCD=VSTESTCD;
   /*
   1 = Systolic Blood Pressure (mmHg)
   2 = Temperature (C)
   3 = Heart Rate (beats/min)
   4 = Diastolic Blood Pressure (mmHg)
   5 = Respiratory Rate (breaths/min)
   6 = Oxygen Saturation (%)
   7 = Weight (kg)
   8 = Height (cm)
   9 = Body Mass Index (kg/m2)
   */

      if VSTEST = "Systolic Blood Pressure"  then do ; PARAMN = 1 ;  end;
      if VSTEST = "Temperature"              then do ; PARAMN = 2 ;  end;
      if VSTEST = "Heart Rate"               then do ; PARAMN = 3 ;  end;
      if VSTEST = "Diastolic Blood Pressure" then do ; PARAMN = 4 ;  end;
      if VSTEST = "Respiratory Rate"         then do ; PARAMN = 5 ;  end;
      if VSTEST = "Oxygen Saturation"        then do ; PARAMN = 6 ;  end;
      if VSTEST = "Weight"                   then do ; PARAMN = 7 ;  end;
      if VSTEST = "Height"                   then do ; PARAMN = 8 ;  end;
      if VSTEST = "Body Mass Index"          then do ; PARAMN = 9 ;  end;

   AVALC =VSSTRESC;
   AVAL = VSSTRESN;
   /*Set to Numeric date part of VS.VSDTC*/

   IF VSDTC NE '' THEN DO;
      ADT= INPUT( SUBSTR (VSDTC,1,10),YYMMDD10.);
      /*Set to numeric date and time part of EG.VSDTC*/

      ADTM= INPUT (VSDTC,IS8601DT.);
      FORMAT ADT DATE9. ADTM DATETIME20.;

   END;
   /**/
   /*"Set to ADVS.ADT-ADSL.TRTSDT.*/
   /*If ADY is greater than or equal to 0 then set to ADY+1."*/

   NEW1= ADT;
   NEW2= TRTSDT;

   FORMAT NEW1 NEW2 DATE9.;

   IF NEW1 NE . AND NEW2 NE . THEN DO;

      IF NEW1 >= NEW2 THEN DO;
         ADY= (NEW1-NEW2)+1;
      END;


      IF NEW1 < NEW2 THEN DO;
         ADY= (NEW1-NEW2);
      END;
   END;


RUN;

/*BASELINE*/

/*Baseline Record Flag*/
/*Set to 'Y' for the record which is latest before treatment or 
latest record from VS.VSTPT = 'PREOPERATIVE'*/

DATA ADVS2;
   SET VS3;
   /*filter all records where test data present before treatment started*/
   IF ADT NE . AND ADT <= TRTSDT AND (AVAL NE . OR AVALC NE '');
RUN;
PROC SORT;BY USUBJID PARAMN PARAM VSSEQ ADT ADTM;RUN;

DATA ADVS3;
   SET ADVS2;
   BY USUBJID PARAMN PARAM VSSEQ ADT ADTM;
   /*now keep ONLY latest record from before treatment started*/
   IF LAST.PARAMN;
   KEEP USUBJID PARAMN AVISITN;
RUN;
PROC SORT;BY USUBJID PARAMN AVISITN;RUN;


PROC SORT DATA=VS3;BY USUBJID PARAMN AVISITN;RUN;

DATA VS4;
   MERGE VS3 (IN=A) ADVS3 (IN=B);
   /*do not bring single extra column from ADVS3*/
   BY USUBJID PARAMN AVISITN;
   /*Set to 'Y' for the record which is latest before treatment */
   IF A AND B THEN ABLFL="Y";
RUN;
PROC SORT DATA=VS4;BY USUBJID PARAMN AVISITN ADT ADTM;RUN;

DATA VS5;
   SET VS4;
   LENGTH CRIT1 $200.;
   BY USUBJID PARAMN AVISITN ADT ADTM;
   /*Set to ADVS.AVAL for the Baseline and Post-baseline records where ADVS.ABLFL = 'Y'*/
   /*Set to ADVS.AVALC for the Baseline and Post-baseline records where ADVS.ABLFL = 'Y'*/

   RETAIN BASE BASEC;

   IF FIRST.PARAMN THEN BASE=.;
   IF FIRST.PARAMN THEN BASEC=.;

   IF ABLFL EQ 'Y' THEN DO;
      BASE=AVAL;
      BASEC=AVALC;
   END;
   /*Set to ADVS.AVAL-ADVS.BASE for Post-baseline records.*/
   /*Set to ADVS.CHG/ADVS.BASE*100 for Post-baseline records. If BASE is not missing or BASE ne 0*/


   ELSE DO;
      IF AVAL NE . AND BASE NE . THEN CHG=AVAL-BASE;
      PCHG= ((AVAL-BASE)/BASE)*100;
   END;

   /*Set to 'Y' where ABLFL = 'Y' and for Post-Baseline records.*/

   IF ABLFL EQ 'Y' THEN DO;ANL01FL='Y';END;
   IF ADT >= TRTSDT THEN DO;ANL01FL='Y';END;
   /*"Set to 'Y' if (ADT >= TRTSDT) and (ADT <= TRTEDT);*/
   /*Else set to null;*/
   /*"*/

   if (ADT >= TRTSDT) and (ADT <= TRTEDT) THEN DO;ONTRTFL='Y';END;


   /*Criteria flag*/
   if VSTESTCD = "SYSBP" and aval ne . then do;

      if 90<=aval<=120 then DO;
         CRIT1fl="Y";
         CRIT1="Normal range";
      end;
      if 120< aval <= 140 then do;
         CRIT1fl="Y";
         CRIT1="Abnormal and Not Clinically Significant";
      end;
      IF AVAL<90 OR AVAL>140 THEN do;
         CRIT1fl="Y";
         CRIT1="Abnormal and Clinically Significant";
      end;

   END;

   if VSTESTCD = "DIABP" and aval ne . then do;

   if 60<=aval<=80 then DO;CRIT1fl="Y";
   CRIT1="Normal range";end;
   if 80< aval <= 90 or  50<= aval < 60 then do;
   CRIT1fl="Y";CRIT1="Abnormal and Not Clinically Significant";end;
   IF AVAL<50 OR AVAL>90 THEN do;CRIT1fl="Y";
   CRIT1="Abnormal and Clinically Significant";end;

   END;


   if VSTESTCD = "RESP" and aval ne . then do;

   if 12<=aval<=18 then DO;CRIT1fl="Y";CRIT1="Normal range";end;
   if 18< aval <= 30 or  10<= aval < 12 then do;CRIT1fl="Y";
   CRIT1="Abnormal and Not Clinically Significant";end;
   IF AVAL<10 OR AVAL>30 THEN do;CRIT1fl="Y";
   CRIT1="Abnormal and Clinically Significant";end;

   END;

   if VSTESTCD in ("HR" "PULSE") and aval ne . then do;

   if 60<=aval<=90 then DO;CRIT1fl="Y";CRIT1="Normal range";end;
   if 90< aval <= 100 or  40<= aval < 60 then do;
   CRIT1fl="Y";CRIT1="Abnormal and Not Clinically Significant";end;
   IF AVAL<40 OR AVAL>100 THEN do;CRIT1fl="Y";
   CRIT1="Abnormal and Clinically Significant";end;

   END;

   if VSTESTCD = "TEMP" and aval ne . then do;

   if 36.5<=aval<=37.3 then DO;CRIT1fl="Y";
   CRIT1="Normal range";end;
   if 37.3< aval <= 39.5 or  34.5<= aval < 36.5 then do;
   CRIT1fl="Y";CRIT1="Abnormal and Not Clinically Significant";end;
   IF AVAL<34.5 OR AVAL>39.5 THEN do;CRIT1fl="Y";
   CRIT1="Abnormal and Clinically Significant";end;

   END;


   if VSTESTCD = "OXYSAT" and aval ne . then do;

   if 95<=aval<=100 then DO;CRIT1fl="Y";
   CRIT1="Normal range";end;
   if   92<= aval < 95 then do;CRIT1fl="Y";
   CRIT1="Abnormal and Not Clinically Significant";end;
   IF AVAL<92 OR AVAL>100 THEN do;CRIT1fl="Y";
   CRIT1="Abnormal and Clinically Significant";end;

   END;
RUN;


DATA TEST;
SET VS5;
KEEP
STUDYID
USUBJID
SUBJID
SITEID
AGE
AGEU
SEX
RACE
ETHNIC
COUNTRY
SAFFL
ITTFL
PPROTFL
RANDFL
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDT
TRTEDT
VSSEQ
VISIT
VISITNUM
VSDTC
AVISIT
AVISITN
PARAM
PARAMN
PARAMCD
AVALC
AVAL
ADT
ADTM
ADY 
ABLFL
BASE
BASEC
CHG
PCHG
ANL01FL
ONTRTFL
CRIT1
CRIT1fl
;
RUN;

/*NOW APPLY LABEL LENGTH PER SPECS*/

DATA ADVS (LABEL="Vital Signs Analysis Dataset");
   SET TEST;
RUN;
