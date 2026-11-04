/* Chapter 13: the AE overview as study macros: one macro for one row, one for the list (needs the macros of 13_3) */

PROC FORMAT;
  VALUE trtf 0 = "Placebo" 54 = "Xanomeline Low Dose" 81 = "Xanomeline High Dose";
RUN;

/*******************************************************************************
  Macro       : %m_ae_row
  Version     : 1.0
  Purpose     : One row of an AE overview: per treatment, the subjects of the safety
                population with at least one TEAE that meets a condition.
  Parameters  :
    label=      the text of the row (required)
    cond=       a condition on ADAE, for example aeser = "Y" (default 1: every TEAE)
    sub=        the position of the row in the table (required)
    adae=       the ADAE data set (default refadm.adae)
    out=        one record per treatment: sub label col n (required)
  Examples    :
    %m_ae_row(label=Subjects with a serious TEAE, cond=aeser = "Y", sub=3, out=row3)
  Change log  :
    2026-11-02  1.0  first version
*******************************************************************************/
%MACRO m_ae_row(label=, cond=1, sub=, adae=refadm.adae, out=);
  %IF %m_need(macro=M_AE_ROW, params=label cond sub adae out) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&adae.)) %THEN %DO;
    %PUT %STR(ERR)OR: [M_AE_ROW] The data set &adae. does not exist.;
    %RETURN;
  %END;

  /* the subjects with such an event, one record each, then the count per treatment */
  PROC SORT DATA=&adae.(WHERE=(saffl = "Y" AND trtemfl = "Y" AND (&cond.)))
            OUT=_mar_010(KEEP=trtan usubjid) NODUPKEY;
    BY trtan usubjid;
  RUN;
  PROC FREQ DATA=_mar_010 NOPRINT;
    TABLES trtan / OUT=_mar_020;
  RUN;
  DATA &out.(KEEP=sub label col n);
    LENGTH label $60;
    SET _mar_020;
    sub   = &sub.;
    label = "&label.";
    col   = trtan;
    n     = count;
  RUN;
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mar_:; RUN; QUIT;
%MEND m_ae_row;

/*******************************************************************************
  Macro       : %m_ae_overview
  Version     : 1.0
  Purpose     : An AE overview from a list of rows. Each row of the list is
                "label | condition"; the rows are separated by #.
  Parameters  :
    list=       the rows (required)
    denom=      the big N data set from %m_bign (variables col and bign) (required)
    adae=       the ADAE data set (default refadm.adae)
    out=        the rows in the layout of %m_report: col ord sub label value (required)
    debug=      Y keeps the work data sets _mao_ (default N)
  Examples    :
    %LET rows = Subjects with at least one TEAE | 1
              # Subjects with a serious TEAE    | aeser = "Y";
    %m_ae_overview(list=&rows., denom=ia_bign, out=ae_over)
  Change log  :
    2026-11-02  1.0  first version
*******************************************************************************/
%MACRO m_ae_overview(list=, denom=, adae=refadm.adae, out=, debug=N);
  %LOCAL macro mversion t0 i n item label cond;
  %LET macro    = %UPCASE(&SYSMACRONAME.);
  %LET mversion = 1.0;
  %LET t0       = %SYSFUNC(DATETIME());
  %IF %m_need(macro=&macro., params=list denom adae out debug) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&denom.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] The big N data set &denom. does not exist.;
    %RETURN;
  %END;
  %PUT NOTE: [&macro.] Version &mversion. started.;

  /* Step 010: one call of %m_ae_row per row of the list */
  %LET n = %SYSFUNC(COUNTW(%SUPERQ(list), #));
  %DO i = 1 %TO &n.;
    %LET item  = %QSCAN(%SUPERQ(list), &i., #);
    %LET label = %QSYSFUNC(STRIP(%QSCAN(&item., 1, |)));
    %LET cond  = %QSYSFUNC(STRIP(%QSCAN(&item., 2, |)));
    %m_ae_row(label=%UNQUOTE(&label.), cond=%UNQUOTE(&cond.), sub=&i., adae=&adae., out=_mao_r&i.)
  %END;
  DATA _mao_010;
    SET _mao_r1-_mao_r&n.;
  RUN;

  /* Step 020: every row in every column: each row once with each column of the big N */
  PROC SORT DATA=_mao_010 OUT=_mao_020(KEEP=sub label) NODUPKEY;
    BY sub;
  RUN;
  DATA _mao_030;
    SET _mao_020;
    DO i = 1 TO ncol;
      SET &denom.(KEEP=col bign) POINT=i NOBS=ncol;
      OUTPUT;
    END;
    DROP i;
  RUN;

  /* Step 030: the count of each cell, 0 where nobody had such an event, and its text */
  PROC SORT DATA=_mao_010; BY sub col; RUN;
  DATA &out.(KEEP=ord sub label col value);
    LENGTH value $20;
    MERGE _mao_030 _mao_010(KEEP=sub col n);
    BY sub col;
    ord = 1;
    IF MISSING(n) THEN value = "0";
    ELSE value = CATX(" ", PUT(n, 4.), CATS("(", PUT(n / bign * 100, 5.1), ")"));
  RUN;

  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mao_:; RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] &n. rows ended after %SYSEVALF(%SYSFUNC(DATETIME()) - &t0., CEIL) seconds.;
%MEND m_ae_overview;

/* The rows of the table: label | condition, one line per row */
%LET overview =
    Subjects with at least one TEAE           | 1
  # Subjects with a related TEAE              | aerel IN ("POSSIBLE" "PROBABLE")
  # Subjects with a serious TEAE              | aeser = "Y"
  # Subjects with a severe TEAE               | aesev = "SEVERE"
  # Subjects with a TEAE that led to death    | aesdth = "Y"
;

%m_bign(data=refadm.adsl, by=trt01an, where=saffl = "Y", out=ov_bign2)
%m_ae_overview(list=&overview., denom=ov_bign2, out=ae_over)

OPTIONS LS=132 PS=60 NOCENTER;
TITLE1 "Table 14.3.0 Overview of treatment emergent adverse events (safety population)";
%m_report(data=ae_over, denom=ov_bign2, fmt=trtf., lwidth=40)
TITLE;
