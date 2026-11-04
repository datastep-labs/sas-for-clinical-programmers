/* Chapter 11: the ADAE dates again, with %m_iso_dt from chapter 9 (needs 09_1, 09_3 and 11_1) */

/* Step 010: the mechanism is the macro: text date to SAS date, a missing day imputed early */
%m_iso_dt(data=adae_010, out=adae_m010, dtc=aestdtc, dt=astdt, impute=FIRST, flag=astdtf)
%m_iso_dt(data=adae_m010, out=adae_m020, dtc=aeendtc, dt=aendt)

/* Step 020: the study rule stays in the program, where a reviewer reads it:     */
/* an imputed start before the first dose, in the month of the first dose,       */
/* moves to the first dose                                                       */
DATA adae_m030;
  LENGTH trtemfl $1;
  SET adae_m020;
  IF astdtf = "D" AND astdt < trtsdt AND YEAR(astdt) = YEAR(trtsdt) AND MONTH(astdt) = MONTH(trtsdt) THEN astdt = trtsdt;
  IF NOT MISSING(astdt) AND astdt >= trtsdt THEN trtemfl = "Y";
  ELSE                                           trtemfl = "N";
RUN;

/* Use the part of the date you know: before any rule for unknown starts,  */
/* compare the known year (and month) of the start with the first dose     */
DATA adae_known;
  SET adae;
  LENGTH precision $5 decided $24;
  yy = INPUT(SUBSTR(aestdtc, 1, 4), ?? 4.);
  IF LENGTHN(aestdtc) >= 7 THEN mm = INPUT(SUBSTR(aestdtc, 6, 2), ?? 2.);
  IF      LENGTHN(aestdtc) = 10 THEN precision = "day";
  ELSE IF NOT MISSING(mm)       THEN precision = "month";
  ELSE IF NOT MISSING(yy)       THEN precision = "year";
  ELSE                               precision = "none";
  /* months counted from year 0, so that one comparison covers year and month */
  IF      precision = "day"   THEN decided = "full date";
  ELSE IF MISSING(trtsdt)     THEN decided = "no first dose";
  ELSE IF precision = "month" THEN DO;
    IF      yy * 12 + mm < YEAR(trtsdt) * 12 + MONTH(trtsdt) THEN decided = "before the first dose";
    ELSE IF yy * 12 + mm > YEAR(trtsdt) * 12 + MONTH(trtsdt) THEN decided = "after the first dose";
    ELSE                                                          decided = "same month: SAP rule";
  END;
  ELSE IF precision = "year" THEN DO;
    IF      yy < YEAR(trtsdt) THEN decided = "before the first dose";
    ELSE IF yy > YEAR(trtsdt) THEN decided = "after the first dose";
    ELSE                           decided = "same year: SAP rule";
  END;
  ELSE decided = "no date: SAP rule";
  DROP yy mm;
RUN;

PROC FREQ DATA=adae_known;
  WHERE precision NE "day";
  TABLES precision * decided * trtemfl / LIST NOCUM NOPERCENT;
  TITLE "Partial start dates: what the known part decides";
RUN;
TITLE;

DATA year_only;
  SET adae_known;
  WHERE precision = "year";
  start_year = INPUT(SUBSTR(aestdtc, 1, 4), 4.);
  dose_year  = YEAR(trtsdt);
RUN;
TITLE "Year-only starts against the first dose";
PROC MEANS DATA=year_only N MIN MAX MAXDEC=0;
  VAR start_year dose_year;
RUN;
TITLE;
