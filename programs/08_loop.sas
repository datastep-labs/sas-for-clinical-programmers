/* Chapter 8: one PROC FREQ per variable in a list */
%MACRO freq_each(data=, vars=);
  %LOCAL i var;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
    %LET var = %SCAN(&vars., &i., %STR( ));
    TITLE "&var. in &data.";
    PROC FREQ DATA=&data.; TABLES &var. / NOCUM; RUN;
  %END;
  TITLE;
%MEND freq_each;

%freq_each(data=refadm.adsl, vars=sex race agegr1)
