/* Chapter 13: a demographics table in plain SAS: statistics, a layout data set, PROC REPORT */

/* Step 010: big N per treatment into macro variables n0, n54, n81 */
/* ADSL has one record per subject, so a count of records is a count of subjects */
PROC FREQ DATA=refadm.adsl(WHERE=(saffl = "Y")) NOPRINT;
  TABLES trt01an / OUT=bign;
RUN;
DATA _NULL_;
  SET bign;
  CALL SYMPUTX(CATS("n", trt01an), count);
RUN;

/* Step 020: age, a continuous variable: n, mean (SD), median, min and max */
PROC MEANS DATA=refadm.adsl(WHERE=(saffl = "Y")) NOPRINT NWAY;
  CLASS trt01an;
  VAR age;
  OUTPUT OUT=age_stat N=n MEAN=mean STD=sd MEDIAN=median MIN=min MAX=max;
RUN;

DATA age_rows;
  LENGTH label $40 value $20;
  SET age_stat;
  ord = 1;
  label = "  n";              value = PUT(n, 3.);                                      sub = 1; OUTPUT;
  label = "  Mean (SD)";      value = CATX(" ", PUT(mean, 5.1), CATS("(", PUT(sd, 5.2), ")")); sub = 2; OUTPUT;
  label = "  Median";         value = PUT(median, 5.1);                                sub = 3; OUTPUT;
  label = "  Min, Max";       value = CATX(", ", PUT(min, 3.), PUT(max, 3.));          sub = 4; OUTPUT;
  KEEP trt01an ord sub label value;
RUN;

/* Step 030: sex, a categorical variable: n (%) of the big N */
PROC FREQ DATA=refadm.adsl(WHERE=(saffl = "Y")) NOPRINT;
  TABLES trt01an * sex / OUT=sex_cnt;
RUN;

DATA sex_rows;
  LENGTH label $40 value $20;
  SET sex_cnt;
  ord = 2;
  IF      trt01an = 0  THEN bign = &n0.;
  ELSE IF trt01an = 54 THEN bign = &n54.;
  ELSE IF trt01an = 81 THEN bign = &n81.;
  IF sex = "F" THEN DO; label = "  Female"; sub = 1; END;
  ELSE              DO; label = "  Male";   sub = 2; END;
  value = CATX(" ", PUT(count, 3.), CATS("(", PUT(count / bign * 100, 5.1), ")"));
  KEEP trt01an ord sub label value;
RUN;

/* Step 040: the layout data set: one row per table line, one column per treatment */
DATA heads;
  LENGTH label $40;
  ord = 1; sub = 0; label = "Age (years)"; OUTPUT;
  ord = 2; sub = 0; label = "Sex, n (%)";  OUTPUT;
RUN;

DATA long;
  SET age_rows sex_rows;
RUN;
PROC SORT DATA=long; BY ord sub label; RUN;

PROC TRANSPOSE DATA=long OUT=wide(DROP=_name_) PREFIX=trt;
  BY ord sub label;
  ID trt01an;
  VAR value;
RUN;

DATA layout;
  SET heads wide;
  BY ord sub;
RUN;

/* Step 050: print */
OPTIONS LS=100 NOCENTER;
TITLE1 "Table 14.1.1 Demographics (safety population)";
PROC REPORT DATA=layout NOWD HEADLINE SPLIT="|";
  COLUMN ord sub label trt0 trt54 trt81;
  DEFINE ord   / ORDER NOPRINT;
  DEFINE sub   / ORDER NOPRINT;
  DEFINE label / DISPLAY " " WIDTH=24;
  DEFINE trt0  / DISPLAY "Placebo|(N=&n0.)"   WIDTH=14 CENTER;
  DEFINE trt54 / DISPLAY "Xanomeline|Low Dose|(N=&n54.)"  WIDTH=14 CENTER;
  DEFINE trt81 / DISPLAY "Xanomeline|High Dose|(N=&n81.)" WIDTH=14 CENTER;
RUN;
TITLE;
