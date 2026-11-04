/* Chapter 13: p-values for a table, Fisher's exact test and an ANCOVA, captured with ODS OUTPUT */

/* Step 010: one record per subject of the safety population, any TEAE yes (1) or no (0) */
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y")) OUT=st_ae(KEEP=usubjid) NODUPKEY;
  BY usubjid;
RUN;
DATA st_subj;
  MERGE refadm.adsl(IN=insl WHERE=(saffl = "Y") KEEP=usubjid saffl trt01an)
        st_ae(IN=inae);
  BY usubjid;
  IF insl;
  IF inae THEN anyteae = 1;
  ELSE         anyteae = 0;
RUN;

/* Step 020: Fisher's exact test, treatment by any TEAE. ODS OUTPUT keeps the result as a data set */
ODS OUTPUT FishersExact=st_fisher;
PROC FREQ DATA=st_subj;
  TABLES trt01an * anyteae / NOROW NOPERCENT;
  EXACT FISHER;
RUN;
PROC PRINT DATA=st_fisher NOOBS;
RUN;

/* Step 030: ANCOVA, change from baseline in systolic BP (lying) at Week 24, baseline as covariate */
DATA st_bp;
  SET refadm.advs(WHERE=(paramcd = "SYSBP" AND atptn = 815 AND avisit = "Week 24"
                         AND NOT MISSING(chg) AND NOT MISSING(base)));
RUN;
/* PLOTS=NONE: no diagnostic graphs. They need a folder SAS can write to, and the table does not use them */
ODS OUTPUT ModelANOVA=st_anova LSMeans=st_lsm Diff=st_diff;
PROC GLM DATA=st_bp PLOTS=NONE;
  CLASS trtpn;
  MODEL chg = trtpn base / SS3;
  LSMEANS trtpn / PDIFF STDERR;
RUN;
QUIT;
PROC PRINT DATA=st_anova NOOBS;
  WHERE hypothesistype = 3;
  VAR dependent source df ss fvalue probf;
RUN;
PROC PRINT DATA=st_lsm NOOBS;
RUN;
PROC PRINT DATA=st_diff NOOBS;
RUN;

/* Step 040: a p-value row for the table, formatted the way tables show it */
DATA st_prow;
  SET st_fisher(WHERE=(name1 = "XP2_FISH"));
  LENGTH label $60 value $20;
  label = "p-value (Fisher's exact test)";
  value = STRIP(PUT(nvalue1, PVALUE6.4));
  KEEP label value nvalue1;
RUN;
PROC PRINT DATA=st_prow NOOBS;
RUN;
