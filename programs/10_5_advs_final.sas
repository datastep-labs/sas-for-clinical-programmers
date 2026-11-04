/* Chapter 10: the final ADVS from the specification (needs 10_1_advs.sas, 10_2_advs_bp.sas and 09_5_spec_macros.sas) */

/* Step 010: weight (10_1) and blood pressure and pulse (10_2) in one data set */
DATA advs_all;
  SET advs advs_bp;
RUN;

/* Step 020: ASEQ in key order, then the final data set */
%m_read_spec(file=adam_spec.csv, out=spec)
%m_aseq(data=advs_all, by=usubjid paramcd adt atptn vsseq, out=advs_seq)
%m_finalize(data=advs_seq, spec=spec, ds=ADVS, out=advs_final, label=Vital Signs Analysis Dataset)

/* Step 030: look at the result */
PROC CONTENTS DATA=advs_final VARNUM;
RUN;
