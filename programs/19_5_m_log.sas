/* Chapter 19: the design checklist in code: the log utility %m_log and a macro built from the template (needs 00_study.sas) */

/*******************************************************************************
  Macro            : %m_log
  Version          : 1.0
  Purpose          : Write one message to the log in the book's format,
                     LEVEL: [MACRO] text, and, when start= is given, the
                     runtime since that moment in seconds.
  Parameters       :
    level=           NOTE (default), WARNING or ERROR
    text=            the message (required); use %STR(,) for a comma
    start=           a DATETIME() value; the message then ends with
                     "in n.nn seconds"
    macro=           the name in brackets (default: the macro that calls
                     %m_log, or OPEN CODE)
  Examples         :
    %m_log(text=Version 1.0 started)
    %m_log(level=WARNING, text=2 variables dropped)
    %m_log(text=Finished, start=&_starttime.)
  Preconditions    : none
  Postconditions   : one line in the log; no data set, no option changed
  Validation level : review
  Change history   :
    2026-11-02  1.0  first version
*******************************************************************************/

/* private helper: the seconds since a DATETIME() value, rounded to 0.01 */
%MACRO _mlg_secs(start);
  %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &start.), 0.01))
%MEND _mlg_secs;

%MACRO m_log(level=NOTE, text=, start=, macro=) / MINOPERATOR DES = 'Write one message in the book log format';
  %LOCAL lvl who msg;
  %LET lvl = %UPCASE(&level.);
  %IF NOT (&lvl. IN NOTE WARNING ERROR) %THEN %LET lvl = NOTE;
  %LET who = %UPCASE(%SUPERQ(macro));
  %IF %LENGTH(&who.) = 0 %THEN %LET who = %SYSMEXECNAME(%EVAL(%SYSMEXECDEPTH - 1));
  %LET msg = %SUPERQ(text);
  %IF %LENGTH(&start.) %THEN %LET msg = &msg. in %_mlg_secs(&start.) seconds;
  /* the word is split, so the source line never looks like a message */
  %IF &lvl. = ERROR %THEN %PUT %STR(ERR)OR: [&who.] &msg..;
  %ELSE %IF &lvl. = WARNING %THEN %PUT %STR(WARN)ING: [&who.] &msg..;
  %ELSE %PUT NOTE: [&who.] &msg..;
%MEND m_log;

/*******************************************************************************
  Macro            : %m_n_subj
  Version          : 1.0
  Purpose          : The big N of a table: the number of subjects of a
                     population per treatment arm.
  Parameters       :
    data=            the subject-level data set (default refadm.adsl)
    where=           the population (default &saf_cond. from 00_study.sas)
    by=              the treatment variable (default &trt. from 00_study.sas)
    out=             the output data set: &by. and n (required)
    debug=           N (default) deletes the work data sets _mns_:;
                     Y keeps them and switches on MPRINT
  Examples         :
    %m_n_subj(out=bign)
    %m_n_subj(where=%STR(ittfl = "Y"), out=bign_itt, debug=Y)
  Preconditions    : 00_study.sas has run (it sets saf_cond and trt);
                     &data. has usubjid and &by.
  Postconditions   : &out. has one row per value of &by.; the option
                     MPRINT is as it was before the call
  Validation level : review
  Change history   :
    2026-11-02  1.0  first version, built from the template of 19.6
*******************************************************************************/
%MACRO m_n_subj(data=refadm.adsl, where=&saf_cond., by=&trt., out=, debug=N)
  / MINOPERATOR DES = 'Big N per treatment arm';
  %LOCAL macro mversion _starttime _mprint nrow;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 1.0;
  %LET _starttime = %SYSFUNC(DATETIME());

  /* Check first: nothing runs when one check fails */
  %IF %LENGTH(%SUPERQ(out)) = 0 %THEN %DO;
    %m_log(level=ERROR, text=Parameter OUT= is required)
    %RETURN;
  %END;
  %LET debug = %UPCASE(&debug.);
  %IF NOT (&debug. IN Y N) %THEN %DO;
    %m_log(level=ERROR, text=DEBUG= must be Y or N%STR(,) not &debug.)
    %RETURN;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %m_log(level=ERROR, text=Data set &data. does not exist)
    %RETURN;
  %END;
  %m_log(text=Version &mversion. started)

  /* Save the option this macro changes, and change it */
  %LET _mprint = %SYSFUNC(GETOPTION(MPRINT));
  %IF &debug. = Y %THEN %DO;
    OPTIONS MPRINT;
  %END;

  /* Step 010: one record per subject of the population */
  PROC SORT DATA=&data.(WHERE=(&where.)) OUT=_mns_010(KEEP=usubjid &by.) NODUPKEY;
    BY &by. usubjid;
  RUN;

  /* Step 020: the count per arm */
  PROC FREQ DATA=_mns_010 NOPRINT;
    TABLES &by. / OUT=&out.(KEEP=&by. count RENAME=(count=n));
  RUN;
  DATA _NULL_;
    IF 0 THEN SET &out. NOBS=nobs;
    CALL SYMPUTX("nrow", nobs, "L");
    STOP;
  RUN;

  /* Restore the option, clean up, and report the runtime */
  OPTIONS &_mprint.;
  %IF &debug. = N %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mns_:;
    RUN; QUIT;
  %END;
  %m_log(text=&out.: &nrow. arms. Finished, start=&_starttime.)
%MEND m_n_subj;

/* The defaults come from 00_study.sas: the safety population per treatment arm */
%m_n_subj(out=bign)
PROC PRINT DATA=bign NOOBS;
RUN;

/* Another population: only the call changes */
%m_n_subj(where=%STR(ittfl = "Y"), out=bign_itt, debug=Y)
PROC PRINT DATA=bign_itt NOOBS;
RUN;
