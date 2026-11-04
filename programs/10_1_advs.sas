/* Chapter 10: ADVS for body weight by hand (needs ADSL from chapter 9) */

/* Step 010: one record per weight measurement, with a date and a study day */
DATA advs_010;
  LENGTH paramcd $8 param $40;
  MERGE sdtm.vs(IN=invs WHERE=(vstestcd = "WEIGHT")
                KEEP=usubjid vsseq vstestcd visitnum visit vsdtc vsstresn)
        adsl(IN=inadsl KEEP=usubjid trtsdt trt01p trt01pn);
  BY usubjid;
  IF invs AND inadsl;
  paramcd = "WEIGHT";
  param   = "Weight (kg)";
  aval    = vsstresn;
  adt     = INPUT(vsdtc, ?? E8601DA.);
  /* no day 0: the first day of treatment is day 1, the day before is day -1 */
  IF      adt >= trtsdt        THEN ady = adt - trtsdt + 1;
  ELSE IF NOT MISSING(adt)     THEN ady = adt - trtsdt;
  FORMAT adt DATE9.;
RUN;

/* Step 020: the analysis visit is the visit as collected (nominal visit) */
DATA advs_020;
  LENGTH avisit $20 ablfl $1;
  SET advs_010;
  IF visit = "BASELINE" THEN DO;
    avisit  = "Baseline";
    avisitn = 0;
    ablfl   = "Y";
  END;
  ELSE IF SCAN(visit, 1) = "WEEK" THEN DO;
    avisitn = INPUT(SCAN(visit, 2), ?? 8.);
    avisit  = CATX(" ", "Week", avisitn);
    ablfl   = "";
  END;
  ELSE ablfl = "";
RUN;

/* Step 030: BASE on every record of the subject, then CHG and PCHG */
DATA advs_bl(KEEP=usubjid base);
  SET advs_020;
  WHERE ablfl = "Y";
  base = aval;
RUN;
DATA advs_030;
  MERGE advs_020 advs_bl;
  BY usubjid;
RUN;
PROC SORT DATA=advs_030;
  BY usubjid adt vsseq;
RUN;

DATA advs_040;
  SET advs_030;
  IF NOT MISSING(aval) AND NOT MISSING(base) THEN DO;
    chg = aval - base;
    IF base NE 0 THEN pchg = chg / base * 100;
  END;
RUN;

/* Step 050: one analysis record per visit (the last one if a visit has two) */
PROC SORT DATA=advs_040; BY usubjid avisitn adt vsseq; RUN;

DATA advs;
  SET advs_040;
  BY usubjid avisitn;
  LENGTH anl01fl $1;
  IF NOT MISSING(avisitn) AND LAST.avisitn THEN anl01fl = "Y";
  ELSE                                           anl01fl = "";
RUN;

PROC SORT DATA=advs; BY usubjid adt vsseq; RUN;
