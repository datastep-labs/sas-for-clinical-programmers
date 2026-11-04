/*******************************************************************************
  Macro       : %count_subj
  Version     : 1.2
  Purpose     : Number of subjects (distinct USUBJID) by one or more variables
  Parameters  :
    data=     input data set with USUBJID (required)
    by=       variables to count by, separated by blanks (required)
    where=    condition on the input (default: all records)
    out=      output data set (default: counts)
    debug=    Y keeps the numbered work data sets and switches on MPRINT
  Example     :
    %count_subj(data=refadm.adae, by=trtan, where=%STR(trtemfl = "Y"))
  Change log  :
    2026-10-31  1.0  first version
    2026-10-31  1.1  checks the parameters, cleans up with %GOTO
    2026-10-31  1.2  debug= keeps _cs_ data sets, MPRINT saved and restored
*******************************************************************************/
%MACRO count_subj(data=, by=, where=1, out=counts, debug=N);
  %LOCAL i v old_mprint;

  /* Step 0: save the options and remove what an earlier call left */
  %LET old_mprint = %SYSFUNC(GETOPTION(MPRINT));
  %IF %UPCASE(&debug.) = Y %THEN %DO;
    OPTIONS MPRINT;
  %END;
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _cs_:; RUN; QUIT;

  /* Check the parameters */
  %IF %LENGTH(&data.) = 0 OR %LENGTH(&by.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [COUNT_SUBJ] DATA= and BY= are required.;
    %GOTO finish;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [COUNT_SUBJ] Data set &data. does not exist.;
    %GOTO finish;
  %END;

  /* Step 010: the records that count */
  DATA _cs_010;
    SET &data.;
    WHERE %UNQUOTE(&where.);
  RUN;

  /* Step 020: one count per BY group: sorted, then counted with BY */
  PROC SORT DATA=_cs_010;
    BY &by. usubjid;
  RUN;
  DATA _cs_020(KEEP=&by. n_subj);
    SET _cs_010;
    BY &by. usubjid;
    IF FIRST.%SCAN(&by., -1, %STR( )) THEN n_subj = 0;
    IF FIRST.usubjid THEN n_subj + 1;
    IF LAST.%SCAN(&by., -1, %STR( ));
  RUN;

  DATA &out.;
    SET _cs_020;
  RUN;

  %finish:
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _cs_:; RUN; QUIT;
  %END;
  OPTIONS &old_mprint.;
%MEND count_subj;
