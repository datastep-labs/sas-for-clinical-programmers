/* Chapter 15: compare production with QC */
PROC COMPARE BASE=prod COMPARE=qc;
  ID usubjid;
RUN;
%PUT NOTE: SYSINFO after the compare = &SYSINFO.;

/* A QC program with one mistake: age 65 goes into the wrong group */
DATA qc_bad;
  SET qc;
  IF age = 65 THEN agegr1 = "<65";
RUN;

PROC COMPARE BASE=prod COMPARE=qc_bad MAXPRINT=10;
  ID usubjid;
  VAR agegr1;
RUN;
%PUT NOTE: SYSINFO after the second compare = &SYSINFO.;

/* Our production against the CDISC reference ADSL */
PROC COMPARE BASE=refadm.adsl(KEEP=usubjid agegr1 trtsdt trtedt trtdur)
             COMPARE=prod(RENAME=(trtdurd=trtdur)) MAXPRINT=10;
  ID usubjid;
  VAR agegr1 trtsdt trtedt trtdur;
RUN;
