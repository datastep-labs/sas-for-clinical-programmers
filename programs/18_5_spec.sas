/* Chapter 18: a parameter written as a small specification language */
%MACRO desc(data=, cont=, by=, out=desc);
  %LOCAL i item var lab dec;
  %DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(cont), #));
    %LET item = %QSCAN(%SUPERQ(cont), &i., #);
    %LET var  = %SCAN(&item., 1, |);
    %LET lab  = %QSCAN(&item., 2, |);
    %LET dec  = %SCAN(&item., 3, |);
    PROC MEANS DATA=&data. NOPRINT NWAY;
      CLASS &by.;
      VAR &var.;
      OUTPUT OUT=_desc_&i. N=n MEAN=mean STD=sd;
    RUN;
    DATA _desc_&i.;
      LENGTH label $40 stat $20;
      SET _desc_&i.;
      label = "%TRIM(&lab.)";
      stat  = CATX(" ", PUT(mean, 8.%EVAL(&dec. + 1)), CATS("(", PUT(sd, 8.%EVAL(&dec. + 2)), ")"));
      KEEP label &by. n stat;
    RUN;
  %END;
  DATA &out.;
    SET _desc_:;
  RUN;
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _desc_:; RUN; QUIT;
%MEND desc;

%desc(data=refadm.adsl, cont=age|Age (years)|0 # bmibl|BMI (kg/m2)|1, by=trt01pn)

PROC PRINT DATA=desc NOOBS;
RUN;
