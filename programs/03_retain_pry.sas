/* Needs DataStep Studio: %pry is a DataStep Studio command, plain SAS does not know it */
/* Chapter 3: RETAIN carries the baseline to later visits */
PROC SORT DATA=sdtm.vs(WHERE=(vstestcd = "WEIGHT")) OUT=wt; BY usubjid visitnum; RUN;

DATA wt_chg;
  SET wt;
  BY usubjid;
  RETAIN base;
  IF FIRST.usubjid THEN base = .;
  IF vsblfl = "Y" THEN base = vsstresn;
  %pry(when=usubjid = "01-701-1015")
  IF NOT MISSING(base) AND vsblfl NE "Y" THEN chg = vsstresn - base;
RUN;
