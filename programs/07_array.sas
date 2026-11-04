/* Chapter 7: one loop instead of four IF statements */
DATA flags;
  SET refadm.adsl(KEEP=usubjid saffl ittfl efffl comp24fl);
  ARRAY fl{*}  saffl ittfl efffl comp24fl;
  ARRAY nfl{*} saffn ittfn efffn comp24fn;
  DO i = 1 TO DIM(fl);
    IF      fl{i} = "Y" THEN nfl{i} = 1;
    ELSE IF fl{i} = "N" THEN nfl{i} = 0;
  END;
  DROP i;
RUN;

PROC MEANS DATA=flags SUM MAXDEC=0;
  VAR saffn ittfn efffn comp24fn;
RUN;
