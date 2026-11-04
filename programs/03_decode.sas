/* Chapter 3: take the text of a code from its format */
PROC FORMAT;
  VALUE trtn 0  = "Placebo"
             54 = "Xanomeline Low Dose"
             81 = "Xanomeline High Dose";
RUN;

DATA decode;
  SET refadm.adsl(KEEP=usubjid trt01pn WHERE=(usubjid IN ("01-701-1015" "01-701-1028" "01-701-1033")));
  LENGTH trt_txt $40;
  FORMAT trt01pn trtn.;
  IF NOT MISSING(trt01pn) THEN trt_txt = VVALUE(trt01pn);
RUN;

PROC PRINT DATA=decode NOOBS; RUN;
