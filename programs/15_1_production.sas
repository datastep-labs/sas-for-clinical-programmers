/* Chapter 15: production version of four ADSL variables */
PROC SORT DATA=sdtm.ex(KEEP=usubjid exstdtc exendtc) OUT=ex; BY usubjid exstdtc; RUN;

DATA prod_trt(KEEP=usubjid trtsdt trtedt);
  SET ex;
  BY usubjid;
  RETAIN trtsdt trtedt;
  IF FIRST.usubjid THEN DO;
    trtsdt = INPUT(exstdtc, ?? E8601DA.);
    trtedt = .;
  END;
  IF NOT MISSING(exendtc) THEN trtedt = MAX(trtedt, INPUT(exendtc, ?? E8601DA.));
  IF LAST.usubjid THEN OUTPUT;
  FORMAT trtsdt trtedt DATE9.;
RUN;

DATA prod;
  MERGE sdtm.dm(IN=indm KEEP=usubjid age armcd WHERE=(armcd NE "Scrnfail")) prod_trt;
  BY usubjid;
  IF indm;
  LENGTH agegr1 $5;
  IF      MISSING(age) THEN agegr1 = "";
  ELSE IF age < 65     THEN agegr1 = "<65";
  ELSE IF age <= 80    THEN agegr1 = "65-80";
  ELSE                      agegr1 = ">80";
  IF NOT MISSING(trtsdt) AND NOT MISSING(trtedt) THEN trtdurd = trtedt - trtsdt + 1;
  DROP armcd;
RUN;
