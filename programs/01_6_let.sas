/* Chapter 1: a macro variable holds text that you write once and use many times */
%LET arm = Placebo;

TITLE "Age of the subjects on &arm.";
PROC MEANS DATA=refadm.adsl N MEAN MIN MAX MAXDEC=1;
  WHERE arm = "&arm.";
  VAR age;
RUN;
TITLE;
