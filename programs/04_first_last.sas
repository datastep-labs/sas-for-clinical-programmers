/* Chapter 4: FIRST. and LAST. count the AEs of each subject */
PROC SORT DATA=sdtm.ae(KEEP=usubjid aedecod aestdtc
                       WHERE=(usubjid IN ("01-701-1015" "01-701-1023")))
          OUT=ae2;
  BY usubjid aestdtc;
RUN;

DATA ae_count;
  SET ae2;
  BY usubjid;
  IF FIRST.usubjid THEN n_ae = 0;
  n_ae + 1;
  IF LAST.usubjid THEN OUTPUT;
RUN;
