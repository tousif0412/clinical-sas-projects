
/* Step 1: Import LB Raw Data */

proc import datafile="//home/u63981529/LB_sdtm/raw_lb.csv"
    out=lb_raw dbms=csv replace;
    getnames=yes;
run;


/* Step 2: Create LB Dataset */

data lb;
    set lb_raw;
    length STUDYID $10 DOMAIN $2 USUBJID $20 LBTEST $40 LBORRESU $15;
    STUDYID = "XYZ123";
    DOMAIN = "LB";
    USUBJID = catx("-", STUDYID, SUBJID);
    retain LBSEQ;
    by SUBJID notsorted;
    if first.SUBJID then LBSEQ = 1;
    else LBSEQ + 1;

    keep STUDYID DOMAIN USUBJID LBSEQ LBTEST LBORRES LBORRESU LBDTC;
run;

/* View observations */
proc print data=lb (obs=10); run;



/* Step 3: Save Final DM Dataset to Output Folder */

libname Output'/home/u63981529/LB_sdtm/Output';
run;

Data Output.LB ;
Set lb;
run;

/*  Step 4: Export DM to CSV */

proc export data=Output.LB
    outfile="/home/u63981529/LB_sdtm/Output/LB_final.csv"
    dbms=csv
    replace;
run;
