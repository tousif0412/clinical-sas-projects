

/* Step 1: Import EX Raw Data */

proc import datafile="/home/u63981529/Ex_Sdtm/raw_ex_105.csv"
    out=ex_raw dbms=csv replace;
    getnames=yes;
run;

/* Step 2: Create EX Dataset */
data ex;
    set ex_raw;

    length STUDYID $10 DOMAIN $2 USUBJID $20 EXTRT $20 EXDOSU $10 EXROUTE $10 EXFREQ $10 EXSTDTC EXENDTC $10;
    
    STUDYID = "XYZ123";
    DOMAIN = "EX";
    USUBJID = catx("-", STUDYID, SUBJID);
    EXSEQ = _N_;
    EXTRT = DRUGNAME;
    EXDOSE = DOSAMT;
    EXDOSU = DOSU;
    EXROUTE = ROUTE;
    EXFREQ = FREQ;
    EXSTDTC = DOSDT;
    EXENDTC = DOSENDT;

    keep STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXROUTE EXFREQ EXSTDTC EXENDTC;
run;

/* View output */

proc print data=ex (obs=10); run;


/* Step 11: Save Final DM Dataset to Output Folder */

libname Output'/home/u63981529/Ex_Sdtm/Output';
run;

Data Output.EX ;
Set ex ;
run;

/* Export DM to CSV */

proc export data=Output.EX
    outfile="/home/u63981529/Ex_Sdtm/Output/EX_final.csv"
    dbms=csv
    replace;
run;
