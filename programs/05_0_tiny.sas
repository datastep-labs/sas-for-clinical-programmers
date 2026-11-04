/* Chapter 5: two tiny tables to combine */
DATA dm;
  INPUT usubjid $ age;
DATALINES;
S1 63
S2 64
S3 71
S4 74
;
RUN;

DATA ae;
  INPUT usubjid $ aedecod :$12.;
DATALINES;
S2 HEADACHE
S4 DIZZINESS
S4 NAUSEA
S5 RASH
;
RUN;
