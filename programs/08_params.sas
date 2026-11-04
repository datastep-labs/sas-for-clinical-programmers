/* Chapter 8: keyword parameters with defaults */
%MACRO freq_one(data=refadm.adsl, var=sex, where=1);
  PROC FREQ DATA=&data.;
    WHERE &where.;
    TABLES &var. / NOCUM;
  RUN;
%MEND freq_one;

%freq_one()
%freq_one(var=agegr1, where=%STR(saffl = "Y"))
