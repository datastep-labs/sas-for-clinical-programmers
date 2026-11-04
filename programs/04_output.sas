/* Chapter 4: one pass, two output data sets */
DATA ae_ser ae_nonser;
  SET sdtm.ae(KEEP=usubjid aedecod aeser);
  IF aeser = "Y" THEN OUTPUT ae_ser;
  ELSE                OUTPUT ae_nonser;
RUN;
