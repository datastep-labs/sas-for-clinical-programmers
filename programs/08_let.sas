/* Chapter 8: macro variables are text that SAS pastes into your code */
%LET lib  = refadm;
%LET ds   = adsl;
%LET flag = saffl;

PROC FREQ DATA=&lib..&ds.;
  TABLES &flag. / NOCUM;
RUN;

%PUT NOTE: The step read &=lib. &=ds. &=flag.;
