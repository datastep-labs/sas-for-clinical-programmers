/* Chapter 9: ADSL as a chain of numbered steps, each step adds one variable */

/* The tool every step calls */
/*******************************************************************************
  Macro       : %m_merge
  Version     : 2.0
  Purpose     : Merge two data sets by a key and write one build-log line:
                the rows of OUT= and the variables that ADD= brought.
  Parameters  :
    data=     the data set to add to, e.g. adsl_030 (data set options allowed)
    add=      the data set with the new variables, e.g. ex_trtedt
    by=       the key, default usubjid
    join=     LEFT (default): every row of DATA=; INNER: rows in both;
              RIGHT: every row of ADD=; FULL: every row of both
    out=      the output data set, e.g. adsl_031
  Examples    :
    %m_merge(data=adsl_020, add=ex_trtsdt, out=adsl_030)
    %m_merge(data=adsl_031, add=supp_flags(KEEP=usubjid saffl), out=adsl_040)
  Change log  :
    2026-11-02  1.0  first version, with three checks
    2026-11-02  2.0  simpler, like a production merge utility: no checks
*******************************************************************************/
%MACRO m_merge(data=, add=, by=usubjid, join=LEFT, out=) / DES='Merge two data sets by a key';
  %LOCAL dsid1 dsid2 rc i v new n;

  /* Step 010: sorted copies, so the macro never sorts your data sets */
  PROC SORT DATA=&data. OUT=_mme_010;
    BY &by.;
  RUN;
  PROC SORT DATA=&add. OUT=_mme_020;
    BY &by.;
  RUN;

  /* Step 020: the join */
  DATA &out.;
    MERGE _mme_010(IN=_mme_a) _mme_020(IN=_mme_b);
    BY &by.;
    %IF %UPCASE(&join.) = LEFT  %THEN IF _mme_a;;
    %IF %UPCASE(&join.) = RIGHT %THEN IF _mme_b;;
    %IF %UPCASE(&join.) = INNER %THEN IF _mme_a AND _mme_b;;
  RUN;

  /* The build log: the rows of OUT= and the variables that only ADD= has */
  %LET dsid1 = %SYSFUNC(OPEN(_mme_010));
  %LET dsid2 = %SYSFUNC(OPEN(_mme_020));
  %LET new = ;
  %DO i = 1 %TO %SYSFUNC(ATTRN(&dsid2., NVARS));
    %LET v = %UPCASE(%SYSFUNC(VARNAME(&dsid2., &i.)));
    %IF %SYSFUNC(VARNUM(&dsid1., &v.)) = 0 %THEN %LET new = &new. &v.;
  %END;
  %LET rc = %SYSFUNC(CLOSE(&dsid1.));
  %LET rc = %SYSFUNC(CLOSE(&dsid2.));
  %LET dsid1 = %SYSFUNC(OPEN(&out.));
  %LET n = %SYSFUNC(ATTRN(&dsid1., NLOBS));
  %LET rc = %SYSFUNC(CLOSE(&dsid1.));
  %IF %SYSFUNC(COUNTW(&new., %STR( ))) = 1 %THEN
    %PUT NOTE: [M_MERGE] &out.: &n. rows, +1 variable: &new.;
  %ELSE
    %PUT NOTE: [M_MERGE] &out.: &n. rows, +%SYSFUNC(COUNTW(&new., %STR( ))) variables: &new.;

  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _mme_:;
  RUN; QUIT;
%MEND m_merge;

/* Step 010: the base, one record per randomised subject, from DM */
DATA adsl_010;
  SET sdtm.dm(KEEP=studyid usubjid subjid siteid arm armcd age ageu sex race ethnic rfstdtc rfendtc);
  WHERE armcd NE "Scrnfail";
RUN;

/* Step 020: planned and actual treatment, text and number. They come from ARM, */
/* which ADSL already has: a value made from ADSL itself is a DATA step         */
DATA adsl_020;
  LENGTH trt01p trt01a $20;
  SET adsl_010;
  trt01p = arm;
  IF      arm = "Placebo"              THEN trt01pn = 0;
  ELSE IF arm = "Xanomeline Low Dose"  THEN trt01pn = 54;
  ELSE IF arm = "Xanomeline High Dose" THEN trt01pn = 81;
  trt01a  = trt01p;
  trt01an = trt01pn;
RUN;

/* Step 030: TRTSDT, the date of the first dose, from EX */
DATA ex_dt;
  SET sdtm.ex(KEEP=usubjid exstdtc exendtc);
  exstdt = INPUT(exstdtc, ?? E8601DA.);
  exendt = INPUT(exendtc, ?? E8601DA.);
RUN;

PROC MEANS DATA=ex_dt NOPRINT NWAY;
  CLASS usubjid;
  VAR exstdt;
  FORMAT exstdt DATE9.;
  OUTPUT OUT=ex_trtsdt(KEEP=usubjid trtsdt) MIN=trtsdt;
RUN;

%m_merge(data=adsl_020, add=ex_trtsdt, out=adsl_030)

/* Step 031: TRTEDT, the date of the last dose: the latest EX end date.       */
/* An EX record without an end date means: still dosed when the subject left, */
/* so the treatment ends at RFENDTC. The rule needs RFENDTC, an ADSL variable: */
/* the merge goes the other way, ADSL into the source data set                 */
PROC MEANS DATA=ex_dt NOPRINT NWAY;
  CLASS usubjid;
  VAR exendt;
  OUTPUT OUT=ex_last(KEEP=usubjid exlast n_open) MAX=exlast NMISS=n_open;
RUN;

%m_merge(data=ex_last, add=adsl_030(KEEP=usubjid rfendtc), out=ex_last_rf)

DATA ex_trtedt(KEEP=usubjid trtedt);
  SET ex_last_rf;
  IF n_open > 0 THEN trtedt = INPUT(rfendtc, ?? E8601DA.);
  ELSE               trtedt = exlast;
  FORMAT trtedt DATE9.;
RUN;

%m_merge(data=adsl_030, add=ex_trtedt, out=adsl_031)

/* Step 040: population flags from SUPPDM, one flag per step.     */
/* SUPPDM has a record only for Y, so every ADSL subject needs a */
/* flag: start from the subjects of ADSL, N when no record       */
PROC TRANSPOSE DATA=sdtm.suppdm OUT=supp(DROP=_name_ _label_);
  BY usubjid;
  ID qnam;
  VAR qval;
RUN;

%m_merge(data=adsl_031(KEEP=usubjid), add=supp(KEEP=usubjid safety itt efficacy complt24), out=supp_031)

DATA supp_flags(KEEP=usubjid saffl ittfl efffl comp24fl);
  LENGTH saffl ittfl efffl comp24fl $1;
  SET supp_031;
  IF safety   = "Y" THEN saffl    = "Y";
  ELSE                   saffl    = "N";
  IF itt      = "Y" THEN ittfl    = "Y";
  ELSE                   ittfl    = "N";
  IF efficacy = "Y" THEN efffl    = "Y";
  ELSE                   efffl    = "N";
  IF complt24 = "Y" THEN comp24fl = "Y";
  ELSE                   comp24fl = "N";
RUN;

%m_merge(data=adsl_031, add=supp_flags(KEEP=usubjid saffl),    out=adsl_040)
%m_merge(data=adsl_040, add=supp_flags(KEEP=usubjid ittfl),    out=adsl_041)
%m_merge(data=adsl_041, add=supp_flags(KEEP=usubjid efffl),    out=adsl_042)
%m_merge(data=adsl_042, add=supp_flags(KEEP=usubjid comp24fl), out=adsl_043)

/* Step 050: height and weight at baseline, from VS.                  */
/* Height is measured once, at screening; weight has a baseline flag */
PROC MEANS DATA=sdtm.vs(WHERE=(vstestcd = "HEIGHT")) NOPRINT NWAY;
  CLASS usubjid;
  VAR vsstresn;
  OUTPUT OUT=vs_heightbl(KEEP=usubjid heightbl) MAX=heightbl;
RUN;
PROC MEANS DATA=sdtm.vs(WHERE=(vstestcd = "WEIGHT" AND vsblfl = "Y")) NOPRINT NWAY;
  CLASS usubjid;
  VAR vsstresn;
  OUTPUT OUT=vs_weightbl(KEEP=usubjid weightbl) MAX=weightbl;
RUN;

%m_merge(data=adsl_043, add=vs_heightbl, out=adsl_050)
%m_merge(data=adsl_050, add=vs_weightbl, out=adsl_051)

/* Step 060: age group, rounding and BMI come from ADSL itself: a DATA step, */
/* and the attributes of the specification                                   */
DATA adsl;
  ATTRIB trt01p   LENGTH=$20 LABEL="Planned Treatment for Period 01"
         trt01pn             LABEL="Planned Treatment for Period 01 (N)"
         trt01a   LENGTH=$20 LABEL="Actual Treatment for Period 01"
         trtsdt              LABEL="Date of First Exposure to Treatment" FORMAT=DATE9.
         trtedt              LABEL="Date of Last Exposure to Treatment"  FORMAT=DATE9.
         agegr1   LENGTH=$5  LABEL="Pooled Age Group 1"
         saffl    LENGTH=$1  LABEL="Safety Population Flag"
         ittfl    LENGTH=$1  LABEL="Intent-To-Treat Population Flag"
         efffl    LENGTH=$1  LABEL="Efficacy Population Flag"
         comp24fl LENGTH=$1  LABEL="Completers of Week 24 Population Flag"
         heightbl            LABEL="Baseline Height (cm)"
         weightbl            LABEL="Baseline Weight (kg)"
         bmibl               LABEL="Baseline BMI (kg/m^2)";
  SET adsl_051;
  IF      age < 65 THEN agegr1 = "<65";
  ELSE IF age > 80 THEN agegr1 = ">80";
  ELSE                  agegr1 = "65-80";
  /* the specification keeps one decimal */
  IF NOT MISSING(weightbl) THEN weightbl = ROUND(weightbl, 0.1);
  IF NOT MISSING(heightbl) THEN heightbl = ROUND(heightbl, 0.1);
  IF NOT MISSING(weightbl) AND NOT MISSING(heightbl) THEN bmibl = ROUND(weightbl / (heightbl / 100)**2, 0.1);
RUN;
