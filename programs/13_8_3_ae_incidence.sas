/* Chapter 13: the AE table of 13.3 as a study macro, %m_incidence_ae (needs the macros of 13_3 and AE_TEXT from 13_2) */

PROC FORMAT;
  VALUE trtf 0 = "Placebo" 54 = "Xanomeline Low Dose" 81 = "Xanomeline High Dose";
RUN;

/*******************************************************************************
  Macro       : %m_incidence_ae
  Version     : 1.0
  Purpose     : The incidence of treatment emergent AEs by system organ class (SOC)
                and preferred term (PT): subjects, not records; n (%) of the safety
                population; 0 in the empty cells. Each call adds only its subset.
  Parameters  :
    where=      an extra condition on ADAE (default 1: every TEAE)
    title=      the table title (required)
    sort=       TOTAL: SOCs and PTs by descending number of subjects over all arms;
                a treatment value (for example 81): by descending number in that arm.
                Equal numbers go in alphabetical order. (default TOTAL)
    adsl=       the ADSL data set (default refadm.adsl)
    adae=       the ADAE data set (default refadm.adae)
    fmt=        the format of the treatment value, for the column headers (default trtf.)
    out=        the rows: col ord sub label value, with level aebodsys aedecod (required)
    print=      Y prints the table with %m_report (default Y)
    debug=      Y keeps the work data sets _mia_ (default N)
  Examples    :
    %m_incidence_ae(title=Table 14.3.1 TEAEs, out=ia_all)
    %m_incidence_ae(where=aeser = "Y", title=Table 14.3.2 Serious TEAEs, out=ia_ser)
  Preconditions : the macros of 13_3_table_macros.sas exist.
  Postconditions: &out. holds one record per line of the table and treatment.
  Change log  :
    2026-11-02  1.0  first version
*******************************************************************************/
%MACRO m_incidence_ae(where=1, title=, sort=TOTAL, adsl=refadm.adsl, adae=refadm.adae,
                      fmt=trtf., out=, print=Y, debug=N);
  %LOCAL macro mversion t0 nteae;
  %LET macro    = %UPCASE(&SYSMACRONAME.);
  %LET mversion = 1.0;
  %LET t0       = %SYSFUNC(DATETIME());
  %IF %m_need(macro=&macro., params=title sort adsl adae fmt out print debug) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&adae.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] The data set &adae. does not exist.;
    %RETURN;
  %END;
  %PUT NOTE: [&macro.] Version &mversion. started with where=%SUPERQ(where);

  /* Step 010: the big N of the safety population, one column per treatment */
  %m_bign(data=&adsl., by=trt01an, where=saffl = "Y", out=_mia_bign)

  /* Step 020: the treatment emergent events of the safety population, and the subset */
  DATA _mia_020;
    SET &adae.(WHERE=(saffl = "Y" AND trtemfl = "Y" AND (&where.)));
    KEEP usubjid trtan aebodsys aedecod;
  RUN;
  %LET nteae = 0;
  DATA _NULL_;
    IF 0 THEN SET _mia_020 NOBS=nobs;
    CALL SYMPUTX("nteae", nobs, "L");
    STOP;
  RUN;
  %IF &nteae. = 0 %THEN %PUT NOTE: [&macro.] No event meets the condition: the table has only the first line.;

  /* Step 030: count subjects, not records. Each event counts for three lines: */
  /* the overall line, its SOC and its SOC with PT. One record per subject and line */
  DATA _mia_030;
    LENGTH aebodsys aedecod $200;
    SET _mia_020;
    col   = trtan;
    level = 2;                    OUTPUT;
    level = 1; aedecod  = " ";    OUTPUT;
    level = 0; aebodsys = " ";    OUTPUT;
    KEEP level aebodsys aedecod col usubjid;
  RUN;
  PROC SORT DATA=_mia_030 NODUPKEY;
    BY level aebodsys aedecod col usubjid;
  RUN;
  PROC FREQ DATA=_mia_030 NOPRINT;
    TABLES level * aebodsys * aedecod * col / LIST MISSING
           OUT=_mia_031(KEEP=level aebodsys aedecod col count RENAME=(count=n));
  RUN;

  /* Step 040: the sort key of each line: subjects over all arms, or subjects in one arm */
  /* (a subject is in one arm only, so the sum over the arms counts each subject once)  */
  DATA _mia_040;
    SET _mia_031(WHERE=(level > 0));
    %IF %UPCASE(&sort.) = TOTAL %THEN %DO; key = n; %END;
    %ELSE %DO; key = n * (col = &sort.); %END;
  RUN;
  PROC MEANS DATA=_mia_040 NOPRINT NWAY MISSING;
    CLASS level aebodsys aedecod;
    VAR key;
    OUTPUT OUT=_mia_040(KEEP=level aebodsys aedecod key) SUM=key;
  RUN;

  /* the rank of each SOC (ord) and of each PT inside its SOC (sub): most subjects first */
  PROC SORT DATA=_mia_040(WHERE=(level = 1)) OUT=_mia_041; BY DESCENDING key aebodsys; RUN;
  DATA _mia_041;
    SET _mia_041;
    ord = _N_;
    KEEP aebodsys ord;
  RUN;
  PROC SORT DATA=_mia_040(WHERE=(level = 2)) OUT=_mia_042; BY aebodsys DESCENDING key aedecod; RUN;
  DATA _mia_042;
    SET _mia_042;
    BY aebodsys;
    IF FIRST.aebodsys THEN sub = 0;
    sub + 1;
    KEEP aebodsys aedecod sub;
  RUN;

  /* Step 050: every line once with each column of the big N */
  PROC SORT DATA=_mia_031 OUT=_mia_050(KEEP=level aebodsys aedecod) NODUPKEY;
    BY level aebodsys aedecod;
  RUN;
  DATA _mia_051;
    SET _mia_050;
    DO i = 1 TO ncol;
      SET _mia_bign(KEEP=col bign) POINT=i NOBS=ncol;
      OUTPUT;
    END;
    DROP i;
  RUN;

  /* the count of each cell, 0 where nobody had the event */
  DATA _mia_052;
    MERGE _mia_051 _mia_031;
    BY level aebodsys aedecod col;
    IF MISSING(n) THEN n = 0;
  RUN;

  /* the rank of the SOC (ord) and of the PT (sub), the row label and the text of each cell */
  PROC SORT DATA=_mia_052; BY aebodsys aedecod; RUN;
  PROC SORT DATA=_mia_041; BY aebodsys; RUN;
  PROC SORT DATA=_mia_042; BY aebodsys aedecod; RUN;
  DATA _mia_053;
    MERGE _mia_052(IN=inline) _mia_041;
    BY aebodsys;
    IF inline;
  RUN;
  DATA &out.(KEEP=level aebodsys aedecod col ord sub label value);
    LENGTH label $200 value $20;
    MERGE _mia_053(IN=inline) _mia_042;
    BY aebodsys aedecod;
    IF inline;
    IF level = 0 THEN ord = 0;
    IF level < 2 THEN sub = 0;
    IF      level = 0 THEN label = "Subjects with at least one TEAE";
    ELSE IF level = 1 THEN label = aebodsys;
    ELSE                   label = CAT("  ", STRIP(aedecod));
    IF n = 0 THEN value = "0";
    ELSE value = CATX(" ", PUT(n, 4.), CATS("(", PUT(n / bign * 100, 5.1), ")"));
  RUN;
  PROC SORT DATA=&out.;
    BY ord sub col;
  RUN;

  /* Step 060: print */
  %IF %UPCASE(&print.) = Y %THEN %DO;
    TITLE1 "&title.";
    TITLE2 "Safety population. Subjects are counted once per line.";
    %m_report(data=&out., denom=_mia_bign, fmt=&fmt., lwidth=50)
    TITLE;
  %END;

  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mia_:; RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] &nteae. events, ended after %SYSEVALF(%SYSFUNC(DATETIME()) - &t0., CEIL) seconds.;
%MEND m_incidence_ae;

/* Step 1: the table of 13.3 again, as one call */
OPTIONS LS=132 PS=80 NOCENTER;
%m_incidence_ae(title=Table 14.3.1 Treatment emergent adverse events, out=ia_all)

/* Step 2: the payoff. Each table adds only its subset */
%m_incidence_ae(where=aeser = "Y", title=Table 14.3.2 Serious treatment emergent adverse events, out=ia_ser)
%m_incidence_ae(where=aesev = "SEVERE", title=Table 14.3.3 Severe treatment emergent adverse events, out=ia_sev)
%m_incidence_ae(where=aerel IN ("POSSIBLE" "PROBABLE"),
                title=Table 14.3.4 Treatment emergent adverse events related to the study drug, out=ia_rel, print=N)
