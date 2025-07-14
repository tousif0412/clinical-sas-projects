/*******************************************************************
* Client:  xxxxxx                                                          
* Project:  yyyyyyy                                                   
* Program: CM.SAS  
*
* Program Type: SDTM                
*
* Author: Tousif
* Date Created: 25-JUN-2025
* Modification History:
*******************************************************************/          
libname raw "/home/u63981529/CL/RAW";
libname sdtm '/home/u63981529/CL/sdtm';

PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;

/*Concomitant Medicine*/
DATA CM1;
   SET RAW.CM (RENAME=(CMTRT=CMTRTX CMROUTE=CMROUTEX CMINDC=CMINDCX CMDOSE=CMDOSEX));

   IF CMTRTX NE '';

   CMTRT=upcase(CMTRTX);
   CMINDC=CMINDCX;

   length CMROUTE $200.;
   if CMROUTEX = "CONTINHAL" then CMROUTE ="RESPIRATORY (INHALATION)";
   else if CMROUTEX = "INHALATION" then CMROUTE ="RESPIRATORY (INHALATION)";
   else if CMROUTEX = "INTMUSC" then CMROUTE ="INTRAMUSCULAR";
   else if CMROUTEX = "INTVEN" then CMROUTE ="INTRAVENOUS";
   else if CMROUTEX = "NASAL" then CMROUTE ="NASAL";
   else if CMROUTEX = "ORAL" then CMROUTE ="ORAL";
   else if CMROUTEX = "SUBCUT" then CMROUTE ="SUBCUTANEOUS";
   else if CMROUTEX = "SUBLINGUAL" then CMROUTE ="SUBLINGUAL";
   else if CMROUTEX = "TOPICAL" then CMROUTE ="TOPICAL";


   CMDOSE=CMDOSEX;

   _YY= SCAN (CMSTDAT,1,'-');
   _MM = SCAN (CMSTDAT,2,'-');
   _DD =SCAN (CMSTDAT,3,'-');
   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMSTTIM='U' THEN CMSTTIM='';
   IF CMSTTIM NE '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMSTTIM);END;

   IF CMSTTIM EQ '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD);
   END;

   _YY1= SCAN (CMENDAT,1,'-');
   _MM1 = SCAN (CMENDAT,2,'-');
   _DD1 =SCAN (CMENDAT,3,'-');

   IF CMENTIM='U' THEN CMENTIM='';

   IF _YY1='UNK' THEN _YY1='';
   IF _MM1='UNK' THEN _MM1='';
   IF _DD1='UNK' THEN _DD1='';

   IF CMENTIM NE '' THEN DO;
   CMENDTC = CATX ("-",_YY1,_MM1,_DD1)||"T"||STRIP (CMENTIM);END;


   IF CMENTIM EQ '' THEN DO;
   CMENDTC = CATX ("-",_YY1,_MM1,_DD1);
   END;

   IF CMONGO EQ 'X' THEN CMENRF='ONGOING' ;
   IF CMONGO EQ '' THEN CMENRF="BEFORE";

   /*CMDECOD is the standardized medication/therapy term derived by the sponsor from the coding dictionary. It is expected that the reported term */
   /*(CMTRT) or the modified term (CMMODIFY) will be coded using a standard dictionary. */
   CMDECOD= STRIP (PREFERRED_NAME);

   CMCAT='CONCOMITANT MEDICATION';

   CMDOSU=CMDOSEU;
   if CMDOSU="APPL" then CMDOSU="APPLICATION";
   CMDOSFRQ=CMFREQ;


      STUDYID  =  'AA-2020-06'; 
      if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);

   DOMAIN='CM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);


RUN;



/*Concomitant PROCEDURES*/
DATA CM1_P;
   SET RAW.CMP (RENAME=(CMTRT=CMTRTX CMINDC=CMINDCX));
   CMTRT=CMTRTX;
   CMINDC=CMINDCX;
   IF CMTRT NE '';


   _YY= SCAN (CMSTDAT,1,'-');
   _MM = SCAN (CMSTDAT,2,'-');
   _DD =SCAN (CMSTDAT,3,'-');

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMSTTIM='U' THEN CMSTTIM='';
   IF CMSTTIM NE '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMSTTIM);END;

   IF CMSTTIM EQ '' THEN DO;
   CMSTDTC = CATX ("-",_YY,_MM,_DD);
   END;

   _YY= SCAN (CMENDAT,1,'-');
   _MM = SCAN (CMENDAT,2,'-');
   _DD =SCAN (CMENDAT,3,'-');

   IF CMENTIM='U' THEN CMENTIM='';

   IF _YY='UNK' THEN _YY='';
   IF _MM='UNK' THEN _MM='';
   IF _DD='UNK' THEN _DD='';

   IF CMENTIM NE '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD)||"T"||STRIP (CMENTIM);END;


   IF CMENTIM EQ '' THEN DO;
   CMENDTC = CATX ("-",_YY,_MM,_DD);
   END;

   IF CMONGO EQ 'X' THEN CMENRF='ONGOING' ;
   IF CMONGO EQ '' THEN CMENRF="BEFORE";

   CMDECOD= STRIP (PT_TERM);

   CMCAT='PROCEDURE';

      STUDYID  =  'AA-2020-06'; 
      if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);

   DOMAIN='CM';
   SITEID=SITENUM;
   SUBJID=substr(subnum,4);

RUN;

DATA CM2;
   SET CM1 CM1_P;
RUN;


*EPOCH;;
PROC SORT DATA=CM2;
   BY USUBJID;
RUN;




*EPOCH;;
DATA CM22;
   LENGTH epoch $200 domain $2;
   MERGE SDTM.SE(WHERE=(taetord=1) RENAME=(sestdtc=scrnst seendtc=scrnend) KEEP=usubjid taetord sestdtc seendtc)
        SDTM.SE(WHERE=(taetord=2) RENAME=(sestdtc=cycle1st seendtc=cycle1end) KEEP=usubjid taetord sestdtc seendtc)
        SDTM.SE(WHERE=(taetord=3) RENAME=(sestdtc=ltfupst seendtc=ltfupend) KEEP=usubjid taetord sestdtc seendtc)
        CM2(in=a);
   BY usubjid;
   IF a;
   IF ltfupst^='' & substr(ltfupst,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(ltfupend,1,10) THEN EPOCH='FOLLOW-UP';
      ELSE IF cycle1st^='' & substr(cycle1st,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(cycle1end,1,10) THEN EPOCH='TREATMENT';
      ELSE IF scrnst^='' & SUBSTR(scrnst,1,10)<=substr(CMSTDTC,1,10)<=SUBSTR(scrnend,1,10) THEN EPOCH='SCREENING';
RUN;



*Study Day;
proc sort data=sdtm.dm out=dm1 nodupkey;by usubjid;run;
DATA DM1;
SET dm1;
RFSTDTC_N = DATEPART (INPUT (RFSTDTC,??IS8601DT.));

FORMAT RFSTDTC_N YYMMDD10.;
KEEP USUBJID RFSTDTC_N;
RUN;



DATA CM4;
   MERGE CM22(in=a)
        DM1(IN=b KEEP=USUBJID  RFSTDTC_N );
   BY USUBJID;
   IF a & b;   
   CMSTDTC_N = INPUT (CMSTDTC,??YYMMDD10.);
    CMENDTC_N = INPUT (CMENDTC,??YYMMDD10.);

/*   Study day of start of medication relative to the sponsor-defined RFSTDTC.*/
   IF CMSTDTC_N NE . AND RFSTDTC_N NE . THEN DO;
   IF CMSTDTC_N >= RFSTDTC_N THEN CMSTDY= CMSTDTC_N - RFSTDTC_N +1;
   ELSE IF CMSTDTC_N < RFSTDTC_N THEN CMSTDY = CMSTDTC_N - RFSTDTC_N;
   END;

/*Study day of end of medication relative to the sponsor-defined RFSTDTC. */
   IF CMENDTC_N NE . AND RFSTDTC_N NE . THEN DO;
   IF CMENDTC_N >= RFSTDTC_N THEN CMENDY= CMENDTC_N - RFSTDTC_N +1;
   ELSE IF CMENDTC_N < RFSTDTC_N THEN CMENDY = CMENDTC_N - RFSTDTC_N;
   END;

RUN;

*SEQ;;
PROC SORT DATA=CM4 out=CM5;
   BY STUDYID USUBJID CMTRT CMSTDTC
;
RUN;

DATA CM6;
   SET CM5;
   BY STUDYID USUBJID CMTRT CMSTDTC;
   IF first.usubjid THEN CMSEQ=1;
      ELSE CMSEQ+1;
RUN;

DATA FINAL;
RETAIN

STUDYID
DOMAIN
USUBJID
CMSEQ
CMTRT
CMDECOD
CMCAT
CMINDC
CMDOSE
CMDOSU
CMDOSFRQ
CMROUTE
EPOCH
CMSTDTC
CMENDTC
CMSTDY
CMENDY
CMENRF;
SET CM6;
KEEP
STUDYID
DOMAIN
USUBJID
CMSEQ
CMTRT
CMDECOD
CMCAT
CMINDC
CMDOSE
CMDOSU
CMDOSFRQ
CMROUTE
EPOCH
CMSTDTC
CMENDTC
CMSTDY
CMENDY
CMENRF
;
RUN;

/* Save Final DM Dataset to Output Folder */

libname Outputs '/home/u63981529/CM_SDTM/Outputs';
run;

Data Outputs.CM1 ;
Set Final ;
Proc sort ; By USUBJID ;
Run ;

/* Export DM to CSV */

proc export data=Outputs.CM1
    outfile="/home/u63981529/CM_SDTM/Outputs/CM1_final.csv"
    dbms=csv
    replace;
run;
