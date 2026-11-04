/* Chapter 1: sort, then read in groups. The oldest subject of each arm */
PROC SORT DATA=refadm.adsl(KEEP=usubjid arm age) OUT=adsl_sorted;
  BY arm DESCENDING age usubjid;
RUN;

DATA oldest;
  SET adsl_sorted;
  BY arm;
  IF FIRST.arm;
RUN;

PROC PRINT DATA=oldest NOOBS;
RUN;
