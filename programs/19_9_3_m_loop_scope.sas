/* Case study: a loop counter that another macro can change (needs 19_9_1 and 19_9_2) */

/* an inner macro that loops with _i and forgot %LOCAL */
%MACRO arm_counts(by=&each.);
  %LOCAL n;
  %DO _i = 1 %TO 3;
    /* n: the number of categories of &by. in arm &_i. */
    PROC SORT DATA=refadm.adsl(WHERE=(trt01pn = %SCAN(0 54 81, &_i.))) OUT=_arm(KEEP=&by.) NODUPKEY; BY &by.; RUN;
    DATA _NULL_; IF 0 THEN SET _arm NOBS=nobs; CALL SYMPUTX("n", nobs); STOP; RUN;
  %END;
  %PUT NOTE: &by.: &n. categories in the last arm;
  %LET tables_made = %EVAL(&tables_made. + 1);
%MEND arm_counts;

/* A: the loop counter _i is not %LOCAL */
%MACRO loop_a(macro=, list=);
  %LOCAL each;
  %DO _i = 1 %TO %SYSFUNC(COUNTW(&list., %STR( )));
    %LET each = %SCAN(&list., &_i., %STR( ));
    %&macro.;
  %END;
%MEND loop_a;

/* B: _i is %LOCAL, but the inner macro still finds it */
%MACRO loop_b(macro=, list=);
  %LOCAL each _i;
  %DO _i = 1 %TO %SYSFUNC(COUNTW(&list., %STR( )));
    %LET each = %SCAN(&list., &_i., %STR( ));
    %&macro.;
  %END;
%MEND loop_b;

%LET tables_made = 0;
%loop_a(macro=arm_counts, list=&subgroups.)
%PUT NOTE: A, _i not local: &tables_made. of 4 subgroups done;

%LET tables_made = 0;
%loop_b(macro=arm_counts, list=&subgroups.)
%PUT NOTE: B, _i local: &tables_made. of 4 subgroups done;

/* C: %m_loop counts with its own name, _ml_i */
%LET tables_made = 0;
%m_loop(macro=arm_counts, list=&subgroups.)
%PUT NOTE: C, %NRSTR(%m_loop) with _ml_i: &tables_made. of 4 subgroups done;

/* D: the inner macro is fixed: %LOCAL n _i */
%MACRO arm_counts(by=&each.);
  %LOCAL n _i;
  %DO _i = 1 %TO 3;
    /* n: the number of categories of &by. in arm &_i. */
    PROC SORT DATA=refadm.adsl(WHERE=(trt01pn = %SCAN(0 54 81, &_i.))) OUT=_arm(KEEP=&by.) NODUPKEY; BY &by.; RUN;
    DATA _NULL_; IF 0 THEN SET _arm NOBS=nobs; CALL SYMPUTX("n", nobs); STOP; RUN;
  %END;
  %PUT NOTE: &by.: &n. categories in the last arm;
  %LET tables_made = %EVAL(&tables_made. + 1);
%MEND arm_counts;
%LET tables_made = 0;
%loop_b(macro=arm_counts, list=&subgroups.)
%PUT NOTE: D, inner macro fixed: &tables_made. of 4 subgroups done;

/* E: a global _i, and a loop that does not declare it */
%LET _i = kept;
%loop_a(macro=arm_counts, list=sex)
%PUT NOTE: E, global _i after loop_a: &_i.;
%LET _i = kept;
%m_loop(macro=arm_counts, list=sex)
%PUT NOTE: E, global _i after %NRSTR(%m_loop): &_i.;
%SYMDEL _i;
