/* Chapter 19: an autocall library finds a macro by its file name */
DATA _NULL_;
  rc = DCREATE("mymacros", "%SYSFUNC(PATHNAME(work))");
RUN;

DATA _NULL_;
  FILE "%SYSFUNC(PATHNAME(work))/mymacros/hello_lib.sas";
  PUT '%MACRO hello_lib(name=world);';
  PUT '  %PUT NOTE: hello &name. from the autocall library;';
  PUT '%MEND hello_lib;';
RUN;

OPTIONS MAUTOSOURCE SASAUTOS=("%SYSFUNC(PATHNAME(work))/mymacros" SASAUTOS);
%hello_lib(name=reader)
