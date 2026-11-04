/* EXPECT: ERROR The target of the %GOTO statement was a reserved macro keyword */
/* EXPECT: ERROR A dummy macro will be compiled */
/* EXPECT: ERROR Macro keyword STOP is not yet implemented */
/* Chapter 8: a label must not be a macro keyword */
%MACRO check_ds(ds=);
  %IF NOT %SYSFUNC(EXIST(&ds.)) %THEN %GOTO stop;
  %PUT NOTE: &ds. exists.;
  %stop:
%MEND check_ds;
