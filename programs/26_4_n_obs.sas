/*******************************************************************************
| Macro Name    : n_obs
| Macro Version : v1.00
| Purpose       : Number of observations of a data set, with an optional WHERE.
|                 A function-style macro: it returns a number, so it can be used
|                 in %IF, %LET and in titles.
|
| Parameters
|   data  = input data set, required             Example: refadm.adae
|   where = filter, default 1 (all records)       Example: %STR(trtemfl = "Y")
|
| Returns -1 and writes an ERROR when the data set cannot be opened.
|
| Usage
|   %PUT NOTE: %n_obs(data=refadm.adae, where=%STR(trtemfl = "Y")) TEAE records;
|
| Change log
|   v1.00  first version, written test first (chapter 26)
*******************************************************************************/
%MACRO n_obs(data=, where=1);
  %LOCAL dsid n rc;
  %LET n = -1;
  %IF %LENGTH(&data.) = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [N_OBS] DATA= is required.;
    %GOTO finish;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [N_OBS] Data set &data. does not exist.;
    %GOTO finish;
  %END;
  %LET dsid = %SYSFUNC(OPEN(&data.(WHERE=(%UNQUOTE(&where.)))));
  %IF &dsid. = 0 %THEN %DO;
    %PUT %STR(ERR)OR: [N_OBS] %SYSFUNC(SYSMSG());
    %GOTO finish;
  %END;
  %LET n  = %SYSFUNC(ATTRN(&dsid., NLOBSF));
  %LET rc = %SYSFUNC(CLOSE(&dsid.));
  %finish:
  &n.
%MEND n_obs;
