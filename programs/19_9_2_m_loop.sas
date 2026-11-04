/* Case study: %m_loop, write the loop once (needs 19_9_1) */
/*******************************************************************************
  Macro       : %m_loop
  Version     : 1.0
  Purpose     : Call a macro once for each item of a list. Inside the called
                macro, &each. holds the current item.
  Parameters  :
    macro=      the macro call without the %, with its parameters (required)
    list=       the items (empty: the macro is called once, &each. is empty)
    delimiter=  the character between the items (default: blank)
  Example     :
    %m_loop(macro=chg_table(paramcd=SYSBP), list=sex agegr1)
  Change log  :
    2026-11-01  1.0  first version: each and the counter _ml_i are %LOCAL,
                     the counter has a private name (see 19_9_3)
*******************************************************************************/
%MACRO m_loop(macro=, list=, delimiter=%STR( ));
  %LOCAL each _ml_i;
  %IF %LENGTH(&list.) = 0 %THEN %&macro.;
  %ELSE %DO _ml_i = 1 %TO %SYSFUNC(COUNTW(&list., &delimiter.));
    %LET each = %SCAN(&list., &_ml_i., &delimiter.);
    %&macro.;
  %END;
%MEND m_loop;

/* Iterate over all subgroups: the analysis is one line */
%LET tables_made = 0;
%m_loop(
    macro = chg_table(paramcd=SYSBP, atptn=815, avisit=Week 24)
  , list  = &subgroups.
)
%PUT NOTE: tables made by %NRSTR(%m_loop): &tables_made.;

/* The same loop, another analysis: only the macro call changes */
%LET tables_made = 0;
%m_loop(
    macro = chg_table(paramcd=DIABP, atptn=815, avisit=Week 24)
  , list  = sex agegr1
)
%PUT NOTE: tables made for DIABP: &tables_made.;
