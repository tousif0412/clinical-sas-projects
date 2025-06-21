/* -----------------------------------------------------------------------
   Author       : Tousif Tamboli
   Project      : SDTM DM Domain Derivation
   Purpose      : To derive SDTM-compliant DM dataset from raw clinical data
   ----------------------------------------------------------------------- */

/* Step 1: Assign Library Reference for Raw Data */
libname Raw_data '/home/u63981529/SDTM-DM/Raw_data';
run;

/* Step 2: Import Required Raw Datasets from Excel */
%macro import_excel(file=, out=);
    proc import 
        datafile="&file"
        out=Raw_data.&out
        dbms=xlsx
        replace;
    run;
%mend;


%macro import_all;
    %let path = /home/u63981529/SDTM-DM/Data - CDM;

    %import_excel(file=&path./DM.xlsx,        out=DM);
    %import_excel(file=&path./DEATH.xlsx,     out=DEATH);
    %import_excel(file=&path./DS.xlsx,        out=DS);
    %import_excel(file=&path./EX.xlsx,        out=EX);
    %import_excel(file=&path./IE.xlsx,        out=IE);
    %import_excel(file=&path./SPCPKB1.xlsx,   out=SPCPKB1);
    %import_excel(file=&path./TA.xlsx,        out=TA);
%mend;

%import_all;


/* Step 3: Create Study Identifiers and Core DM Variables */
data DM1;
    set raw_data.DM;
run;

data DM2;
    set DM1;
    STUDYID = "XYZ";
    DOMAIN = "DM";
    USUBJID = strip(STUDYID) || "/" || strip(put(SUBJECT, best.));
    SUBJID = SUBJECT;
run;

/* Step 4: RFSTDTC (Reference Start Date) from SPCPKB1 */
data SPCPKB1;
    set raw_data.SPCPKB1;
    where IPFD1DAT ne " " and PSCHDAY = 1 and PART = "A";
    RFSTDTC = IPFD1DAT || "T" || IPFD1TIM;
run;

/* Step 5: RFENDTC (Reference End Date) from EX Dataset */
data EX;
    set raw_data.EX;
    if EXENDAT ne " " or EXSTDAT ne " ";
run;

proc sort data=EX; 
    by SUBJECT EXSTDAT EXENDAT;
run;

data EX1;
    set EX;
    by SUBJECT EXSTDAT EXENDAT;
    if last.SUBJECT;
run;

/* Step 6: Merge All Required Data */
data DM2;
    merge DM1(in=a) 
          SPCPKB1 
          EX1 
          Raw_data.DS 
          Raw_data.DEATH(where=(DTHDESIG = "1")) 
          Raw_data.IE(where=(IEYN = "0"));
    by SUBJECT;
    if a;
run;

/* Step 7: Key SDTM Variables (RFSTDTC, RFENDTC, etc.) */
data DM3 (rename=(ETHNIC1=ETHNIC));
    length ETHNIC1 $60;
    set DM2;

    if EXENDAT ne "" then RFENDTC = EXENDAT;
    else if EXENDAT = "" then RFENDTC = EXSTDAT;
    else RFENDTC = IPFD1DAT || "T" || IPFD1TIM;

    RFXSTDTC = RFSTDTC;
    RFXENDTC = RFENDTC;
    RFPENDTC = DSSTDAT;
    DTHDTC   = DTH_DAT;
    SITEID   = CENTRE;
    BRTHDTC  = BRTHDAT;
    AGEU     = "YEARS";

    /* Death flag */
    if DTHDTC ne " " then DTHFL = "Y";

    /* Decode controlled terminology */
    if SEX='C20197' then SEX = "M";
    else if SEX='C16576' then SEX = "F";
    else SEX = "U";

    if RACE = 'C41260' then RACE = 'ASIAN';
    if RACE = 'C41261' then RACE = 'WHITE';
    if ETHNIC = 'C41222' then ETHNIC1 = 'NOT HISPANIC OR LATINO';

    /* Treatment Arm Assignment */
    if RFSTDTC ne " " then ARMCD = "A01-A02-A03";
    else if IEYN = "0" and RFSTDTC = " " then ARMCD = "SCRNFAIL";
    else ARMCD = "NOTASSGN";

    drop ETHNIC;
run;

proc sort data=DM3;
    by ARMCD;
run;

/* Step 8: Merge Treatment Arm Descriptions from TA */
data TA;
    set raw_data.TA(keep=ARMCD ARM);
run;

proc sort data=TA nodupkey;
    by ARMCD;
run;

data DM4;
    merge DM3(in=a) TA;
    by ARMCD;
    if a;
    if ARMCD = "SCRNFAIL" then ARM = "Screen Failure";
    if ARMCD = "NOTASSGN" then ARM = "Not Assigned";
run;

/* Step 9: Add Actual Arm Variables and Country Derivation */
data DM5;
    set DM4;
    ACTARMCD = ARMCD;
    ACTARM   = ARM;

    CO = put(CENTRE,6.);
    if substr(strip(CO),1,2) = "23" then COUNTRY = "FRA";
    else if substr(strip(CO),1,2) = "70" then COUNTRY = "ESP";
    else if substr(strip(CO),1,2) = "60" then COUNTRY = "KOR";

    DMDTC     = VIS_DAT;
    RACEOTH   = upcase(RACEOTH);
    VISITDTC  = VIS_DAT;
run;

/* Step 10: Assign Variable Labels and Final Formatting */
data DM6;
    length STUDYID $21 DOMAIN $8 USUBJID $30 SUBJID 8 
           RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFPENDTC DTHDTC $19 
           DTHFL $1 SITEID 5 BRTHDTC $19 AGE 8 AGEU $10 
           SEX $1 RACE $60 ETHNIC $60 ARMCD ARM ACTARMCD ACTARM $200 
           COUNTRY $3 DMDTC $19 CENTRE 8 PART $1 RACEOTH $200 VISITDTC $19;

    set DM5(rename=(SEX=SEX1 SITEID=SITEID1));

    label STUDYID  = "Study Identifier"
          DOMAIN   = "Domain Abbreviation"
          USUBJID  = "Unique Subject Identifier"
          SUBJID   = "Subject Identifier for the Study"
          RFSTDTC  = "Subject Reference Start Date/Time"
          RFENDTC  = "Subject Reference End Date/Time"
          RFXSTDTC = "Date/Time of First Study Treatment"
          RFXENDTC = "Date/Time of Last Study Treatment"
          RFPENDTC = "Date/Time of End of Participation"
          DTHDTC   = "Date/Time of Death"
          DTHFL    = "Subject Death Flag"
          SITEID   = "Study Site Identifier"
          BRTHDTC  = "Date/Time of Birth"
          AGE      = "Age"
          AGEU     = "Age Units"
          SEX      = "Sex"
          RACE     = "Race"
          ETHNIC   = "Ethnicity"
          ARMCD    = "Planned Arm Code"
          ARM      = "Description of Planned Arm"
          ACTARMCD = "Actual Arm Code"
          ACTARM   = "Description of Actual Arm"
          COUNTRY  = "Country"
          DMDTC    = "Date/Time of Collection"
          CENTRE   = "Centre Number"
          PART     = "Study Part Code"
          RACEOTH  = "Other Race Specification"
          VISITDTC = "Date of Visit";

    SEX    = SEX1;
    SITEID = SITEID1;

    keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFPENDTC 
         DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM ACTARMCD 
         ACTARM COUNTRY DMDTC CENTRE PART RACEOTH VISITDTC;
run;

/* Step 11: Save Final DM Dataset to Output Folder */
libname Output '/home/u63981529/SDTM-DM/Outputs';
run;

data Output.DM;
    set DM6;
run;

proc sort data=Output.DM;
    by USUBJID;
run;
