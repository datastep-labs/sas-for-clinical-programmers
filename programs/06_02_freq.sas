/* Chapter 6: count with PROC FREQ */
TITLE1 "Age group (safety population)";
PROC FREQ DATA=refadm.adsl;
  WHERE saffl = "Y";
  TABLES agegr1 / NOCUM;
  TABLES trt01a * agegr1 / NOROW NOPERCENT;
RUN;

/* LIST gives one row per combination; OUT= keeps the counts as data */
TITLE1 "Treatment and sex, one row per combination";
PROC FREQ DATA=refadm.adsl;
  WHERE saffl = "Y";
  TABLES trt01a * sex / LIST NOCUM OUT=trt_sex;
RUN;

/* a missing value is not counted, unless you ask for it with MISSING */
/* VSTPT (the position) is blank for weight and temperature */
TITLE1 "Position of the BASELINE vital signs: without and with MISSING";
PROC FREQ DATA=sdtm.vs;
  WHERE visit = "BASELINE";
  TABLES vstpt / NOCUM;
  TABLES vstpt / NOCUM MISSING;
RUN;
TITLE;
