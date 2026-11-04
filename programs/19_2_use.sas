/* Chapter 19: two calls, one with debug=Y */
%count_subj(data=refadm.adae, by=trtan, where=%STR(trtemfl = "Y"), out=teae_n)
PROC PRINT DATA=teae_n NOOBS; RUN;

%count_subj(data=refadm.adsl, by=trt01pn sex, out=sex_n, debug=Y)
PROC PRINT DATA=sashelp.vtable NOOBS;
  WHERE libname = "WORK" AND memname =: "_CS_";
  VAR memname;
RUN;
