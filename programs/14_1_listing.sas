/* Chapter 14: a listing of serious adverse events, by hand with PROC REPORT */

/* Step 010: the records to list, in the order to list them */
DATA sae;
  SET refadm.adae(WHERE=(saffl = "Y" AND aeser = "Y"));
  KEEP trtan trta usubjid aedecod astdt aendt aesev aeout;
RUN;
PROC SORT DATA=sae;
  BY trtan usubjid astdt aedecod;
RUN;

/* Step 020: print */
OPTIONS LS=132 PS=60 NOCENTER;
TITLE1 "Listing 16.2.7 Serious adverse events (safety population)";
PROC REPORT DATA=sae NOWD HEADLINE HEADSKIP SPLIT="|" SPACING=2;
  COLUMN trtan trta usubjid aedecod astdt aendt aesev aeout;
  DEFINE trtan   / ORDER NOPRINT;
  DEFINE trta    / ORDER   "Treatment"      WIDTH=20;
  DEFINE usubjid / ORDER   "Subject"        WIDTH=11;
  DEFINE aedecod / DISPLAY "Preferred term" WIDTH=30 FLOW;
  DEFINE astdt   / DISPLAY "Start"          WIDTH=9 FORMAT=DATE9.;
  DEFINE aendt   / DISPLAY "End"            WIDTH=9 FORMAT=DATE9.;
  DEFINE aesev   / DISPLAY "Severity"       WIDTH=8;
  DEFINE aeout   / DISPLAY "Outcome"        WIDTH=18 FLOW;
  BREAK AFTER usubjid / SKIP;
RUN;
TITLE;
