/* Chapter 4: one record per subject and preferred term */
PROC SORT DATA=sdtm.ae(KEEP=usubjid aedecod) OUT=ae_pt NODUPKEY DUPOUT=ae_dups;
  BY usubjid aedecod;
RUN;
