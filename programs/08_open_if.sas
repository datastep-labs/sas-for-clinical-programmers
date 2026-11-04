/* Chapter 8: %IF outside a macro needs %DO and %END */
%IF %SYSFUNC(EXIST(refadm.adsl)) %THEN %DO;
  %PUT NOTE: ADSL found.;
%END;
%ELSE %DO;
  %PUT %STR(WAR)NING: ADSL not found.;
%END;
