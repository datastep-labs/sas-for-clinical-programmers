/* Chapter 10: the same two macros on a laboratory parameter, ALT (needs ADSL from 09_1 and the macros of 10_2_0) */

/* Step 010: one record per ALT result, with date and first dose date */
DATA adlb_010;
  LENGTH paramcd $8;
  MERGE sdtm.lb(IN=inlb WHERE=(lbtestcd = "ALT")
                KEEP=usubjid lbseq lbtestcd visitnum visit lbdtc lbstresn)
        adsl(IN=inadsl KEEP=usubjid trtsdt);
  BY usubjid;
  IF inlb AND inadsl;
  paramcd = lbtestcd;
  aval    = lbstresn;
  adt     = INPUT(lbdtc, ?? E8601DA.);
  FORMAT adt DATE9.;
  DROP lbtestcd lbdtc lbstresn;
RUN;

/* Step 020: the baseline as the SAP says, then BASE and CHG: two calls, no new code */
%m_baseline(data=adlb_010, out=adlb_020, sortby=usubjid paramcd adt lbseq)
%m_chg(data=adlb_020, out=adlb_alt, by=usubjid paramcd)

/* Step 030: where does the baseline come from? The SAP rule takes the last value before the first dose */
PROC FREQ DATA=adlb_alt;
  WHERE ablfl = "Y";
  TABLES visit / NOCUM NOPERCENT;
  TITLE "Visit of the baseline record";
RUN;
TITLE;
