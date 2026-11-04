/* Chapter 12: ADTTE by hand: time to the first dermatologic event */

/* Step 010: the event: the first treatment emergent AE of the dermatologic query (CQ01) */
PROC SORT DATA=refadm.adae(WHERE=(trtemfl = "Y" AND NOT MISSING(cq01nam))
                           KEEP=usubjid aeseq astdt trtemfl cq01nam)
          OUT=derm;
  BY usubjid astdt aeseq;
RUN;

DATA first_derm;
  SET derm;
  BY usubjid;
  IF FIRST.usubjid;
  KEEP usubjid astdt aeseq;
RUN;

/* Step 020: one record per subject: the event, or censoring at the end of study */
DATA adtte;
  LENGTH paramcd $8 param $40 evntdesc $40 srcdom $8 srcvar $8;
  MERGE refadm.adsl(IN=inadsl KEEP=usubjid trtsdt rfendt saffl WHERE=(saffl = "Y"))
        first_derm(IN=inev);
  BY usubjid;
  IF inadsl;
  paramcd = "TTDE";
  param   = "Time to First Dermatologic Event";
  startdt = trtsdt;
  IF inev THEN DO;
    adt      = astdt;
    cnsr     = 0;
    evntdesc = "Dermatologic event";
    srcdom   = "ADAE";
    srcvar   = "ASTDT";
    srcseq   = aeseq;
  END;
  ELSE DO;
    adt      = rfendt;
    cnsr     = 1;
    evntdesc = "Study completion date";
    srcdom   = "ADSL";
    srcvar   = "RFENDT";
  END;
  /* the first day counts: an event on the day of the first dose is day 1 */
  aval = adt - startdt + 1;
  FORMAT startdt adt DATE9.;
  KEEP usubjid paramcd param startdt adt aval cnsr evntdesc srcdom srcvar srcseq;
RUN;

PROC FREQ DATA=adtte; TABLES cnsr*evntdesc / LIST NOCUM; RUN;
