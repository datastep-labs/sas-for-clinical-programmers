/* Chapter 13: study macros for summary tables. Run this file once, then 13_4 and 13_5 use the macros. */
/* All macros share one interface: data= the input, out= the output, by= the column variable,       */
/* where= the records to use. Every macro writes rows in one layout, the same for all of them:       */
/*   col (the value of by=), ord (the section), sub (the line in the section), label, value (text)   */

/*******************************************************************************
  Macro       : %m_need
  Purpose     : Check that the required parameters of a macro are not empty.
                Returns 1 (and writes an ERROR line for each empty one) or 0.
  Parameters  :
    macro=      the name of the calling macro, for the message
    params=     the names of the required parameters, separated by blanks
  Example     :
    %IF %m_need(macro=M_FREQ, params=data var by denom) %THEN %RETURN;
  Note        : the local names start with _mn_, so they never hide a
                parameter of the macro that calls %m_need.
*******************************************************************************/
%MACRO m_need(macro=, params=);
  %LOCAL _mn_i _mn_p _mn_bad;
  %LET _mn_bad = 0;
  %DO _mn_i = 1 %TO %SYSFUNC(COUNTW(&params., %STR( )));
    %LET _mn_p = %SCAN(&params., &_mn_i., %STR( ));
    %IF %SUPERQ(&_mn_p.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] The parameter %UPCASE(&_mn_p.)= is required.;
      %LET _mn_bad = 1;
    %END;
  %END;
  &_mn_bad.
%MEND m_need;

/*******************************************************************************
  Macro       : %m_bign
  Purpose     : The big N: the number of subjects in each column.
  Parameters  :
    data=       the subject level data set, for example refadm.adsl
    by=         the numeric column variable, for example trt01an
    where=      the population, for example saffl = "Y" (default: all records)
    id=         the subject variable (default: usubjid)
    out=        the output data set: one record per column, variables col and bign
*******************************************************************************/
%MACRO m_bign(data=, by=, where=1, id=usubjid, out=);
  %IF %m_need(macro=M_BIGN, params=data by id out) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [M_BIGN] The data set &data. does not exist.;
    %RETURN;
  %END;

  /* one record per subject and column, then count the records */
  PROC SORT DATA=&data.(WHERE=(&where.)) OUT=_mb_010(KEEP=&by. &id.) NODUPKEY;
    BY &by. &id.;
  RUN;
  PROC FREQ DATA=_mb_010 NOPRINT;
    TABLES &by. / OUT=&out.(KEEP=&by. count RENAME=(&by.=col count=bign));
  RUN;
  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mb_:; RUN; QUIT;

  DATA _NULL_;
    SET &out.;
    PUTLOG "NOTE: [M_BIGN] column " col "has N=" bign;
  RUN;
%MEND m_bign;

/*******************************************************************************
  Macro       : %m_desc
  Purpose     : Rows for a continuous variable: n, Mean (SD), Median, Min, Max.
  Parameters  :
    data=       the input data set
    var=        the numeric variable
    by=         the numeric column variable
    where=      the records to use (default: all records)
    dec=        the decimals of the collected value (default 0): the mean and
                the median get one more, the SD two more
    label=      the text of the section heading
    ord=        the number of the section in the table
    out=        the output data set in the row layout
*******************************************************************************/
%MACRO m_desc(data=, var=, by=, where=1, dec=0, label=, ord=, out=);
  %IF %m_need(macro=M_DESC, params=data var by dec label ord out) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [M_DESC] The data set &data. does not exist.;
    %RETURN;
  %END;

  /* Step 010: the statistics, one record per column */
  PROC MEANS DATA=&data.(WHERE=(&where.)) NOPRINT NWAY;
    CLASS &by.;
    VAR &var.;
    OUTPUT OUT=_md_010 N=n MEAN=mean STD=sd MEDIAN=median MIN=min MAX=max;
  RUN;

  /* Step 020: five lines of text per column */
  DATA &out.;
    LENGTH label $60 value $20;
    SET _md_010(RENAME=(&by.=col));
    ord = &ord.;
    sub = 0; label = "&label.";    value = " ";                                    OUTPUT;
    sub = 1; label = "  n";         value = CATS(n);                                OUTPUT;
    sub = 2; label = "  Mean (SD)"; value = CATX(" ", PUT(mean, 8.%EVAL(&dec. + 1)),
                                              CATS("(", PUT(sd, 8.%EVAL(&dec. + 2)), ")")); OUTPUT;
    sub = 3; label = "  Median";    value = STRIP(PUT(median, 8.%EVAL(&dec. + 1))); OUTPUT;
    sub = 4; label = "  Min, Max";  value = CATX(", ", PUT(min, 8.&dec.), PUT(max, 8.&dec.)); OUTPUT;
    KEEP col ord sub label value;
  RUN;

  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _md_:; RUN; QUIT;
%MEND m_desc;

/*******************************************************************************
  Macro       : %m_freq
  Purpose     : Rows for a categorical variable: n (%) of the big N, with a
                line for every category in every column, also when n is 0.
  Parameters  :
    data=       the input data set
    var=        the categorical variable
    by=         the numeric column variable
    where=      the records to use (default: all records)
    id=         count distinct values of this variable (for example usubjid);
                empty (default): count records
    denom=      the big N data set from %m_bign (variables col and bign)
    fmt=        a format for the category text (default: the value itself)
    orderby=    the variable that gives the order of the categories
                (default: var=), for example agegr1n for agegr1
    label=      the text of the section heading (", n (%)" is added)
    ord=        the number of the section in the table
    out=        the output data set in the row layout
*******************************************************************************/
%MACRO m_freq(data=, var=, by=, where=1, id=, denom=, fmt=, orderby=, label=, ord=, out=);
  %IF %m_need(macro=M_FREQ, params=data var by denom label ord out) %THEN %RETURN;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [M_FREQ] The data set &data. does not exist.;
    %RETURN;
  %END;
  %IF %SUPERQ(orderby) = %THEN %LET orderby = &var.;

  /* Step 010: the records of the section; one per subject when id= is given */
  DATA _mf_010;
    SET &data.(WHERE=(&where.));
    IF NOT MISSING(&var.);
    col    = &by.;
    level  = &var.;
    lorder = &orderby.;
    KEEP col level lorder &id.;
  RUN;
  %IF %SUPERQ(id) NE %THEN %DO;
    PROC SORT DATA=_mf_010 NODUPKEY; BY col lorder &id.; RUN;
  %END;

  /* Step 020: the counts; SPARSE writes 0 for a category that a column does not have */
  PROC FREQ DATA=_mf_010 NOPRINT;
    TABLES col * lorder / SPARSE OUT=_mf_020(KEEP=col lorder count RENAME=(count=n));
  RUN;

  /* Step 030: the category of each count */
  PROC SORT DATA=_mf_010(KEEP=lorder level) OUT=_mf_025 NODUPKEY; BY lorder; RUN;
  PROC SORT DATA=_mf_020; BY lorder col; RUN;
  DATA _mf_030;
    MERGE _mf_020 _mf_025;
    BY lorder;
  RUN;
  PROC SORT DATA=_mf_030; BY col lorder; RUN;

  /* Step 040: with the big N of each column: one heading line and one line per category */
  DATA &out.;
    LENGTH label $60 value $20;
    MERGE _mf_030(IN=incount) &denom.;
    BY col;
    IF incount;
    ord = &ord.;
    IF FIRST.col THEN DO;
      sub = 0; label = "&label., n (%)"; value = " "; OUTPUT;
    END;
    sub + 1;
    label = CAT("  ", %IF %SUPERQ(fmt) NE %THEN STRIP(PUT(level, &fmt.)); %ELSE CATS(level););
    IF n = 0 THEN value = "0";
    ELSE value = CATX(" ", PUT(n, 4.), CATS("(", PUT(n / bign * 100, 5.1), ")"));
    OUTPUT;
    KEEP col ord sub label value;
  RUN;

  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mf_:; RUN; QUIT;
%MEND m_freq;

/*******************************************************************************
  Macro       : %m_report
  Purpose     : Print rows in the row layout as a table: one line per ord and
                sub, one column per value of col, headers with the big N.
  Parameters  :
    data=       the rows (variables col, ord, sub, label, value)
    denom=      the big N data set from %m_bign (variables col and bign)
    fmt=        the format that turns col into the column name
    lwidth=     the width of the label column (default 32)
    cwidth=     the width of each treatment column (default 20)
*******************************************************************************/
%MACRO m_report(data=, denom=, fmt=, lwidth=32, cwidth=20);
  %LOCAL i _mr_n;
  %IF %m_need(macro=M_REPORT, params=data denom fmt lwidth cwidth) %THEN %RETURN;

  /* Step 010: one column per value of col */
  PROC SORT DATA=&data. OUT=_mr_010; BY ord sub label; RUN;
  PROC TRANSPOSE DATA=_mr_010 OUT=_mr_020(DROP=_name_) PREFIX=c;
    BY ord sub label;
    ID col;
    VAR value;
  RUN;

  /* Step 020: the column names and headers, from the big N */
  DATA _NULL_;
    SET &denom. END=eof;
    CALL SYMPUTX(CATS("_mr_c", _N_), col, "L");
    CALL SYMPUTX(CATS("_mr_h", _N_), CATS(PUT(col, &fmt.), "|(N=", bign, ")"), "L");
    IF eof THEN CALL SYMPUTX("_mr_n", _N_, "L");
  RUN;

  /* Step 030: print */
  PROC REPORT DATA=_mr_020 NOWD HEADLINE SPLIT="|" MISSING;
    COLUMN ord sub label %DO i = 1 %TO &_mr_n.; c&&_mr_c&i. %END;;
    DEFINE ord   / ORDER NOPRINT;
    DEFINE sub   / ORDER NOPRINT;
    DEFINE label / DISPLAY " " WIDTH=&lwidth. FLOW;
    %DO i = 1 %TO &_mr_n.;
      DEFINE c&&_mr_c&i. / DISPLAY "&&_mr_h&i." WIDTH=&cwidth. CENTER;
    %END;
    COMPUTE AFTER ord;
      LINE " ";
    ENDCOMP;
  RUN;

  PROC DATASETS LIBRARY=work NOLIST NOWARN; DELETE _mr_:; RUN; QUIT;
%MEND m_report;
