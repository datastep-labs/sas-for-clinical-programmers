/* Chapter 17: how the macro processor resolves names */
%LET trt1 = Placebo;
%LET trt2 = Xanomeline Low Dose;
%LET trt3 = Xanomeline High Dose;
%LET i    = 2;
%PUT NOTE: &&trt&i.;

%LET name = trt3;
%PUT NOTE: &&&name.;

/* Integer and decimal arithmetic */
%PUT NOTE: EVAL gives %EVAL(7 / 2), SYSEVALF gives %SYSEVALF(7 / 2);

/* Data step functions in macro code */
%PUT NOTE: %SYSFUNC(PUTN(0, DATE9.)) %SYSFUNC(COUNTW(sex race agegr1)) %SYSFUNC(PROPCASE(xanomeline high dose));
