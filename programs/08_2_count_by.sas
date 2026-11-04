/*******************************************************************************
| Macro Name    : count_by
| Macro Version : v1.02
| Purpose       : Count subjects and records by one or more variables.
|
| Parameters
|   data  = input data set, required             Example: refadm.adae
|   by    = grouping variables, required          Example: trtan aesev
|   where = filter, default 1 (all records)       Example: %STR(trtemfl = "Y")
|   out   = output data set, default counts
|   debug = Y keeps the _cb_ work data sets, default N
|
| Usage
|   %count_by(data=refadm.adae, by=trtan aesev, where=%STR(trtemfl = "Y"))
|
| Change log
|   v1.00  first version
|   v1.01  checks of the required parameters and of the variables
|   v1.02  debug parameter keeps the intermediate data sets
*******************************************************************************/
%MACRO count_by(
  data  =
, by    =
, where = 1
, out   = counts
, debug = N
);
  %LOCAL i v;

  /* Step 0: clean up the work data sets of an earlier call */
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _cb_:; RUN; QUIT;

  %IF %LENGTH(&data.) = 0 OR %LENGTH(&by.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [COUNT_BY] DATA= and BY= are required.;
    %GOTO finish;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [COUNT_BY] Data set &data. does not exist.;
    %GOTO finish;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&by., %STR( )));
    %LET v = %SCAN(&by., &i., %STR( ));
    %IF %varexist(&data., &v.) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [COUNT_BY] Variable &v. is not in &data..;
      %GOTO finish;
    %END;
  %END;

  /* Step 1: the records to count */
  DATA _cb_001_in;
    SET &data.;
    WHERE %UNQUOTE(&where.);
  RUN;

  /* Step 2: subjects and records per group: sorted, then counted with BY */
  PROC SORT DATA=_cb_001_in OUT=_cb_002;
    BY &by. usubjid;
  RUN;
  DATA &out.(KEEP=&by. n_subj n_rec);
    SET _cb_002;
    BY &by. usubjid;
    IF FIRST.%SCAN(&by., -1, %STR( )) THEN DO;
      n_subj = 0;
      n_rec  = 0;
    END;
    n_rec + 1;
    IF FIRST.usubjid THEN n_subj + 1;
    IF LAST.%SCAN(&by., -1, %STR( ));
  RUN;

  %finish:
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _cb_:; RUN; QUIT;
  %END;
%MEND count_by;

%count_by(data=refadm.adae, by=trtan aesev, where=%STR(trtemfl = "Y"))

PROC PRINT DATA=counts NOOBS; RUN;
