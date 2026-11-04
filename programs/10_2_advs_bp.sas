/* Chapter 10: blood pressure and pulse with the study macros %m_baseline and %m_chg (needs ADSL from 09_1, ADVS_020 from 10_1 and the macros of 10_2_0) */

/*****************************************************************************/
/* Example SAP definition: Baseline                                          */
/* Baseline is the last non-missing value on or before the day of the first  */
/* dose. Blood pressure and pulse are measured in three positions: each      */
/* position has its own baseline.                                            */
/*****************************************************************************/

/* Step 010: one record per measurement, with date, study day and position */
DATA advs_bp_010;
  LENGTH paramcd $8 param $40 atpt $40 avisit $20;
  MERGE sdtm.vs(IN=invs WHERE=(vstestcd IN ("SYSBP" "DIABP" "PULSE"))
                KEEP=usubjid vsseq vstestcd vstest vstpt vstptnum visitnum visit vsdtc vsstresn vsstresu)
        adsl(IN=inadsl KEEP=usubjid trtsdt);
  BY usubjid;
  IF invs AND inadsl;
  paramcd = vstestcd;
  param   = CATS(vstest, " (", vsstresu, ")");
  atpt    = vstpt;
  atptn   = vstptnum;
  aval    = vsstresn;
  adt     = INPUT(vsdtc, ?? E8601DA.);
  IF      adt >= trtsdt    THEN ady = adt - trtsdt + 1;
  ELSE IF NOT MISSING(adt) THEN ady = adt - trtsdt;
  IF visit = "BASELINE" THEN DO;
    avisit  = "Baseline";
    avisitn = 0;
  END;
  ELSE IF SCAN(visit, 1) = "WEEK" THEN DO;
    avisitn = INPUT(SCAN(visit, 2), ?? 8.);
    avisit  = CATX(" ", "Week", avisitn);
  END;
  FORMAT adt DATE9.;
  DROP vstestcd vstest vstpt vstptnum vsdtc vsstresn vsstresu;
RUN;

/* Step 020: the baseline record, as the SAP says, not as the visit is called: */
/* the last non-missing value on or before the first dose, one per position   */
%m_baseline(data=advs_bp_010, out=advs_bp_020, by=usubjid paramcd atptn,
            sortby=usubjid paramcd atptn adt vsseq)

/* Step 030: BASE, CHG and PCHG, one baseline per position */
%m_chg(data=advs_bp_020, out=advs_bp, by=usubjid paramcd atptn)

/* Where does the baseline come from when it is not the BASELINE visit? */
TITLE "Baselines that do not come from the BASELINE visit";
PROC FREQ DATA=advs_bp;
  WHERE ablfl = "Y" AND visit NE "BASELINE";
  TABLES usubjid*visit / LIST NOCUM NOPERCENT;
RUN;
TITLE;

/* Step 040: the same macro on weight: the SAP rule against the visit name of 10_1 */
%m_baseline(data=advs_020, out=advs_wt_sap, sortby=usubjid paramcd adt vsseq)
PROC SORT DATA=advs_020(KEEP=usubjid vsseq visit adt aval ablfl) OUT=wt_visit;
  BY usubjid vsseq;
RUN;
PROC SORT DATA=advs_wt_sap(KEEP=usubjid vsseq ablfl) OUT=wt_sap;
  BY usubjid vsseq;
RUN;
DATA wt_diff;
  MERGE wt_visit(RENAME=(ablfl=by_visit_name)) wt_sap(RENAME=(ablfl=by_sap_rule));
  BY usubjid vsseq;
  IF by_visit_name NE by_sap_rule;
RUN;
TITLE "Weight: baseline by the visit name (10_1) or by the SAP rule";
PROC PRINT DATA=wt_diff NOOBS;
  VAR usubjid visit adt aval by_visit_name by_sap_rule;
RUN;
TITLE;

