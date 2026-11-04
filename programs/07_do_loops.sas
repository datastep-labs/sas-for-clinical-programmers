/* Chapter 7: DO loops and SELECT */

/* Step 010: an iterative DO: one record per day of one exposure record */
DATA ex_days;
  SET sdtm.ex(WHERE=(usubjid = "01-701-1015") KEEP=usubjid exseq exdose exstdtc exendtc);
  exstdt = INPUT(exstdtc, E8601DA.);
  exendt = INPUT(exendtc, E8601DA.);
  DO adt = exstdt TO exendt;
    OUTPUT;
  END;
  FORMAT exstdt exendt adt DATE9.;
  KEEP usubjid exseq exdose exstdt exendt adt;
RUN;

TITLE1 "01-701-1015: days per exposure record";
PROC FREQ DATA=ex_days;
  TABLES exseq * exdose / LIST NOCUM NOPERCENT;
RUN;

/* Step 020: DO WHILE tests at the top: the body can run zero times */
DATA flags;
  LENGTH list $40 flag $8;
  list = "SAFFL ITTFL EFFFL";
  i    = 1;
  flag = SCAN(list, i);
  DO WHILE (flag NE "");
    OUTPUT;
    i    = i + 1;
    flag = SCAN(list, i);
  END;
  KEEP i flag;
RUN;
TITLE1 "One record per word of the list";
PROC PRINT DATA=flags NOOBS; RUN;

/* Step 030: DO UNTIL tests at the bottom. Around SET, it reads one whole BY group per loop of the DATA step */
DATA ae_per_subject;
  n_ae = 0;
  DO UNTIL (LAST.usubjid);
    SET refadm.adae(KEEP=usubjid);
    BY usubjid;
    n_ae = n_ae + 1;
  END;
RUN;
TITLE1 "AEs per subject, the first five subjects";
PROC PRINT DATA=ae_per_subject(OBS=5) NOOBS; RUN;

/* Step 040: SELECT: one branch for each value */
DATA trt_group;
  SET refadm.adsl(KEEP=usubjid trt01pn);
  LENGTH trtgrp $10;
  SELECT (trt01pn);
    WHEN (0)      trtgrp = "Placebo";
    WHEN (54, 81) trtgrp = "Active";
    OTHERWISE     trtgrp = "Unknown";
  END;
RUN;
TITLE1 "Placebo against active";
PROC FREQ DATA=trt_group;
  TABLES trtgrp / NOCUM;
RUN;
TITLE;
