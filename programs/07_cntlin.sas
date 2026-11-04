/* Chapter 7: build a format from data and use it as a lookup */
PROC SORT DATA=refadm.adsl(KEEP=trt01pn trt01p) OUT=trt_values NODUPKEY;
  BY trt01pn;
RUN;
DATA trtfmt(KEEP=fmtname start label);
  SET trt_values;
  fmtname = "trtf";
  start   = trt01pn;
  label   = trt01p;
RUN;

PROC FORMAT CNTLIN=trtfmt;
RUN;

DATA lookup;
  SET refadm.adae(OBS=3 KEEP=usubjid trtan);
  LENGTH trt_txt $40;
  trt_txt = PUT(trtan, trtf.);
RUN;

PROC PRINT DATA=trtfmt NOOBS; RUN;
PROC PRINT DATA=lookup NOOBS; RUN;
