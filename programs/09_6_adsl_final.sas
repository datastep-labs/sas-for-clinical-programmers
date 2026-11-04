/* Chapter 9: the final ADSL from the specification (needs 09_1_adsl.sas and 09_5_spec_macros.sas) */
/* adam_spec.csv must sit next to this program: DataStep Studio uploads it with the folder.         */

/* Step 010: the specification is data */
%m_read_spec(file=adam_spec.csv, out=spec)

/* Step 020: what the function %m_get_attrib returns, the start of the ATTRIB text for ADSL */
%PUT NOTE: %QSUBSTR(%m_get_attrib(spec=spec, ds=ADSL), 1, 150);

/* Step 030: the final data set. WORK.ADSL stays as it is: chapters 10 and 11 use its working variables. */
%m_finalize(data=adsl, spec=spec, ds=ADSL, out=adsl_final, label=Subject-Level Analysis Dataset)

/* Step 040: look at the result: the variables in specification order, with their attributes */
PROC CONTENTS DATA=adsl_final VARNUM;
RUN;
