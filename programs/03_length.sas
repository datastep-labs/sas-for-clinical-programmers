/* Chapter 3: the first use of a variable sets its length */
DATA trap;
  SET refadm.adsl(OBS=3 KEEP=usubjid age);
  IF age < 65 THEN agegrp = "<65";
  ELSE             agegrp = "65 or older";
RUN;

PROC PRINT DATA=trap NOOBS; RUN;
