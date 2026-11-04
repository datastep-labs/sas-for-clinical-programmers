/* Chapter 8: where does a macro variable live? */
%LET where = global;

%MACRO inner();
  %PUT NOTE: inner sees &=where.;
%MEND inner;

%MACRO outer();
  %LOCAL where;
  %LET where = outer;
  %inner()
%MEND outer;

%outer()
%PUT NOTE: after the call &=where.;
