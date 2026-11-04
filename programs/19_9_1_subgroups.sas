/* Case study: list processing, a subgroup list and a table for ONE subgroup */

/* Naming and order of the subgroups */
%LET subgroups =
  sex       /* Sex: F, M */
  agegr1    /* Age group: <65, 65-80, >80 years */
  race      /* Race: as collected */
  bmiblgr1  /* Baseline BMI: <25, 25-<30, >=30 kg/m2 */
;
%PUT NOTE: subgroups=&subgroups.;

/* The label of a variable, as text: %varlabel(data set, variable) */
%MACRO varlabel(ds, var);
  %LOCAL dsid num lbl rc;
  %LET dsid = %SYSFUNC(OPEN(&ds.));
  %IF &dsid. > 0 %THEN %DO;
    %LET num = %SYSFUNC(VARNUM(&dsid., &var.));
    %IF &num. > 0 %THEN %LET lbl = %SYSFUNC(VARLABEL(&dsid., &num.));
    %LET rc = %SYSFUNC(CLOSE(&dsid.));
  %END;
  %IF %LENGTH(&lbl.) = 0 %THEN %LET lbl = &var.;
  &lbl.
%MEND varlabel;

/* One table: change from baseline by treatment, for ONE subgroup variable */
%GLOBAL tables_made;
%LET tables_made = 0;
%MACRO chg_table(paramcd=SYSBP, atptn=815, avisit=Week 24, by=&each., by_title=%varlabel(refadm.adsl, &each.));
  /* Step 010: the analysis records, with the subgroup from ADSL */
  DATA _ct_010;
    MERGE refadm.advs(IN=inadvs KEEP=usubjid paramcd atptn avisit trtpn trtp chg)
          refadm.adsl(IN=inadsl KEEP=usubjid &by.);
    BY usubjid;
    IF inadvs AND inadsl;
    IF paramcd = "&paramcd." AND atptn = &atptn. AND avisit = "&avisit." AND NOT MISSING(chg);
    KEEP &by. trtpn trtp chg;
  RUN;
  /* Step 020: n, mean and SD per subgroup and treatment */
  PROC MEANS DATA=_ct_010 NWAY NOPRINT;
    CLASS &by. trtpn trtp;
    VAR chg;
    OUTPUT OUT=_ct_020(DROP=_type_ _freq_) N=n MEAN=mean STD=sd;
  RUN;
  TITLE1 "Change from baseline in &paramcd. at &avisit.";
  TITLE2 "by &by_title.";
  PROC PRINT DATA=_ct_020 NOOBS;
    VAR &by. trtp n mean sd;
    FORMAT mean sd 8.2;
  RUN;
  TITLE;
  %LET tables_made = %EVAL(&tables_made. + 1);
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _ct_:; RUN; QUIT;
%MEND chg_table;

/* The old way: a loop macro written for this one analysis */
%MACRO _subgroup_chg(subgroups=);
  %LOCAL i _subgroup_i;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&subgroups., %STR( )));
    %LET _subgroup_i = %SCAN(&subgroups., &i., %STR( ));
    %chg_table(by=&_subgroup_i., by_title=%varlabel(refadm.adsl, &_subgroup_i.))
  %END;
%MEND _subgroup_chg;

%_subgroup_chg(subgroups=&subgroups.)
%PUT NOTE: tables made by the old way: &tables_made.;
