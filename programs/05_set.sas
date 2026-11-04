/* Chapter 5: SET stacks, SET with BY interleaves */
DATA more;
  INPUT usubjid $ age;
DATALINES;
S0 58
S5 80
;
RUN;

DATA stacked;
  SET dm(IN=indm) more;
  LENGTH source $4;
  IF indm THEN source = "DM";
  ELSE         source = "MORE";
RUN;

DATA interleaved;
  SET dm more;
  BY usubjid;
RUN;

PROC PRINT DATA=stacked NOOBS; RUN;
PROC PRINT DATA=interleaved NOOBS; RUN;
