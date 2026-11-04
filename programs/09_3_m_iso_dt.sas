/* EXPECT: ERROR [M_ISO_DT] */
/* Chapter 9: a study macro for ISO 8601 dates, written because 09_1 does the same thing three times (needs 09_1) */

/*******************************************************************************
  Macro       : %m_iso_dt
  Version     : 1.0
  Purpose     : ISO 8601 text date (--DTC) to SAS date. impute=FIRST|LAST
                gives 2013-03 the first|last day (flag D); a year stays missing.
  Parameters  :
    data=     input data set, data set options allowed (required)
    out=      output data set (required)
    dtc=      the ISO 8601 text variable, e.g. aestdtc (required)
    dt=       the new SAS date variable, e.g. astdt (required)
    impute=   NONE (default), FIRST or LAST
    flag=     the new imputation flag variable, e.g. astdtf (required
              when impute is FIRST or LAST)
  Preconditions  : &dtc. exists in &data.
  Postconditions : &out. = &data. plus &dt. (FORMAT DATE9.) and &flag.
  Examples    :
    %m_iso_dt(data=sdtm.ex, out=ex_dt, dtc=exstdtc, dt=exstdt)
    %m_iso_dt(data=sdtm.ae, out=ae_dt, dtc=aestdtc, dt=astdt, impute=FIRST, flag=astdtf)
  Change log  :
    2026-11-01  1.0  first version
*******************************************************************************/
%MACRO m_iso_dt(data=, out=, dtc=, dt=, impute=NONE, flag=);
  %LOCAL macro p ds dsid hasvar rc;
  %LET macro  = M_ISO_DT;
  %LET impute = %UPCASE(&impute.);

  /* Check the parameters: nothing runs when one check fails */
  %DO p = 1 %TO 4;
    %LET ds = %SCAN(data out dtc dt, &p.);
    %IF %SUPERQ(&ds.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the parameter &ds.= is required.;
      %RETURN;
    %END;
  %END;
  /* the data set name without its options: sdtm.ex(KEEP=...) is sdtm.ex */
  %LET ds = %SCAN(&data., 1, %STR(%());
  %IF NOT %SYSFUNC(EXIST(&ds.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the data set &ds. does not exist.;
    %RETURN;
  %END;
  %LET dsid   = %SYSFUNC(OPEN(&ds.));
  %LET hasvar = %SYSFUNC(VARNUM(&dsid., &dtc.));
  %LET rc     = %SYSFUNC(CLOSE(&dsid.));
  %IF &hasvar. = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the variable &dtc. is not in &ds..;
    %RETURN;
  %END;
  %IF NOT (&impute. = NONE OR &impute. = FIRST OR &impute. = LAST) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] impute=&impute. is not NONE, FIRST or LAST.;
    %RETURN;
  %END;
  %IF &impute. NE NONE AND %SUPERQ(flag) = %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] impute=&impute. needs flag=, the imputation flag variable.;
    %RETURN;
  %END;

  /* The mechanism: the work variables have a private prefix, so they cannot */
  /* overwrite a variable of the caller                                       */
  DATA &out.;
    SET &data.;
    %IF &impute. NE NONE %THEN %DO;
      LENGTH &flag. $1;
      &flag. = "";
    %END;
    _mid_yy = INPUT(SUBSTR(&dtc., 1, 4), ?? 4.);
    _mid_mm = .;
    IF LENGTHN(&dtc.) >= 7 THEN _mid_mm = INPUT(SUBSTR(&dtc., 6, 2), ?? 2.);
    /* a complete date, perhaps with a time part: 2013-03-21T10:30 */
    IF LENGTHN(&dtc.) >= 10 THEN &dt. = INPUT(SUBSTR(&dtc., 1, 10), ?? E8601DA.);
    %IF &impute. = FIRST %THEN %DO;
      ELSE IF NOT MISSING(_mid_mm) THEN DO;
        &dt.   = MDY(_mid_mm, 1, _mid_yy);
        &flag. = "D";
      END;
    %END;
    %ELSE %IF &impute. = LAST %THEN %DO;
      ELSE IF NOT MISSING(_mid_mm) THEN DO;
        &dt.   = INTNX("MONTH", MDY(_mid_mm, 1, _mid_yy), 0, "END");
        &flag. = "D";
      END;
    %END;
    ELSE &dt. = .;
    FORMAT &dt. DATE9.;
    DROP _mid_yy _mid_mm;
  RUN;
%MEND m_iso_dt;

/* Use it: the dose dates of 09_1 again, now with the macro */
%m_iso_dt(data=sdtm.ex(KEEP=usubjid exstdtc exendtc), out=ex_m010, dtc=exstdtc, dt=exstdt)
%m_iso_dt(data=ex_m010, out=ex_m020, dtc=exendtc, dt=exendt)

/* What it does with the dates the study data does not have yet */
DATA iso_cases;
  LENGTH dtc $16;
  INPUT dtc $;
  IF dtc = "-" THEN dtc = "";
  DATALINES;
2013-03-21
2013-03-21T10:30
2013-03
2012-02
2013
-
;
RUN;

%m_iso_dt(data=iso_cases, out=iso_first, dtc=dtc, dt=dt_first, impute=FIRST, flag=dtf)
%m_iso_dt(data=iso_first, out=iso_both,  dtc=dtc, dt=dt_last,  impute=LAST,  flag=dtf_last)

PROC PRINT DATA=iso_both NOOBS;
  VAR dtc dt_first dt_last dtf;
RUN;

/* A wrong call stops before any step runs: here the name of the variable is wrong */
%m_iso_dt(data=sdtm.ex, out=ex_bad, dtc=exstdt, dt=exstdt_n)
