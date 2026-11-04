/* Chapter 12: a study macro for time-to-event parameters, %m_tte, with a time window (needs ADTTE from 12_1) */

/*******************************************************************************
  Macro       : %m_tte
  Version     : 2.1
  Purpose     : One time-to-event record per subject. An event counts only
                inside the window from the start date to the end date. The
                first event in the window wins. A subject without an event in
                the window is censored at the censoring date when that date is
                inside the window, else at the end of the window.
  Parameters  :
    data=        the subjects, one record each: usubjid and every variable
                 that the date expressions below use (required)
    out=         output data set (required)
    paramcd=     the parameter code, e.g. TTDE (required)
    param=       the parameter name (required)
    events=      one or more event data sets with usubjid adt evntdesc srcdom
                 srcvar srcseq; an optional numeric prio decides between two
                 events on the same day, the lower value wins (required)
    startdt=     start of the window, a DATA step expression (default trtsdt)
    enddt=       end of the window, a DATA step expression, e.g. trtsdt + 83
                 (required)
    censordt=    the censoring date, a DATA step expression, e.g. rfendt
                 (optional: without it, every subject without an event is
                 censored at the end of the window)
    censor_desc= EVNTDESC of a censoring at censordt (default Censoring date)
    end_desc=    EVNTDESC of a censoring at the end of the window
                 (default End of at-risk period)
    srcdom=      SRCDOM of a censoring at censordt (default ADSL)
    debug=       N (default) deletes the work data sets _mtt_:; Y keeps them
  Preconditions  : adt and the date expressions give SAS dates; usubjid is
                   unique in &data.
  Postconditions : &out. has one record per subject with a valid window:
                   usubjid paramcd param startdt adt aval cnsr evntdesc srcdom
                   srcvar srcseq. A subject with a missing start or end date,
                   or a start after the end, is left out with a WARNING.
  Rule of the day: the pilot study has dates, no times, so an event on the
                   start day counts (AVAL = 1). With times, an event on the
                   start day counts only from the start time on.
  Examples       :
    %m_tte(data=subj, out=tte_derm, paramcd=TTDE, param=Time to First Dermatologic Event,
           events=ev_derm, enddt=rfendt, censordt=rfendt, censor_desc=Study completion date)
    %m_tte(data=subj, out=tte_derm12, paramcd=TTDE12, param=Time to First Dermatologic Event in 12 Weeks,
           events=ev_derm, enddt=trtsdt + 83, censordt=rfendt, censor_desc=Study completion date)
  Change history :
    2026-11-01  1.0  first version: events= and censors= source lists
    2026-11-02  2.0  time window: startdt=, enddt=, censordt=, censor_desc=,
                     end_desc=, srcdom= replace censors=; a build-log NOTE
    2026-11-02  2.1  debug= and the runtime NOTE (the checklist of 19.6)
*******************************************************************************/
%MACRO m_tte(data=, out=, paramcd=, param=, events=, startdt=trtsdt, enddt=, censordt=,
             censor_desc=Censoring date, end_desc=End of at-risk period, srcdom=ADSL, debug=N)
  / DES = 'Time-to-event records with a time window';
  %LOCAL macro mversion _starttime p par i ds ndup nexcl nsubj nev ncens nend censvar;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 2.1;
  %LET _starttime = %SYSFUNC(DATETIME());

  /* Check the parameters: the required ones, then the data sets */
  %DO p = 1 %TO 6;
    %LET par = %SCAN(data out paramcd param events enddt, &p.);
    %IF %SUPERQ(&par.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the parameter &par.= is required.;
      %RETURN;
    %END;
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&data. &events., %STR( )));
    %LET ds = %SCAN(&data. &events., &i., %STR( ));
    %IF NOT %SYSFUNC(EXIST(&ds.)) %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the data set &ds. does not exist.;
      %RETURN;
    %END;
  %END;
  PROC SORT DATA=&data. OUT=_mtt_001(KEEP=usubjid) NODUPKEY DUPOUT=_mtt_002(KEEP=usubjid);
    BY usubjid;
  RUN;
  DATA _NULL_;
    IF 0 THEN SET _mtt_002 NOBS=nobs;
    CALL SYMPUTX("ndup", nobs, "L");
    STOP;
  RUN;
  %IF &ndup. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] &data. has &ndup. records too many: one record per subject is required.;
    %RETURN;
  %END;
  %PUT NOTE: [&macro.] Version &mversion. started %SYSFUNC(DATE(), DATE9.) %SYSFUNC(TIME(), HHMM.);

  /* SRCVAR of a censoring at censordt: the variable name, when censordt= is one name */
  %LET censvar = ;
  %IF %SUPERQ(censordt) NE %THEN %DO;
    %IF %SYSFUNC(NVALID(%SUPERQ(censordt))) %THEN %LET censvar = %UPCASE(&censordt.);
  %END;

  /* Step 010: the window of each subject; a subject without a valid window is left out */
  DATA _mtt_010 _mtt_011(KEEP=usubjid);
    SET &data.;
    startdt  = &startdt.;
    enddt    = &enddt.;
    %IF %SUPERQ(censordt) = %THEN %DO;
      censordt = .;
    %END;
    %ELSE %DO;
      censordt = &censordt.;
    %END;
    FORMAT startdt enddt censordt DATE9.;
    IF MISSING(startdt) OR MISSING(enddt) OR startdt > enddt THEN OUTPUT _mtt_011;
    ELSE OUTPUT _mtt_010;
    KEEP usubjid startdt enddt censordt;
  RUN;
  DATA _NULL_;
    IF 0 THEN SET _mtt_011 NOBS=nobs;
    CALL SYMPUTX("nexcl", nobs, "L");
    STOP;
  RUN;
  %IF &nexcl. > 0 %THEN
    %PUT %STR(WAR)NING: [&macro.] &paramcd.: subjects left out: &nexcl. (missing start or end date, or the start after the end).;

  /* Step 020: the events inside the window; the first one per subject wins */
  DATA _mtt_020;
    /* prio is optional: a source without it gets a missing prio */
    LENGTH prio 8;
    CALL MISSING(prio);
    SET &events.;
    KEEP usubjid adt evntdesc srcdom srcvar srcseq prio;
  RUN;
  PROC SORT DATA=_mtt_020; BY usubjid adt prio srcseq; RUN;
  PROC SORT DATA=_mtt_010; BY usubjid; RUN;
  DATA _mtt_021;
    MERGE _mtt_020(IN=inev) _mtt_010(IN=insubj KEEP=usubjid startdt enddt);
    BY usubjid;
    /* the start day counts: no times in the data */
    IF inev AND insubj AND NOT MISSING(adt) AND startdt <= adt <= enddt;
  RUN;
  DATA _mtt_022;
    SET _mtt_021;
    BY usubjid;
    IF FIRST.usubjid;
    cnsr = 0;
    DROP prio startdt enddt;
  RUN;

  /* Step 030: one record per subject: the event, or a censoring */
  DATA &out.;
    LENGTH paramcd $8 param $60 evntdesc $40 srcdom srcvar $8;
    MERGE _mtt_010(IN=insubj) _mtt_022(IN=inev);
    BY usubjid;
    IF insubj;
    paramcd = "&paramcd.";
    param   = "&param.";
    IF NOT inev THEN DO;
      cnsr   = 1;
      srcseq = .;
      IF NOT MISSING(censordt) AND startdt <= censordt <= enddt THEN DO;
        adt      = censordt;
        evntdesc = "&censor_desc.";
        srcdom   = "&srcdom.";
        srcvar   = "&censvar.";
      END;
      ELSE DO;
        adt      = enddt;
        evntdesc = "&end_desc.";
        srcdom   = "";
        srcvar   = "";
      END;
    END;
    aval = adt - startdt + 1;
    FORMAT startdt adt DATE9.;
    KEEP usubjid paramcd param startdt adt aval cnsr evntdesc srcdom srcvar srcseq;
  RUN;

  /* Step 040: the build log, one line per parameter */
  DATA _NULL_;
    SET &out. END=last;
    nev   + (cnsr = 0);
    ncens + (cnsr = 1 AND evntdesc = "&censor_desc.");
    nend  + (cnsr = 1 AND evntdesc = "&end_desc.");
    IF last THEN DO;
      CALL SYMPUTX("nsubj", _N_, "L");
      CALL SYMPUTX("nev", nev, "L");
      CALL SYMPUTX("ncens", ncens, "L");
      CALL SYMPUTX("nend", nend, "L");
    END;
  RUN;
  %PUT NOTE: [&macro.] &paramcd.: &nsubj. subjects, &nev. events, &ncens. censored at censordt, &nend. censored at the end of the window, &nexcl. left out.;

  /* Remove the work data sets of this macro, unless debug=Y */
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mtt_:;
    RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] Finished in %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &_starttime.), 0.01)) seconds.;
%MEND m_tte;

/* Step 010: the subjects and the events, in plain DATA steps */
DATA subj;
  SET refadm.adsl(KEEP=usubjid trtsdt trtedt rfendt saffl WHERE=(saffl = "Y"));
RUN;

DATA ev_derm;
  LENGTH evntdesc $40 srcdom srcvar $8;
  SET refadm.adae(KEEP=usubjid aeseq astdt trtemfl cq01nam
                  WHERE=(trtemfl = "Y" AND NOT MISSING(cq01nam)));
  adt = astdt; evntdesc = "Dermatologic event"; srcdom = "ADAE"; srcvar = "ASTDT"; srcseq = aeseq;
RUN;

/* Step 020: the parameter of 12_1, now one call: the window ends at the end of study */
%m_tte(data=subj, out=tte_derm, paramcd=TTDE, param=Time to First Dermatologic Event,
       events=ev_derm, enddt=rfendt, censordt=rfendt, censor_desc=Study completion date)

/* Step 030: a second parameter is one more source and one more call */
DATA ev_ser;
  LENGTH evntdesc $40 srcdom srcvar $8;
  SET refadm.adae(KEEP=usubjid aeseq astdt trtemfl aeser
                  WHERE=(trtemfl = "Y" AND aeser = "Y"));
  adt = astdt; evntdesc = "Serious adverse event"; srcdom = "ADAE"; srcvar = "ASTDT"; srcseq = aeseq;
RUN;

%m_tte(data=subj, out=tte_ser, paramcd=TTSAE, param=Time to First Serious Adverse Event,
       events=ev_ser, enddt=rfendt, censordt=rfendt, censor_desc=Study completion date)

/* Step 040: the same events in another window: the first 12 weeks (days 1 to 84) */
%m_tte(data=subj, out=tte_derm12, paramcd=TTDE12, param=Time to First Dermatologic Event in 12 Weeks,
       events=ev_derm, enddt=trtsdt + 83, censordt=rfendt, censor_desc=Study completion date)

DATA adtte_all;
  SET tte_derm tte_ser tte_derm12;
RUN;

PROC FREQ DATA=adtte_all;
  TABLES paramcd*cnsr*evntdesc / LIST NOCUM NOPERCENT;
RUN;

/* Step 050: three subjects, three results of the 12-week window */
PROC MEANS DATA=ev_derm NOPRINT NWAY;
  CLASS usubjid;
  VAR adt;
  FORMAT adt DATE9.;
  OUTPUT OUT=first_any(KEEP=usubjid first_event) MIN=first_event;
RUN;
DATA cases;
  MERGE tte_derm12(IN=intte) subj(KEEP=usubjid rfendt) first_any;
  BY usubjid;
  WHERE usubjid IN ("01-701-1015" "01-705-1059" "01-701-1033");
  IF intte;
  enddt    = startdt + 83;
  censordt = rfendt;
  FORMAT enddt censordt DATE9.;
RUN;
PROC PRINT DATA=cases NOOBS;
  VAR usubjid startdt enddt censordt first_event adt aval cnsr evntdesc;
RUN;
