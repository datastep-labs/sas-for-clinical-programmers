/* Chapter 4: the same step without RETAIN */
PROC SORT DATA=sdtm.vs(WHERE=(vstestcd = "WEIGHT" AND usubjid = "01-701-1015")) OUT=wt1; BY visitnum; RUN;

DATA wt_noretain;
  SET wt1(KEEP=usubjid visit visitnum vsblfl vsstresn);
  IF vsblfl = "Y" THEN base = vsstresn;
  IF NOT MISSING(base) AND vsblfl NE "Y" THEN chg = vsstresn - base;
RUN;
