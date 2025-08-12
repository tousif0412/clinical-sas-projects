/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: ADCM.SAS  
*
* Program Type: ADAM
*
* Purpose: To produce ADAE
* Usage Notes: 
*
* SAS� Version: 9.4
* Operating System: Windows 2003 R2 Standard Edition.                   
*
* Author: Arjun
* Date Created: 11-JUN-2022
* Modification History:
*******************************************************************/          
libname sdtm '/home/u63981529/CL/sdtm';
libname adam '/home/u63981529/CL/adam';


PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

OPTION VALIDVARNAME=UPCASE;


/*COPY ALL THE VARIABLES FROM AE AND SUPPAE*/
/*main data sourrce*/
DATA AE1;
   SET SDTM.AE;
RUN;
PROC SORT;BY USUBJID AESEQ;RUN;


/*supp data source*/
DATA SUPPAE;
   SET SDTM.SUPPAE;
   AESEQ= INPUT (IDVARVAL,BEST.);
RUN;

PROC SORT;BY USUBJID AESEQ;RUN;

PROC TRANSPOSE DATA=SUPPAE OUT=SUPPAE_TRANS;
   BY USUBJID AESEQ;
   ID QNAM;
   VAR QVAL;
   IDLABEL QLABEL;
RUN;


DATA AE2;
   MERGE AE1 (IN=A) SUPPAE_TRANS (IN=B);
   BY USUBJID AESEQ;
   IF A ;
RUN;

/*bring required variables from adsl*/
DATA AE3;
   LENGTH STUDYID $20. USUBJID $200.;
   MERGE AE2 (IN=A DROP=ARM ACTARM) ADAM.ADSL (IN=B);
   BY USUBJID;
   IF A AND B;
RUN;

/*ASEV*/
/**/
/*"""If AE.AESEV=’MILD’ then ASEV=’Mild’ Else if AE.AESEV=’MODERATE’ then ASEV=’Moderate’ Else if AE.AESEV is equal to ‘SEVERE’ then ASEV=’Severe’*/
/*if AE.AESEV = 'LIFE-THREATENING' then ASEV = 'Life-threatening'"*/

/*AREL*/
/**/
/*"If AE.AEREL= 'DEFINITELY RELATED' then AREL=Definitely related' */
/*Else if AE.AREL='PROBABLY RELATED' then AREL = ""Probably related' */
/*Else if AE.AREL='POSSIBLY RELATED' then AREL = ""Possibly related' */
/*Else if AE.AREL='UNLIKELY RELATED' then AREL = ""Unlikely related' */
/*Else if AE.AREL='NOT RELATED' then AREL = ""Not related'"*/
/**/

/*AACN*/
/**/
/*AE.AEACN in propcase*/

DATA AE4;
   SET AE3;
   length asev AREL AACN RELGR1$ 25.;
   IF AESEV="MILD" THEN DO;ASEVN=1;ASEV="Mild";end;
   else IF AESEV="MODERATE" THEN DO;ASEVN=2;ASEV="Moderate";end;
   else IF AESEV="SEVERE" THEN DO;ASEVN=3;ASEV="Severe";end;
   else if aesev='LIFE-THREATENING' THEN DO;ASEVN=4;ASEV="Life-threatening";end;

   If AEREL= 'DEFINITELY RELATED' then do; AREL='Definitely related' ;ARELN=1;end;
   Else if AEREL='PROBABLY RELATED' then do; AREL = "Probably related";ARELN=2;end;
   Else if AEREL='POSSIBLY RELATED' then do; AREL = "Possibly related";ARELN=3;end; 
   Else if AEREL='UNLIKELY RELATED' then do; AREL = "Unlikely related";ARELN=4;end; 
   Else if AEREL='NOT RELATED' then do; AREL = "Not related";ARELN=5;end;

   IF AEACN ='NONE' THEN DO;AACN='None';AACNN=1;END;
   ELSE IF AEACN ='INTERRUPTED' THEN DO;AACN='Interrupted';AACNN=2;END;
   ELSE IF AEACN  IN ('DISCONTINUED' 'DRUG WITHDRAWN') THEN DO;AACN='Discontinued or withdrawn';AACNN=3;END;
   ELSE IF AEACN ='NOT APPLICABLE' THEN DO;AACN='Not Applicable';AACNN=4;END;
   ELSE IF AEACN ='UNKNOWN' THEN DO;AACN='Unknown';AACNN=5;END;
   ELSE IF AEACN='DOSE NOT CHANGED' THEN DO; AACN='Dose not changed';AACNN=6;END;
   /*RELGR1*/
   /*"if AREL IN 1 or 2 or 3 then set to ""Related"";*/
   /*Else set to ""Not Related"""*/

   IF ARELN IN ( 1 2 3) THEN RELGR1="Related";
   ELSE RELGR1="Not Related";
run;


/**/
/*ASTDTM*/
/**/
/*"Datetime part of ASTDTC, then convert to SAS date format*/
/**/
/*For Missing Date values:*/
/**/
/*If day is missing and month and year are available in AE.AESTDTC then set 
day value os ""01"";*/
/**/
/*For Missing time value:*/
/**/
/*If date in AE.AESTDTC is not missing and time in AE.AESTDTC is missing 
and AE.AESTDTC equals to ADSL.TRTSDT*/
/*then set to timepart of ADSL.TRTSDTM +1;*/
/*If date in AE.AESTDTC is not missing and time in AE.AESTDTC is missing 
and AE.AESTDTC not equals to ADSL.TRTSDT */
/*then set to ""00:01"";"*/
/**/
/*ASTDT*/
/**/
/*Date part of ASTDTM, then convert to SAS date format*/
/**/
/*ASTDTF*/
/**/
/*"If start date is completely missing or missing the year then ASTDTF=’Y’ Else if start date has month missing then ASTDTF=’M’*/
/*Else if start date has day missing then ASTDTF=’D’"*/

DATA AE5;
   SET AE4 ;
   /*separate date and time part*/
   STDATEC= SCAN (AESTDTC,1,'T');
   STTIMEC= SCAN (AESTDTC,2,'T');

   IF STTIMEC EQ '' THEN STTIMEC='00:01';
   /*separate year , month and day from date*/
   STYEAR= INPUT (SCAN (STDATEC,1,"-"),BEST.);
   STMONTH= INPUT (SCAN (STDATEC,2,"-"),BEST.);
   STDAY= INPUT (SCAN (STDATEC,3,"-"),BEST.);

   IF STYEAR NE . AND STMONTH NE . AND STDAY NE . THEN DO;
      STDATE= MDY (STMONTH,STDAY,STYEAR);
      FORMAT STDATE DATE9.;
   END;

   /*missing imputation for day*/
   IF STYEAR NE . AND STMONTH NE . AND STDAY EQ . THEN DO;
      STDATE= MDY (STMONTH,01,STYEAR);
      ASTDTF='D';
   END;

   ASTDTM_C= PUT (STDATE,YYMMDD10.)||"T"|| STRIP (STTIMEC);
   ASTDTM= INPUT (ASTDTM_C,IS8601DT.);
   FORMAT ASTDTM DATETIME20.;

   ASTDT= DATEPART(ASTDTM);
   FORMAT ASTDT DATE9.;

RUN;

/*AENDTM*/
/**/
/*"Set to AE.AEENDTC, then convert to SAS date time format*/
/**/
/**/
/*For Missing Date values:*/
/**/
/*If day is missing and month and year are available in AE.CMEnDTC then set
to last day value of the month;*/
/**/
/*For Missing time value:*/
/**/
/*If date in AE.AEENDTC is not missing and time in AE.AEENDTC is missing 
and AE.AEENDTC  */
/*not equals to ADSL.TRTSDT then set to ""23:59"";"*/
/**/
/*AENDT*/
/**/
/*"Date part of AENDTM, then convert to SAS date format*/
/*"*/
/**/
/*AENDTF*/
/**/
/*"If end date is completely missing or missing the year then AENDTF=’Y’ */
/*Else if end date has month missing then AENDTF=’M’ */
/*Else if end date has day missing then AENDTF=’D’"*/


DATA AE6;
   SET AE5 ;

   /*separate date and time part*/
   ENDATEC= SCAN (AEENDTC,1,'T');
   ENTIMEC= SCAN (AEENDTC,2,'T');


   IF ENDATEC NE '' THEN DO;
      /*missing imputation for time part*/
      IF ENTIMEC EQ '' THEN ENTIMEC='23:59';
   END;
   /*separate year , month and day from date*/
   ENYEAR= INPUT (SCAN (ENDATEC,1,"-"),BEST.);
   ENMONTH= INPUT (SCAN (ENDATEC,2,"-"),BEST.);
   ENDAY= INPUT (SCAN (ENDATEC,3,"-"),BEST.);

   IF ENYEAR NE . AND ENMONTH NE . AND ENDAY NE . THEN DO;
      ENDATE= MDY (ENMONTH,ENDAY,ENYEAR);
      FORMAT ENDATE DATE9.;
   END;



   /*set to last day value of the month*/
   IF ENYEAR NE . AND ENMONTH NE . AND ENDAY EQ . THEN DO;
      ENDATE= INTNX ('MONTH', INPUT (STRIP (AEENDTC)||"-01",YYMMDD10.),0,'end');
      AENDTF='D';
   END;

   IF ENTIMEC NE '' THEN DO;
      AENDTM_C= PUT (ENDATE,YYMMDD10.)||"T"|| STRIP (ENTIMEC);
   END;
   AENDTM= INPUT (AENDTM_C,??IS8601DT.);
   FORMAT AENDTM DATETIME20.;

   AENDT= DATEPART(AENDTM);
   FORMAT AENDT DATE9.;



RUN;

/*ASTDY*/
/**/
/*(ASTDT - ADSL.TRTSDT) + 1, if ASTDT >= ADSL.TRTSDT; else ASTDT - ADSL.TRTSDT, if ASTDT < ADSL.TRTSDT.*/
/**/
/*AENDY*/
/**/
/*(AENDT - ADSL.TRTSDT) + 1, if AENDT >= ADSL.TRTSDT; else AEND T - ADSL.TRTSDT, if AENDT < ADSL.TRTSDT*/

DATA AE7;
   SET AE6 ;

   NEW1= ASTDT;
   NEW2= TRTSDT;
   NEW3= AENDT;

   FORMAT NEW1 NEW2 DATE9.;

   IF NEW1 NE . AND NEW2 NE . THEN DO;

   IF NEW1 >= NEW2 THEN DO;
   ASTDY= (NEW1-NEW2)+1;
   END;


   IF NEW1 < NEW2 THEN DO;
   ASTDY= (NEW1-NEW2);
   END;
   END;

   IF NEW2 NE . AND NEW3 NE . THEN DO;

   IF NEW3 >= NEW2 THEN DO;
   AENDY= (NEW3-NEW2)+1;
   END;


   IF NEW3 < NEW2 THEN DO;
   AENDY= (NEW3-NEW2);
   END;
   END;
   /*TRTEMFL*/
   /*"if ADSL.TRTSDT <= ASTDT<= ADSL.RFPENDTC then TRTEMFL='Y'*/
   /*Or*/
   /*Set to ""Y"" when SDTM.SUPPAE.QNAM='AETRTEM' AND QVAL=""Y"""*/

   IF AETRTEM EQ 'Y' THEN DO;TRTEMFL='Y';END;
   RFPENDTN= INPUT (RFPENDTC,YYMMDD10.);

   IF RFPENDTN >= ASTDT >= TRTSDT THEN DO;TRTEMFL='Y';END;
RUN;

DATA TEST;
SET AE7;
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
TRT01P
TRT01PN
TRT01A
TRT01AN
TRTSDT
TRTEDT
AESEQ
AETERM
AEDECOD
AEBODSYS
AEBDSYCD
AELLT
AELLTCD
AEPTCD
AEHLT
AEHLTCD
AEHLGT
AEHLGTCD
AESOC
AESOCCD
AESTDTC
ASTDT
ASTDTM
ASTDTF
AEENDTC
AENDT
AENDTM
AENDTF
AESTDY
ASTDY
AEENDY
AENDY
TRTEMFL
AESER
ASEV
ASEVN
AREL
ARELN
RELGR1
AEACNOTH
AACN
AACNN
AEOUT
AESCONG
AESDISAB
AESDTH
AESHOSP
AESLIFE
AESMIE
;
RUN;

/*apply attributes per specs*/

DATA ADAE (LABEL="Adverse Event Analysis Dataset");
   SET TEST;
RUN;
