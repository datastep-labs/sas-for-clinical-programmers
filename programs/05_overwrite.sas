/* Chapter 5: the same variable in both data sets: the last one wins */
DATA dm_new;
  INPUT usubjid $ age;
DATALINES;
S2 65
S3 72
;
RUN;

DATA overwritten;
  MERGE dm dm_new;
  BY usubjid;
RUN;

PROC PRINT DATA=overwritten NOOBS; RUN;
