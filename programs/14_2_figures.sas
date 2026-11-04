/* Chapter 14: two figures: mean weight change by visit, and a Kaplan-Meier plot (needs ADTTE_ALL from 12_2) */

/* graphs go to the WORK folder: every reader can write there */
ODS LISTING GPATH="%SYSFUNC(PATHNAME(WORK))";

/* Mean change from baseline in weight, by treatment and visit */
PROC MEANS DATA=refadm.advs(WHERE=(paramcd = "WEIGHT" AND anl01fl = "Y" AND 2 <= avisitn <= 26))
           NOPRINT NWAY;
  CLASS trtan trtp avisitn;
  VAR chg;
  OUTPUT OUT=chg_mean MEAN=mean STDERR=se N=n;
RUN;

DATA chg_plot;
  SET chg_mean;
  lo = mean - se;
  hi = mean + se;
RUN;

PROC PRINT DATA=chg_plot(WHERE=(avisitn = 24)) NOOBS;
  VAR trtp avisitn n mean se;
  FORMAT mean se 6.2;
RUN;

ODS GRAPHICS ON / WIDTH=16CM HEIGHT=10CM;
TITLE1 "Mean change from baseline in weight (kg), mean and standard error";
PROC SGPLOT DATA=chg_plot;
  SERIES  X=avisitn Y=mean / GROUP=trtp MARKERS;
  SCATTER X=avisitn Y=mean / GROUP=trtp YERRORLOWER=lo YERRORUPPER=hi;
  REFLINE 0 / AXIS=Y;
  XAXIS LABEL="Week" VALUES=(2 4 6 8 12 16 20 24 26);
  YAXIS LABEL="Change from baseline (kg)";
RUN;

/* Time to first dermatologic event: Kaplan-Meier estimate by treatment, from your ADTTE of chapter 12 */
DATA km_010;
  MERGE adtte_all(IN=intte WHERE=(paramcd = "TTDE") KEEP=usubjid paramcd aval cnsr)
        refadm.adsl(IN=inadsl KEEP=usubjid trt01an RENAME=(trt01an=trtan));
  BY usubjid;
  IF intte AND inadsl;
  LABEL aval = "Analysis Value" trtan = "Actual Treatment (N)";
  DROP paramcd;
RUN;

TITLE1 "Time to first dermatologic event";
ODS SELECT CensoredSummary Quartiles SurvivalPlot;
ODS OUTPUT Quartiles=km_q CensoredSummary=km_c;
PROC LIFETEST DATA=km_010 PLOTS=SURVIVAL(ATRISK=0 to 210 by 30);
  TIME aval * cnsr(1);
  STRATA trtan;
RUN;
ODS SELECT ALL;
TITLE;

PROC PRINT DATA=km_q(WHERE=(percent = 50)) NOOBS; RUN;
