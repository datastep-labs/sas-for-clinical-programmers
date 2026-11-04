/* Chapter 4: RETAIN carries the baseline value to later visits */
PROC SORT DATA=sdtm.vs(WHERE=(vstestcd = "WEIGHT" AND usubjid = "01-701-1015")) OUT=wt1;
  BY usubjid visitnum;
RUN;

DATA wt_chg;
  SET wt1(KEEP=usubjid visit visitnum vsblfl vsstresn);
  BY usubjid;
  RETAIN base;
  IF FIRST.usubjid THEN base = .;
  IF vsblfl = "Y" THEN base = vsstresn;
  IF NOT MISSING(base) AND vsblfl NE "Y" THEN chg = vsstresn - base;
RUN;

PROC PRINT DATA=wt_chg NOOBS; VAR visitnum visit vsblfl vsstresn base chg; RUN;
