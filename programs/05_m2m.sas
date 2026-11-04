/* EXPECT: NOTE MERGE statement has more than one data set with repeats of BY values */
/* Chapter 5: many records on both sides: MERGE does not do what you expect */
DATA cm;
  INPUT usubjid $ cmdecod :$12.;
DATALINES;
S4 ASPIRIN
S4 PARACETAMOL
S4 IBUPROFEN
;
RUN;

DATA m2m;
  MERGE ae(WHERE=(usubjid = "S4")) cm;
  BY usubjid;
RUN;

PROC PRINT DATA=m2m NOOBS; RUN;
