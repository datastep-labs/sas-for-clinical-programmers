/* Chapter 11: ADAE by hand (needs ADSL from chapter 9) */

/* Step 010: every AE with the treatment and dates of the subject */
DATA adae_010;
  MERGE sdtm.ae(IN=inae KEEP=usubjid aeseq aeterm aedecod aebodsys aesev aeser aestdtc aeendtc)
        adsl(KEEP=usubjid trtsdt trtedt trt01a trt01an RENAME=(trt01a=trta trt01an=trtan));
  BY usubjid;
  IF inae;
RUN;

/* Step 020: start date imputed early (a missing day only), end date as collected */
DATA adae_020;
  LENGTH astdtf $1;
  SET adae_010;
  yy = INPUT(SUBSTR(aestdtc, 1, 4), ?? 4.);
  IF LENGTH(aestdtc) >= 7 THEN mm = INPUT(SUBSTR(aestdtc, 6, 2), ?? 2.);
  IF LENGTH(aestdtc) = 10 THEN DO;
    astdt  = INPUT(aestdtc, ?? E8601DA.);
    astdtf = "";
  END;
  ELSE IF NOT MISSING(mm) THEN DO;
    astdt  = MDY(mm, 1, yy);
    astdtf = "D";
  END;
  /* a start with the year only stays missing: the SAP imputes a missing day, not a missing month */
  /* an imputed start before the first dose, in the month of the first dose, moves to the first dose */
  IF astdtf = "D" AND astdt < trtsdt AND YEAR(astdt) = YEAR(trtsdt) AND MONTH(astdt) = MONTH(trtsdt) THEN astdt = trtsdt;
  aendt = INPUT(aeendtc, ?? E8601DA.);
  FORMAT astdt aendt DATE9.;
  DROP yy mm;
RUN;

/* Step 030: treatment emergent: starts on or after the first dose */
DATA adae_030;
  LENGTH trtemfl $1;
  SET adae_020;
  IF NOT MISSING(astdt) AND astdt >= trtsdt THEN trtemfl = "Y";
  ELSE                                           trtemfl = "N";
RUN;

/* Step 040: first occurrence flags among the treatment emergent events */
PROC SORT DATA=adae_030; BY usubjid trtemfl astdt aeseq; RUN;

DATA adae_040;
  SET adae_030;
  BY usubjid trtemfl;
  LENGTH aoccfl $1;
  IF trtemfl = "Y" AND FIRST.trtemfl THEN aoccfl = "Y";
  ELSE                                    aoccfl = "";
RUN;

PROC SORT DATA=adae_040; BY usubjid trtemfl aedecod astdt aeseq; RUN;

DATA adae;
  SET adae_040;
  BY usubjid trtemfl aedecod;
  LENGTH aoccpfl $1;
  IF trtemfl = "Y" AND FIRST.aedecod THEN aoccpfl = "Y";
  ELSE                                    aoccpfl = "";
RUN;

PROC SORT DATA=adae; BY usubjid aeseq; RUN;

PROC FREQ DATA=adae; TABLES astdtf trtemfl / MISSING NOCUM; RUN;
