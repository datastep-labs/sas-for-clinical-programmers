/* Chapter 13: a time-to-event table: events, Kaplan-Meier median, log-rank test and hazard ratios (needs ADTTE_ALL from 12_2) */

/* Step 010: the parameter, with the treatment of each subject from ADSL */
DATA tte_010;
  MERGE adtte_all(IN=intte WHERE=(paramcd = "TTDE") KEEP=usubjid paramcd aval cnsr)
        refadm.adsl(IN=inadsl KEEP=usubjid trt01an trt01a RENAME=(trt01an=trtan trt01a=trta));
  BY usubjid;
  IF intte AND inadsl;
  DROP paramcd;
RUN;
PROC SORT DATA=tte_010;
  BY trtan usubjid;
RUN;

/* Step 020: subjects, events and censored subjects per treatment */
DATA tte_020(KEEP=trtan n nevent ncens);
  SET tte_010;
  BY trtan;
  IF FIRST.trtan THEN DO;
    n = 0; nevent = 0; ncens = 0;
  END;
  n      + 1;
  nevent + (cnsr = 0);
  ncens  + (cnsr = 1);
  IF LAST.trtan;
RUN;

/* Step 030: Kaplan-Meier quartiles and the log-rank test */
ODS SELECT NONE;
ODS OUTPUT Quartiles=tte_q HomTests=tte_lr;
PROC LIFETEST DATA=tte_010 PLOTS=NONE;
  TIME aval * cnsr(1);
  STRATA trtan / TEST=LOGRANK;
RUN;
ODS SELECT ALL;

/* Step 040: hazard ratio of each Xanomeline arm against placebo (Cox model) */
ODS SELECT NONE;
ODS OUTPUT ParameterEstimates=tte_hr;
PROC PHREG DATA=tte_010 PLOTS=NONE;
  CLASS trtan(REF="0") / PARAM=REF;
  MODEL aval * cnsr(1) = trtan / TIES=EFRON RL;
RUN;
ODS SELECT ALL;

PROC PRINT DATA=tte_q NOOBS; VAR stratum trtan percent estimate lowerlimit upperlimit; RUN;
PROC PRINT DATA=tte_lr NOOBS; RUN;
PROC PRINT DATA=tte_hr NOOBS; VAR parameter classval0 hazardratio hrlowercl hruppercl probchisq; RUN;

/* Step 050: one text per row and treatment, in the row layout of 13.4 */
DATA tte_050;
  LENGTH label $50 value $30;
  /* data set options run in this order: KEEP=, RENAME=, then WHERE= (so WHERE= sees the new names) */
  MERGE tte_020
        tte_q(KEEP=trtan percent estimate lowerlimit upperlimit WHERE=(percent = 50)
              RENAME=(estimate=med lowerlimit=medlo upperlimit=medhi))
        tte_q(KEEP=trtan percent estimate WHERE=(percent = 25) RENAME=(estimate=q1))
        tte_q(KEEP=trtan percent estimate WHERE=(percent = 75) RENAME=(estimate=q3));
  BY trtan;
  ord = 1; label = "Subjects";                         value = PUT(n, 3.);                                             OUTPUT;
  ord = 2; label = "Subjects with event, n (%)";       value = CATX(" ", PUT(nevent, 3.), CATS("(", PUT(nevent / n * 100, 5.1), ")")); OUTPUT;
  ord = 3; label = "Censored, n (%)";                  value = CATX(" ", PUT(ncens, 3.), CATS("(", PUT(ncens / n * 100, 5.1), ")"));   OUTPUT;
  ord = 4; label = "Median time to event, days";
  /* more than half of the subjects without an event: the median is not reached */
  IF MISSING(med) THEN value = "Not reached";
  ELSE value = STRIP(PUT(med, 5.));
  OUTPUT;
  ord = 5; label = "  95% CI";
  IF MISSING(medlo) THEN value = "-";
  ELSE value = CATS("(", CATX(", ", PUT(medlo, 5.), IFC(MISSING(medhi), "NE", PUT(medhi, 5.))), ")");
  OUTPUT;
  ord = 6; label = "25th, 75th percentile";
  value = CATX(", ", IFC(MISSING(q1), "NE", STRIP(PUT(q1, 5.))), IFC(MISSING(q3), "NE", STRIP(PUT(q3, 5.))));
  OUTPUT;
  KEEP trtan ord label value;
RUN;

/* the hazard ratio rows: placebo is the reference, so its cells stay empty */
DATA tte_051;
  LENGTH label $50 value $30;
  SET tte_hr;
  trtan = INPUT(classval0, 8.);
  ord = 7; label = "Hazard ratio vs placebo (95% CI)";
  value = CATX(" ", PUT(hazardratio, 5.2), CATS("(", CATX(", ", PUT(hrlowercl, 5.2), PUT(hruppercl, 5.2)), ")"));
  OUTPUT;
  ord = 8; label = "  p-value (Cox model)";
  value = STRIP(PUT(probchisq, PVALUE6.4));
  OUTPUT;
  KEEP trtan ord label value;
RUN;

/* Step 060: one column per treatment */
DATA tte_060;
  SET tte_050 tte_051;
RUN;
PROC SORT DATA=tte_060; BY ord label trtan; RUN;
PROC TRANSPOSE DATA=tte_060 OUT=tte_rows(DROP=_name_) PREFIX=c;
  BY ord label;
  ID trtan;
  VAR value;
RUN;

/* the log-rank p-value (all three arms) and the big N go into the titles */
DATA _NULL_;
  SET tte_lr;
  CALL SYMPUTX("p_lr", PUT(probchisq, PVALUE6.4));
RUN;
DATA _NULL_;
  SET tte_020;
  CALL SYMPUTX(CATS("n", trtan), n);
RUN;

/* Step 070: the table */
TITLE1 "Time to first dermatologic event (safety population)";
TITLE2 "Log-rank test across the three treatments: p = &p_lr.";
PROC REPORT DATA=tte_rows NOWD HEADLINE SPLIT="|" MISSING;
  COLUMN ord label c0 c54 c81;
  DEFINE ord   / ORDER NOPRINT;
  DEFINE label / DISPLAY " " WIDTH=34;
  DEFINE c0    / DISPLAY "Placebo|(N=&n0.)"              WIDTH=16;
  DEFINE c54   / DISPLAY "Xanomeline Low Dose|(N=&n54.)"  WIDTH=20;
  DEFINE c81   / DISPLAY "Xanomeline High Dose|(N=&n81.)" WIDTH=20;
RUN;
TITLE;
