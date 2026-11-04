/* Chapter 3: PUT makes text, INPUT makes numbers */
DATA conv;
  SET sdtm.dm(OBS=3 KEEP=usubjid siteid age);
  LENGTH age_c $3 subj $4 txt $30;
  site_n = INPUT(siteid, 8.);
  age_c  = PUT(age, 3.);
  subj   = SCAN(usubjid, 3, "-");
  txt    = CATX(" / ", usubjid, age_c);
RUN;

PROC PRINT DATA=conv NOOBS; RUN;
PROC CONTENTS DATA=conv VARNUM SHORT; RUN;
