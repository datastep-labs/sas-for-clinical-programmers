/* Chapter 3: the text functions you use every day, on the adverse events of SDTM */
DATA ae_text;
  LENGTH site $3 subj $4 short $200 label $250;
  SET sdtm.ae(KEEP=usubjid aeterm aedecod);
  site     = SCAN(usubjid, 2, "-");
  subj     = SUBSTR(usubjid, 8, 4);
  has_pain = (FIND(aedecod, "pain", "i") > 0);
  short    = TRANWRD(aedecod, "APPLICATION SITE", "APPL. SITE");
  digits   = INPUT(COMPRESS(usubjid, , "kd"), 9.);
  label    = CATX(" | ", usubjid, aedecod);
RUN;

PROC FREQ DATA=ae_text;
  TABLES has_pain / NOCUM;
RUN;

PROC PRINT DATA=ae_text(OBS=3) NOOBS;
  VAR usubjid site subj digits short label;
RUN;
