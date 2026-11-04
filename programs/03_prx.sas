/* Chapter 3: a regular expression sorts ISO 8601 dates by how complete they are */
DATA ae_dtc;
  LENGTH dtc_type $10;
  SET sdtm.ae(KEEP=usubjid aeseq aestdtc);
  IF      PRXMATCH("/^\d{4}-\d{2}-\d{2}/", aestdtc)    THEN dtc_type = "complete";
  ELSE IF PRXMATCH("/^\d{4}-\d{2}$/", STRIP(aestdtc))  THEN dtc_type = "year-month";
  ELSE IF PRXMATCH("/^\d{4}$/", STRIP(aestdtc))        THEN dtc_type = "year";
  ELSE                                                      dtc_type = "missing";
RUN;

PROC FREQ DATA=ae_dtc;
  TABLES dtc_type / NOCUM;
RUN;
