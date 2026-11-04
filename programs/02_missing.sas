/* Chapter 2: a missing number is smaller than every number */
DATA bp;
  LENGTH bpcat $7;
  SET sdtm.vs(KEEP=usubjid vstestcd visit vsstresn);
  WHERE vstestcd = "SYSBP";
  IF vsstresn < 140 THEN bpcat = "normal";
  ELSE                   bpcat = "high";
RUN;

PROC PRINT DATA=bp NOOBS;
  WHERE MISSING(vsstresn);
  VAR usubjid visit vsstresn bpcat;
RUN;

/* the fix: test for a missing value first */
DATA bp_fixed;
  SET bp;
  IF      MISSING(vsstresn) THEN bpcat = "missing";
  ELSE IF vsstresn < 140    THEN bpcat = "normal";
  ELSE                           bpcat = "high";
RUN;

PROC FREQ DATA=bp_fixed;
  TABLES bpcat / NOCUM;
RUN;
