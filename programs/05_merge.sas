/* Chapter 5: MERGE with IN= flags */
DATA all match dm_only;
  MERGE dm(IN=indm) ae(IN=inae);
  BY usubjid;
  OUTPUT all;
  IF indm AND inae THEN OUTPUT match;
  IF indm AND NOT inae THEN OUTPUT dm_only;
RUN;

PROC PRINT DATA=all NOOBS; RUN;
PROC PRINT DATA=match NOOBS; RUN;
PROC PRINT DATA=dm_only NOOBS; RUN;
