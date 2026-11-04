/*******************************************************************************
  Program     : 16_2_derive.sas
  Purpose     : Date of last exposure to treatment (TRTEDT) for ADSL
  Input       : sdtm.ex, sdtm.dm
  Output      : work.trt_final (one record per dosed subject)
  Rule        : TRTEDT = end date of the last EX record. When that end date is
                missing, the subject was still dosed at the end of the study:
                use RFENDTC from DM (rule agreed with the statistician, the
                same rule as chapter 9).
  Change log  :
    2026-10-31  1.0  first version
    2026-10-31  1.1  decision data trt_020 keeps the source of each date
    2026-11-02  1.2  an open last record ends at RFENDTC, proof against ADSL
*******************************************************************************/

/* Step 010: the last EX record of each subject, with the end of study from DM */
PROC SORT DATA=sdtm.ex(KEEP=usubjid exseq exstdtc exendtc) OUT=trt_010;
  BY usubjid exstdtc exseq;
RUN;

PROC SORT DATA=sdtm.dm(KEEP=usubjid rfendtc) OUT=trt_dm;
  BY usubjid;
RUN;

DATA trt_010;
  MERGE trt_010(IN=inex) trt_dm;
  BY usubjid;
  IF inex AND LAST.usubjid;
RUN;

/* Step 020: decision data, which date and why */
DATA trt_020;
  SET trt_010;
  LENGTH trtedtc $10 trtesrc $7;
  IF NOT MISSING(exendtc) THEN DO;
    trtedtc = SUBSTR(exendtc, 1, 10);
    trtesrc = "EXENDTC";
  END;
  ELSE DO;
    trtedtc = SUBSTR(rfendtc, 1, 10);
    trtesrc = "RFENDTC";
  END;
RUN;

/* Step 030: computation only, no decisions */
DATA trt_final(KEEP=usubjid trtedt trtesrc);
  SET trt_020;
  trtedt = INPUT(trtedtc, ?? E8601DA.);
  FORMAT trtedt DATE9.;
RUN;

PROC FREQ DATA=trt_final;
  TABLES trtesrc / NOCUM;
RUN;

/* Proof: the same TRTEDT as the reference ADSL */
PROC SORT DATA=refadm.adsl(KEEP=usubjid trtedt) OUT=trt_ref;
  BY usubjid;
RUN;

PROC COMPARE BASE=trt_ref COMPARE=trt_final NOSUMMARY;
  ID usubjid;
  VAR trtedt;
RUN;
%PUT NOTE: PROC COMPARE result SYSINFO=&SYSINFO. (0 means equal);
