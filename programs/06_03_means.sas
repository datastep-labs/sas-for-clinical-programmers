/* Chapter 6: statistics with PROC MEANS, PROC SUMMARY and PROC UNIVARIATE */
TITLE1 "Age by treatment (safety population)";
PROC MEANS DATA=refadm.adsl N MEAN STD MEDIAN MIN MAX MAXDEC=1;
  WHERE saffl = "Y";
  CLASS trt01a;
  VAR age;
RUN;

/* the same statistics as data: PROC SUMMARY prints nothing, it writes OUTPUT OUT= */
PROC SUMMARY DATA=refadm.adsl NWAY;
  WHERE saffl = "Y";
  CLASS trt01an trt01a;
  VAR age;
  OUTPUT OUT=age_stats(DROP=_type_ _freq_) N=n MEAN=mean STD=sd MEDIAN=median MIN=min MAX=max;
RUN;
TITLE1 "AGE_STATS: one record per treatment";
PROC PRINT DATA=age_stats NOOBS;
  FORMAT mean sd median 5.1;
RUN;

/* BY instead of CLASS: the data must be sorted, and SAS prints one table per group */
PROC SORT DATA=refadm.adsl(WHERE=(saffl = "Y")) OUT=adsl_saf;
  BY trt01an;
RUN;
TITLE1 "Age with BY: one table per treatment";
PROC MEANS DATA=adsl_saf N MEAN MAXDEC=1;
  BY trt01an;
  VAR age;
RUN;

/* a quick look at one variable: the basic measures and the extreme values */
TITLE1 "Baseline weight (kg): a quick look";
ODS SELECT BasicMeasures ExtremeObs;
PROC UNIVARIATE DATA=refadm.adsl NEXTROBS=3;
  WHERE saffl = "Y";
  VAR weightbl;
  ID usubjid;
RUN;
TITLE;
