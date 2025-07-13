/*******************************************************************
* Client:  xxx                                                          
* Project:  yyy                                                   
* Program: AE.SAS  
*
* Program Type: SDTM
* Purpose: AE      

* Date Created: 08-JUNE-2025
* Modification History:
*******************************************************************/          

libname raw "/home/u63981529/CL/RAW";
libname sdtm '/home/u63981529/CL/sdtm';


PROC DATASETS LIB=WORK KILL;
RUN;
QUIT;


data ae;
   set raw.ae;
run;


/***Required data for AE***/

data ae1;
   length USUBJID $ 40 AELLT AEDECOD AEHLT AEHLGT AEBODSYS
         AESOC AEACN  AEREL AEOUT $ 200 AESER $ 1 AESTDTC AEENDTC $ 16;
   set ae;
   /*consider only subjects with Adverse Event*/
      if AETERM ne " ";
      
    STUDYID  = 'AA-2020-06'; 
   if SUBNUM ne ' ' then USUBJID = strip(STUDYID)||'-'||strip(SUBNUM);
      DOMAIN   = 'AE';
      if not missing (AETERM) then AETERM = upcase(strip(AETERM));
      AELLT    =  strip (LLT_NAME);
      /*      convert from character to numeric*/
      AELLTCD  =   input (LLT_CODE,??best.);

      AEDECOD  =  strip (PT_TERM) ;

      AEPTCD   =   input (PT_CODE,??best.);
      AEHLT    =  strip (HLT_TERM);
      AEHLTCD     =  input (HLT_CODE,??best.);

      AEHLGT      =  strip (HLGT_TERM);
      AEHLGTCD =  input (HLGT_CODE,??best.);

      AEBODSYS =  strip (SOC_TERM);
      AEBDSYCD =  input (SOC_CODE,??best.);
      AESOC    =  strip (SOC_TERM);
      AESOCCD     =  input (SOC_CODE,??best.);

      AEONGO      =  AEONG;

      if AESAE = "N" then AESER = "N";
      if AESAE = "Y" then AESER = "Y";


      If AEACN = "NO_CHANGE" then AEACN = "DOSE NOT CHANGED";
      if AEACN = "WITHDRAWN" then AEACN = "DRUG WITHDRAWN";
      if AEACN = "NA"        then AEACN = "NOT APPLICABLE";

      if not missing (AEACTOTH) and upcase(AEACTOTH) = "X" then AEACNOTH  =  upcase(AEACTSPE);

          if AEREL = "UNLIKELY"   then AEREL = "UNLIKELY RELATED";
          if AEREL = "POSSIBLY"   then AEREL = "POSSIBLY RELATED";
          if AEREL = "NOTRELATED" then AEREL = "NOT RELATED";
          if AEREL = "DEFINITELY" then AEREL = "DEFINITELY RELATED";
          if AEREL = "PROBABLY"   then AEREL = "PROBABLY RELATED";

            IF AEOUT =  "RECOVERED"           THEN AEOUT =  "RECOVERED/RESOLVED";
            IF AEOUT =  "NOTREC"           THEN AEOUT =  "NOT RECOVERED/NOT RESOLVED";
            
               if not missing (AECONG) then AESCONG = "Y" ; else AESCONG = " " ;
               if not missing (AEDISAB) then AESDISAB = "Y" ; else AESDISAB = " " ;
               if not missing (AEDTH) then AESDTH = "Y" ; else AESDTH = " " ;
               if not missing (AEHOSP) then AESHOSP = "Y" ; else AESHOSP = " " ;
               if not missing (AELIFE) then AESLIFE = "Y" ; else AESLIFE = " " ;
               if not missing (AESMIE) then AESMIE = "Y" ; else AESMIE = " " ;

   IF NOT MISSING (AESTDAT) AND not missing (AESTTIM) and AESTTIM NOT IN ("00:UU","00:00","UU:00","U") then 
      AESTDTC  =  STRIP (AESTDAT) || "T" || STRIP (AESTTIM);
   IF NOT MISSING (AESTDAT) AND MISSING (AESTTIM) THEN AESTDTC     =  STRIP (AESTDAT);
   IF NOT MISSING (AESTDAT) AND AESTTIM IN ("00:UU","00:00","UU:00","U") THEN AESTDTC     =  STRIP (AESTDAT);

   IF NOT MISSING (AEENDAT) AND not missing (AEENTIM) and AEENTIM NOT IN ("00:UU","00:00","UU:00","U") then 
      AEENDTC  =  STRIP (AEENDAT) || "T" || STRIP (AEENTIM);
   IF NOT MISSING (AEENDAT) AND MISSING (AEENTIM) THEN AEENDTC     =  STRIP (AEENDAT);
   IF NOT MISSING (AEENDAT) AND AEENTIM  IN ("00:UU","00:00","UU:00","U")THEN
      AEENDTC     =  STRIP (AEENDAT);

   drop aestdat aesttim aeendat aeentim;
run;

*EPOCH;;
PROC SORT DATA=ae1;
   BY USUBJID;
RUN;

*EPOCH;;
DATA ae3;
   LENGTH epoch $200 domain $2;
   MERGE sdtm.se(WHERE=(taetord=1) RENAME=(sestdtc=scrnst seendtc=scrnend) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=2) RENAME=(sestdtc=cycle1st seendtc=cycle1end) KEEP=usubjid taetord sestdtc seendtc)
        sdtm.se(WHERE=(taetord=3) RENAME=(sestdtc=ltfupst seendtc=ltfupend) KEEP=usubjid taetord sestdtc seendtc)
        ae1(in=a);
   BY usubjid;
   IF a;
   IF ltfupst^='' & substr(ltfupst,1,10)<=aeSTDTC<=SUBSTR(ltfupend,1,10) THEN EPOCH='FOLLOW-UP';
      ELSE IF cycle1st^='' & substr(cycle1st,1,10)<=aeSTDTC<=SUBSTR(cycle1end,1,10) THEN EPOCH='TREATMENT';
      ELSE IF scrnst^='' & SUBSTR(scrnst,1,10)<=aeSTDTC<=SUBSTR(scrnend,1,10) THEN EPOCH='SCREENING';
RUN;


*AESTDY ;
proc sort data=sdtm.dm out=dm1 nodupkey;by usubjid;run;
DATA DM1;
   SET dm1;
   RFSTDTC_N = DATEPART (INPUT (RFSTDTC,??IS8601DT.));

   FORMAT RFSTDTC_N YYMMDD10.;
   KEEP USUBJID RFSTDTC_N;
RUN;

DATA ae4;
   MERGE ae3(in=a)  DM1(IN=b KEEP=USUBJID  RFSTDTC_N );
   BY USUBJID;
   IF a & b;   
   aeSTDTC_N = INPUT (aeSTDTC,??YYMMDD10.);
    aeENDTC_N = INPUT (aeENDTC,??YYMMDD10.);

   IF aeSTDTC_N NE . AND RFSTDTC_N NE . THEN DO;
      IF aeSTDTC_N >= RFSTDTC_N THEN aeSTDY= aeSTDTC_N - RFSTDTC_N +1;
      ELSE IF aeSTDTC_N < RFSTDTC_N THEN aeSTDY = aeSTDTC_N - RFSTDTC_N;
   END;

   IF aeENDTC_N NE . AND RFSTDTC_N NE . THEN DO;
      IF aeENDTC_N >= RFSTDTC_N THEN aeENDY= aeENDTC_N - RFSTDTC_N +1;
      ELSE IF aeENDTC_N < RFSTDTC_N THEN aeENDY = aeENDTC_N - RFSTDTC_N;
   END;
RUN;

/* */

*SEQ;;
PROC SORT DATA=ae4 out=ae5;
   BY USUBJID AESTDTC AEENDTC AETERM;
RUN;

DATA ae6;
   SET ae5;
   BY USUBJID AESTDTC AEENDTC AETERM;
   IF first.usubjid THEN aeSEQ=1;
      ELSE aeSEQ+1;
keep
STUDYID
DOMAIN
USUBJID
AESEQ
AETERM
AELLT
AELLTCD
AEDECOD
AEPTCD
AEHLT
AEHLTCD
AEHLGT
AEHLGTCD
AEBODSYS
AEBDSYCD
AESOC
AESOCCD
AESEV
AESER
AEACN
AEACNOTH
AEREL
AEOUT
AESCONG
AESDISAB
AESDTH
AESHOSP
AESLIFE
AESMIE
EPOCH
AESTDTC
AEENDTC
AESTDY
AEENDY
;
run;

data ae(LABEL='Adverse Event'); set ae6; run;
      


