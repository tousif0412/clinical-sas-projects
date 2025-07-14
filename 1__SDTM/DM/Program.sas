/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: DM.SAS  
*
* Program Type: SDTM
*
* Purpose: To produce DM
*
* Author: Tousif
* Date Created: 11-JUN-2025
* Modification History:
*******************************************************************/          

libname raw"/home/u63981529/CL/RAW";

PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

data dm1;
   /*if variable name in raw data set and SDTM is same then first we rename the raw variable*/
   set raw.dm (rename=(age=agex sex=sexx race=racex ETHNIC=ETHNICX));
   LENGTH ETHNIC $200.;
   STUDYID  = 'AA-2020-06';
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (subnum);

/*convert to character*/
/*   YYYY-MM-DDThh:mm:ss*/
   BRTHDTC= put (BRTHDAT,IS8601DA.);
   AGE=AGEX;
   AGEU="YEARS";
   SEX=sexx;
   RACE= RACEX;

   IF ETHNICX='HISP' THEN ETHNIC='HISPANIC OR LATINO';
      ELSE IF ETHNICX='NHISP' THEN ETHNIC='NOT HISPANIC OR LATINO';
      ELSE IF ETHNICX='U' THEN ETHNIC='UNKNOWN';
      ELSE IF ETHNICX='DECLINED TO ANSWER' THEN ETHNIC='NOT REPORTED';

   KEEP STUDYID DOMAIN SITEID SUBJID USUBJID BRTHDTC AGE AGEU SEX RACE ETHNIC;
run;
PROC SORT;BY USUBJID;RUN;

DATA IC;
   SET RAW.IC;
   STUDYID="AA-2020-06";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   /*   common join variable*/
   USUBJID= strip (STUDYID)||"-"||strip (subnum);
   RFICDTC1= PUT (ICDAT,YYMMDD10.);
   /*Set to IC.ICDAT*/

   RFICDTC= PUT (ICDAT,is8601da.);
   KEEP USUBJID RFICDTC ;
RUN;
PROC SORT;BY USUBJID;RUN;

DATA DS1;
   SET RAW.DS;
   STUDYID="AA-2020-06";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (subnum);
   IF DSDTHDAT NE . THEN DTHDTC = PUT (DSDTHDAT,YYMMDD10.);
   IF DTHDTC NE '' THEN DTHFL='Y';
   IF DSLVDAT NE . THEN   RFPENDTC= PUT (DSLVDAT,YYMMDD10.);
   KEEP USUBJID DTHDTC DTHFL RFPENDTC;
RUN;

PROC SORT;BY USUBJID;RUN;

data ds;
   set ds1;
   by USUBJID;
   if LAST.USUBJID;
run;

PROC DATASETS LIB=WORK nolist;
delete ds1;
RUN;
QUIT;

data ex1;
   set raw.ex;
run;

proc sort data=ex1; by subnum EXSTDAT; run;

data ex;
   set ex1;
   retain RFXSTDTC RFSTDTC ;
   by subnum EXSTDAT;
   if first.subnum then do;
      IF EXSTDAT NE . THEN DO;
         RFXSTDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
         RFSTDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
      END;
   end;
   if last.subnum then do;
      IF EXSTDAT NE . THEN DO;
      RFXENDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
      RFENDTC=PUT (EXSTDAT,YYMMDD10.)||"T"||PUT (EXSTTIM,TOD8.);
      END;
   end;
   if last.subnum;
   KEEP USUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC;
   STUDYID="AA-2020-06";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (subnum);
run;
PROC DATASETS LIB=WORK nolist;
delete ex1;
RUN;
QUIT;

DATA TRT;
   SET RAW.DUMMY_RND;
   LENGTH ARMCD ACTARMCD $8. ARM ACTARM $200.;
   STUDYID="AA-2020-06";
   DOMAIN='DM';

   SITEID=SUBSTR(USUBJID,12,3);
   SUBJID=substr(USUBJID,15);
   USUBJID= strip (STUDYID)||"-"||strip (SUBSTR(USUBJID,12));


   ARMCD=TRTCD;
   IF ARMCD='TQ' THEN ARM='TQU';
   IF ARMCD='PLACEBO' THEN ARM='PLACEBO';

   ACTARMCD=TRTCD;
   IF ACTARMCD='TQ' THEN ACTARM='TQU';
   IF ACTARMCD='PLACEBO' THEN ACTARM='PLACEBO';

   KEEP USUBJID ARMCD ARM ACTARMCD ACTARM;
RUN;
PROC SORT;BY USUBJID;RUN;

DATA SCF;
   SET RAW.DAT_SUB;
   STUDYID="AA-2020-06";
   DOMAIN='DM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);
   USUBJID= strip (STUDYID)||"-"||strip (subnum);

   IF STATUSID=15 THEN DO;
   ARMNRS='SCREEN FAILURE';
   ACTARMUD='SCREEN FAILURE';
   END;

   KEEP USUBJID ARMNRS ACTARMUD;
RUN;
PROC SORT;BY USUBJID;RUN;


DATA FINAL;
   MERGE DM1 (IN=A) IC DS EX TRT SCF;
   BY USUBJID;
   IF A;
   IF ARM='ASSIGNED, NOT TREATED' AND ACTARM EQ '' THEN DO;
      ARMNRS='NOT ASSIGNED';
   END;
   COUNTRY='USA';
RUN;


DATA FINAL1;
RETAIN
STUDYID
DOMAIN
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
SEX
RACE
ETHNIC
ARMCD
ARM
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY;
SET FINAL;
KEEP
STUDYID
DOMAIN
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
SEX
RACE
ETHNIC
ARMCD
ARM
ACTARMCD
ACTARM
ARMNRS
ACTARMUD
COUNTRY
;
RUN;

/* Save Final DM Dataset to Output Folder */

libname Output '/home/u63981529/SDTM-DM/Outputs';
run;

Data Output.DM1 ;
Set Final1 ;
Proc sort ; By USUBJID ;
Run ;

/* Export DM to CSV */

proc export data=Output.DM1
    outfile="/home/u63981529/SDTM-DM/Outputs/dm1_final.csv"
    dbms=csv
    replace;
run;

