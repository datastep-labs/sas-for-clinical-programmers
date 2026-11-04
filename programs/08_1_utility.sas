/* Chapter 8: two utility macros that every library needs */
%MACRO nobs(ds);
  %LOCAL dsid n rc;
  %LET dsid = %SYSFUNC(OPEN(&ds.));
  %IF &dsid. %THEN %DO;
    %LET n  = %SYSFUNC(ATTRN(&dsid., NLOBSF));
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
  %END;
  %ELSE %LET n = -1;
  &n.
%MEND nobs;

%MACRO varexist(ds, var);
  %LOCAL dsid rc res;
  %LET res  = 0;
  %LET dsid = %SYSFUNC(OPEN(&ds.));
  %IF &dsid. %THEN %DO;
    %IF %SYSFUNC(VARNUM(&dsid., &var.)) > 0 %THEN %LET res = 1;
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
  %END;
  &res.
%MEND varexist;

%PUT NOTE: ADSL has %nobs(refadm.adsl) records, a missing data set gives %nobs(work.nothere).;
%PUT NOTE: TRTSDT in ADSL: %varexist(refadm.adsl, trtsdt), FOO in ADSL: %varexist(refadm.adsl, foo);
