/* Chapter 10: the study macros for BDS data sets, %m_baseline and %m_chg. Run this file once, then 10_2 and later programs use them. */

/*******************************************************************************
  Macro            : %m_baseline (study macro)
  Version          : 2.0
  Purpose          : Mark the baseline record of each group, as the SAP
                     defines it: the last record that meets the condition.
  SAP text         : example SAP definition written for this book
                     "Baseline is the last non-missing value on or before the
                     day of the first dose. When that value comes from a
                     screening visit, the screening value is the baseline.
                     Blood pressure and pulse are measured in three positions:
                     each position has its own baseline."
  Parameters       :
    data=            a BDS data set (required)
    out=             the output data set, sorted by &sortby. (required)
    by=              one baseline per group (default usubjid paramcd)
    where=           which records can be baseline, a WHERE condition
                     (default adt <= trtsdt AND NOT MISSING(aval))
    sortby=          the by= variables, then the time order: the last record
                     of a group is its baseline (default &by. adt). Add a
                     key such as the SDTM sequence number when two records
                     of a group can have the same date.
    baseline_visit=  AVISITN of the new records when copy=Y (default 0)
    copy=            N: set ABLFL = "Y" on the collected baseline record
                     (default; the reference ADVS of the pilot does this)
                     Y: also add a copy with AVISIT "Baseline", AVISITN =
                     &baseline_visit., ABLFL "Y". Only for records without an
                     analysis visit, else a group has two Baseline rows
  Preconditions    : &data. has the variables of by=, sortby= and where=;
                     sortby= starts with the variables of by=
  Postconditions   : &out. has all records of &data. and the variable ABLFL,
                     "Y" on exactly one record per group that has a record
                     meeting where=; with copy=Y one more record per such
                     group; work data sets _mbl_: are deleted
  Validation level : independent double programming of the baseline values
  Examples         :
    %m_baseline(data=advs_bp_010, out=advs_bp_020, by=usubjid paramcd atptn,
                sortby=usubjid paramcd atptn adt vsseq)
    %m_baseline(data=adlb_010, out=adlb_020, sortby=usubjid paramcd adt lbseq)
  Author           : your name, date
  Change history   :
    2026-11-01  1.0  first version, case study of Part V
    2026-11-01  1.1  renamed: input= to data=, baseline_cond= to where=, groupby= to by=, output= to out=
    2026-11-01  2.0  moved to chapter 10 for every BDS data set: defaults, copy=N|Y, all records
*******************************************************************************/
%MACRO m_baseline(data=, out=, by=usubjid paramcd, where=adt <= trtsdt AND NOT MISSING(aval),
                  sortby=&by. adt, baseline_visit=0, copy=N)
  / DES = 'Mark the baseline record of each group';
  %LOCAL macro mversion i p n last;
  %LET macro    = %UPCASE(&SYSMACRONAME.);
  %LET mversion = 2.0;

  /* Check the parameters: required ones, the input, the sort order, copy= */
  %DO i = 1 %TO 5;
    %LET p = %SCAN(data out by where sortby, &i.);
    %IF %LENGTH(%SUPERQ(&p.)) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] Parameter %UPCASE(&p.)= is required.;
      %RETURN;
    %END;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] Data set &data. does not exist.;
    %RETURN;
  %END;
  %LET n = %SYSFUNC(COUNTW(&by., %STR( )));
  %DO i = 1 %TO &n.;
    %IF %UPCASE(%SCAN(&by., &i., %STR( ))) NE %UPCASE(%SCAN(&sortby., &i., %STR( ))) %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] SORTBY= must start with the BY= variables.;
      %RETURN;
    %END;
  %END;
  %LET copy = %UPCASE(&copy.);
  %IF &copy. NE N AND &copy. NE Y %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] COPY= must be N or Y, not &copy..;
    %RETURN;
  %END;
  %LET last = %SCAN(&by., -1, %STR( ));

  %PUT NOTE: [&macro.] Version &mversion. started %SYSFUNC(DATE(), DATE9.) %SYSFUNC(TIME(), HHMM.);

  /* Step 010: the records in time order within each group, numbered */
  PROC SORT DATA=&data. OUT=_mbl_010;
    BY &sortby.;
  RUN;
  DATA _mbl_010;
    SET _mbl_010;
    _mbl_n = _N_;
  RUN;

  /* Step 020: the number of the last record of each group that can be baseline */
  DATA _mbl_020(KEEP=_mbl_n);
    SET _mbl_010(WHERE=(&where.));
    BY &by.;
    IF LAST.&last.;
  RUN;

  /* Step 030: flag that record, or add a copy of it */
  DATA &out.(DROP=_mbl_n);
    LENGTH ablfl $1;
    MERGE _mbl_010 _mbl_020(IN=_mbl_bl);
    BY _mbl_n;
    %IF &copy. = N %THEN %DO;
      IF _mbl_bl THEN ablfl = "Y";
      ELSE            ablfl = "";
    %END;
    %ELSE %DO;
      ablfl = "";
      OUTPUT;
      IF _mbl_bl THEN DO;
        avisit  = "Baseline";
        avisitn = &baseline_visit.;
        ablfl   = "Y";
        OUTPUT;
      END;
    %END;
  RUN;

  /* Remove the work data sets of this macro */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _mbl_:;
  RUN; QUIT;
%MEND m_baseline;

/*******************************************************************************
  Macro            : %m_chg (study macro)
  Version          : 1.2
  Purpose          : Put the baseline value on every record of its group (BASE)
                     and compute the change (CHG) and the percent change (PCHG).
  Parameters       :
    data=            input data set with one baseline record per group (required)
    out=             output data set, sorted by &by. (required)
    by=              the variables of one group, e.g. usubjid paramcd (required)
    flag=            the baseline flag, Y on the baseline record (default ablfl)
    debug=           N (default) deletes the work data sets _mch_:; Y keeps them
  Preconditions    : &data. has the analysis value aval; at most one record
                     with &flag. = "Y" per group
  Postconditions   : &out. = &data. plus the new variables base, chg and
                     pchg (existing variables with these names are replaced).
                     CHG is computed on every record with AVAL and BASE: on
                     the baseline record it is 0, before baseline it is not
                     empty. Your specification may ask for empty values there.
  Validation level : independent double programming of BASE and CHG
  Examples         :
    %m_chg(data=advs_bp_020, out=advs_bp, by=usubjid paramcd atptn)
    %m_chg(data=adlb_020, out=adlb_alt, by=usubjid paramcd, debug=Y)
  Author           : your name, date
  Change history   :
    2026-11-01  1.0  first version
    2026-11-01  1.1  version NOTE and messages as in %m_baseline; WORK._MCH_021
                     keeps the whole records of a group with two baselines
    2026-11-02  1.2  debug= and the runtime NOTE (the checklist of 19.6)
*******************************************************************************/
%MACRO m_chg(data=, out=, by=, flag=ablfl, debug=N)
  / DES = 'BASE, CHG and PCHG from the baseline record of each group';
  %LOCAL macro mversion _starttime i p last ndup;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 1.2;
  %LET _starttime = %SYSFUNC(DATETIME());

  /* Check the parameters: required ones and the input */
  %DO i = 1 %TO 3;
    %LET p = %SCAN(data out by, &i.);
    %IF %LENGTH(%SUPERQ(&p.)) = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] Parameter %UPCASE(&p.)= is required.;
      %RETURN;
    %END;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] Data set &data. does not exist.;
    %RETURN;
  %END;
  %LET last = %SCAN(&by., -1, %STR( ));

  %PUT NOTE: [&macro.] Version &mversion. started %SYSFUNC(DATE(), DATE9.) %SYSFUNC(TIME(), HHMM.);

  /* Step 010: the records in group order */
  PROC SORT DATA=&data. OUT=_mch_010;
    BY &by.;
  RUN;

  /* Step 020: one baseline value per group; two baseline records is an error */
  DATA _mch_020(KEEP=&by. base) _mch_021;
    SET _mch_010(WHERE=(&flag. = "Y"));
    BY &by.;
    base = aval;
    IF FIRST.&last. AND LAST.&last. THEN OUTPUT _mch_020;
    ELSE                                  OUTPUT _mch_021;
  RUN;
  DATA _NULL_;
    IF 0 THEN SET _mch_021 NOBS=nobs;
    CALL SYMPUTX("ndup", nobs, "L");
    STOP;
  RUN;
  %IF &ndup. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] &ndup. baseline records in groups with more than one. See WORK._MCH_021.;
    %RETURN;
  %END;

  /* Step 030: BASE on every record of the group, then CHG and PCHG */
  DATA &out.;
    MERGE _mch_010 _mch_020;
    BY &by.;
    IF NOT MISSING(aval) AND NOT MISSING(base) THEN DO;
      chg = aval - base;
      IF base NE 0 THEN pchg = chg / base * 100;
    END;
  RUN;

  /* Remove the work data sets of this macro, unless debug=Y */
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mch_:;
    RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] Finished in %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &_starttime.), 0.01)) seconds.;
%MEND m_chg;
