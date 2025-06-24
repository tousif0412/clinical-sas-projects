/* Step 1: Import AE Raw Data */
proc import datafile="/home/u63981529/AE_SDTM/AE_RAW.xlsx"
    out=ae_raw dbms=xlsx replace;
    sheet="Sheet1";
    getnames=yes;
run;

/* Step 2: Create SDTM AE Dataset */
data ae_sdtm;
    set ae_raw;
    
    /* Static values */
    STUDYID = "XYZ123";
    DOMAIN = "AE";

    /* Sequence number */
    retain AESEQ 0;
    by USUBJID;
    if first.USUBJID then AESEQ = 1;
    else AESEQ + 1;

    /* SDTM variables */
    AETERM   = strip(AETERM);
    AEDECOD  = propcase(strip(AEDECOD));
    AESEV    = upcase(AESEV);
    AESER    = upcase(AESER);
    AEREL    = upcase(AEREL);
    AEOUT    = upcase(AEOUT);
    AEACN    = upcase(AEACN);

    /* Convert dates to ISO format */
    format AESTDTC AEENDTC yymmdd10.;
    AESTDTC = input(strip(AESTDTC), yymmdd10.);
    AEENDTC = input(strip(AEENDTC), yymmdd10.);
run;

/* Step 3: Sort the SDTM dataset */
proc sort data=ae_sdtm;
    by USUBJID AESEQ;
run;

/* Step 4: Export Final SDTM Dataset */
proc export data=ae_sdtm
    outfile="/home/u63981529/AE_SDTM/Output"
    dbms=xlsx replace;
    sheet="AE";
run;
