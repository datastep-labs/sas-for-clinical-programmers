/* Chapter 13: the demographics table again, with the study macros of 13_3_table_macros.sas */

PROC FORMAT;
  VALUE trtf  0 = "Placebo" 54 = "Xanomeline Low Dose" 81 = "Xanomeline High Dose";
  VALUE $sexf "F" = "Female" "M" = "Male";
RUN;

/* Compute and arrange: one macro call per section of the table */
%m_bign(data=refadm.adsl, by=trt01an, where=saffl = "Y", out=dm_bign)

%m_desc(data=refadm.adsl, var=age, by=trt01an, where=saffl = "Y",
        label=Age (years), ord=1, out=dm_age)
%m_freq(data=refadm.adsl, var=agegr1, orderby=agegr1n, by=trt01an, where=saffl = "Y",
        denom=dm_bign, label=Age group, ord=2, out=dm_agegr1)
%m_freq(data=refadm.adsl, var=sex, by=trt01an, where=saffl = "Y",
        denom=dm_bign, fmt=$sexf., label=Sex, ord=3, out=dm_sex)
%m_freq(data=refadm.adsl, var=race, orderby=racen, by=trt01an, where=saffl = "Y",
        denom=dm_bign, label=Race, ord=4, out=dm_race)

DATA dm_rows;
  SET dm_age dm_agegr1 dm_sex dm_race;
RUN;

/* Print */
OPTIONS LS=110 PS=60 NOCENTER;
TITLE1 "Table 14.1.1 Demographics (safety population)";
%m_report(data=dm_rows, denom=dm_bign, fmt=trtf., lwidth=40)
TITLE;
