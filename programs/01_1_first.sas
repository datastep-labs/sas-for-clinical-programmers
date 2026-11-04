/* Chapter 1: a first program. Read ADSL, keep five variables, count the subjects per arm */
DATA adsl_tour;
  SET refadm.adsl(KEEP=usubjid arm age sex saffl);
RUN;

PROC FREQ DATA=adsl_tour;
  TABLES arm;
RUN;
