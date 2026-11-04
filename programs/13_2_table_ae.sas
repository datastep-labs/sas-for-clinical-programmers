/* Chapter 13: treatment emergent adverse events by system organ class and preferred term, by hand */

/* Step 010: the big N of each column, from ADSL, into a data set and into macro variables n0 n54 n81 */
/* ADSL has one record per subject, so a count of records is a count of subjects */
PROC FREQ DATA=refadm.adsl(WHERE=(saffl = "Y")) NOPRINT;
  TABLES trt01an / OUT=ae_bign(KEEP=trt01an count RENAME=(trt01an=trtan count=bign));
RUN;
DATA _NULL_;
  SET ae_bign;
  CALL SYMPUTX(CATS("n", trtan), bign);
RUN;

/* Step 020: the treatment emergent events of the safety population */
DATA teae;
  SET refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y"));
  KEEP usubjid trtan aebodsys aedecod;
RUN;

/* Step 030: count subjects, not records: keep one record per subject and line, then count */
PROC SORT DATA=teae OUT=any_subj NODUPKEY; BY trtan usubjid; RUN;
PROC SORT DATA=teae OUT=soc_subj NODUPKEY; BY aebodsys trtan usubjid; RUN;
PROC SORT DATA=teae OUT=pt_subj  NODUPKEY; BY aebodsys aedecod trtan usubjid; RUN;

PROC FREQ DATA=any_subj NOPRINT; TABLES trtan / OUT=ae_any; RUN;
PROC FREQ DATA=soc_subj NOPRINT; TABLES aebodsys * trtan / OUT=ae_soc; RUN;
PROC FREQ DATA=pt_subj  NOPRINT; TABLES aebodsys * aedecod * trtan / OUT=ae_pt; RUN;

DATA ae_cnt;
  LENGTH aebodsys aedecod $200;
  SET ae_any(IN=in0) ae_soc(IN=in1) ae_pt(IN=in2);
  IF      in0 THEN level = 0;
  ELSE IF in1 THEN level = 1;
  ELSE             level = 2;
  n = count;
  KEEP level aebodsys aedecod trtan n;
RUN;

/* Step 040: every line of the table in every column, with 0 where nobody had the event */
PROC SORT DATA=ae_cnt OUT=ae_lines(KEEP=level aebodsys aedecod) NODUPKEY;
  BY aebodsys level aedecod;
RUN;
DATA ae_grid;
  RETAIN level aebodsys aedecod trtan bign;
  SET ae_lines;
  DO i = 1 TO ncol;                                /* each line once with each column */
    SET ae_bign POINT=i NOBS=ncol;
    OUTPUT;
  END;
  DROP i;
RUN;
PROC SORT DATA=ae_cnt;
  BY aebodsys level aedecod trtan;
RUN;
DATA ae_grid;
  MERGE ae_grid ae_cnt;
  BY aebodsys level aedecod trtan;
  IF MISSING(n) THEN n = 0;
  LABEL bign = " ";                                 /* no label from PROC FREQ */
RUN;

/* Step 050: the text of each cell and of each row label */
DATA ae_text;
  LENGTH label $200 value $20;
  SET ae_grid;
  IF      level = 0 THEN label = "Subjects with at least one TEAE";
  ELSE IF level = 1 THEN label = aebodsys;
  ELSE                   label = CAT("  ", STRIP(aedecod));  /* STRIP: CAT keeps trailing blanks */
  IF n = 0 THEN value = "0";
  ELSE value = CATX(" ", PUT(n, 4.), CATS("(", PUT(n / bign * 100, 5.1), ")"));
RUN;

/* Step 060: one column per treatment */
PROC TRANSPOSE DATA=ae_text OUT=ae_layout(DROP=_name_) PREFIX=c;
  BY aebodsys level aedecod label;
  ID trtan;
  VAR value;
RUN;

/* Step 070: print */
OPTIONS LS=132 PS=60 NOCENTER;
TITLE1 "Table 14.3.1 Treatment emergent adverse events by system organ class and preferred term";
TITLE2 "Safety population. Subjects are counted once per line.";
/* MISSING: the overall line and the SOC lines have an empty aedecod; without it PROC REPORT drops them */
PROC REPORT DATA=ae_layout NOWD HEADLINE SPLIT="|" MISSING;
  COLUMN aebodsys level aedecod label c0 c54 c81;
  DEFINE aebodsys / ORDER NOPRINT;
  DEFINE level    / ORDER NOPRINT;
  DEFINE aedecod  / ORDER NOPRINT;
  DEFINE label    / DISPLAY "System organ class|  Preferred term" WIDTH=50 FLOW;
  DEFINE c0       / DISPLAY "Placebo|(N=&n0.)"                   WIDTH=20 CENTER;
  DEFINE c54      / DISPLAY "Xanomeline Low Dose|(N=&n54.)"      WIDTH=20 CENTER;
  DEFINE c81      / DISPLAY "Xanomeline High Dose|(N=&n81.)"     WIDTH=20 CENTER;
  COMPUTE AFTER aebodsys;
    LINE " ";
  ENDCOMP;
RUN;
TITLE;
