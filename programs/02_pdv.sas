/* Chapter 2: watch the PDV */
DATA pdv_demo;
  LENGTH agecat $5;
  PUTLOG "TOP " _N_= age= agecat=;
  SET dm_rand(OBS=2 KEEP=usubjid age);
  IF age >= 65 THEN agecat = ">=65";
  ELSE              agecat = "<65";
  PUTLOG "END " _N_= age= agecat=;
RUN;
