/* Chapter 11: the final ADAE from the specification (needs 11_1_adae.sas and 09_5_spec_macros.sas) */

/* Step 010: ASEQ in key order, then the final data set */
%m_read_spec(file=adam_spec.csv, out=spec)
%m_aseq(data=adae, by=usubjid astdt aedecod aeseq, out=adae_seq)
%m_finalize(data=adae_seq, spec=spec, ds=ADAE, out=adae_final, label=Adverse Events Analysis Dataset)

/* Step 020: ASEQ (analysis order) and AESEQ (collection order) are not the same numbering */
PROC SORT DATA=adae_final(KEEP=usubjid aeseq aseq) OUT=seq_010;
  BY usubjid aeseq;
RUN;
DATA seq_020;
  SET seq_010;
  BY usubjid;
  IF FIRST.usubjid THEN rank = 0;
  rank + 1;
  differ = (rank NE aseq);
RUN;
PROC FREQ DATA=seq_020;
  TABLES differ / NOCUM;
RUN;
/* the subjects with at least one record that differs: one row each */
PROC SORT DATA=seq_020(WHERE=(differ = 1)) OUT=seq_subj NODUPKEY;
  BY usubjid;
RUN;
