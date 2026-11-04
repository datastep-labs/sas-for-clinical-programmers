/* Chapter 3: date and time functions on real dates */

/* Step 010: a date and a time from ISO 8601 text: the first laboratory sample */
DATA lb_dtm;
  SET sdtm.lb(KEEP=usubjid lbtestcd lbdtc OBS=1);
  lbdtm = INPUT(lbdtc, E8601DT.);
  lbdt  = DATEPART(lbdtm);
  lbtm  = TIMEPART(lbdtm);
  FORMAT lbdtm E8601DT. lbdt DATE9. lbtm TIME5.;
RUN;

PROC PRINT DATA=lb_dtm NOOBS;
RUN;

/* Step 020: AE duration in days, and the months since the first dose */
DATA ae_dur;
  SET refadm.adae(KEEP=usubjid aedecod astdt aendt trtsdt adurn);
  WHERE NOT MISSING(astdt) AND NOT MISSING(aendt);
  aedur   = aendt - astdt + 1;
  differ  = (aedur NE adurn);
  months  = INTCK("MONTH", trtsdt, astdt);
  mon_beg = INTNX("MONTH", astdt, 0, "B");
  FORMAT mon_beg DATE9.;
RUN;

PROC PRINT DATA=ae_dur(OBS=3) NOOBS;
  VAR usubjid aedecod trtsdt astdt aendt aedur adurn months mon_beg;
RUN;

PROC FREQ DATA=ae_dur;
  TABLES differ / NOCUM;
RUN;

/* Step 030: INTCK counts boundaries, not full months */
DATA _NULL_;
  one_day   = INTCK("MONTH", "31JAN2014"d, "01FEB2014"d);
  full_mons = INTCK("MONTH", "31JAN2014"d, "01FEB2014"d, "C");
  PUTLOG one_day= full_mons=;
RUN;

/* Step 040: years on treatment */
DATA trt_years;
  SET refadm.adsl(KEEP=usubjid trtsdt trtedt trtdur);
  WHERE NOT MISSING(trtedt);
  years = YRDIF(trtsdt, trtedt, "ACT/ACT");
RUN;

PROC MEANS DATA=trt_years N MEAN MAX MAXDEC=2;
  VAR trtdur years;
RUN;
