/* Chapter 17: the classic log options */
%MACRO freq_each(data=, vars=);
  %LOCAL i var;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&vars., %STR( )));
    %LET var = %SCAN(&vars., &i., %STR( ));
    PROC FREQ DATA=&data.; TABLES &var. / NOCUM; RUN;
  %END;
%MEND freq_each;

OPTIONS MPRINT MLOGIC SYMBOLGEN;
%freq_each(data=refadm.adsl, vars=sex)
OPTIONS NOMPRINT NOMLOGIC NOSYMBOLGEN;
