/* Chapter 9: four study macros that let the specification drive the final ADaM data sets */
/* The specification is the file adam_spec.csv next to the programs of this book.          */

/*******************************************************************************
  Macro       : %m_read_spec
  Version     : 1.1
  Purpose     : Read the ADaM specification (a CSV file) into a data set.
  Parameters  :
    file=     the CSV file: dataset, variable, label, type, length, format,
              order, key (required)
    out=      the output data set, sorted by dataset and order (required)
    debug=    N (default) deletes the work data sets _mrs_:; Y keeps them
  Preconditions  : &file. exists; one header row
  Postconditions : &out. has one row per data set and variable
  Examples    :
    %m_read_spec(file=adam_spec.csv, out=spec)
  Change log  :
    2026-11-02  1.0  first version
    2026-11-02  1.1  debug= and the runtime NOTE (the checklist of 19.6)
*******************************************************************************/
%MACRO m_read_spec(file=, out=, debug=N) / DES = 'Read the ADaM specification';
  %LOCAL macro mversion _starttime p par nbad ndup nrow dslist;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 1.1;
  %LET _starttime = %SYSFUNC(DATETIME());

  /* Check the parameters: nothing runs when one check fails */
  %DO p = 1 %TO 2;
    %LET par = %SCAN(file out, &p.);
    %IF %SUPERQ(&par.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the parameter &par.= is required.;
      %RETURN;
    %END;
  %END;
  %IF NOT %SYSFUNC(FILEEXIST(&file.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the file &file. does not exist. Put it next to the programs.;
    %RETURN;
  %END;

  /* Step 010: read the CSV as chapter 2 does: DSD, one row per variable */
  DATA _mrs_010;
    INFILE "&file." DSD FIRSTOBS=2 TRUNCOVER LRECL=1000;
    LENGTH dataset $8 variable $32 label $200 type $1 length 8 format $32 order key 8;
    INPUT dataset variable label type length format order key;
    dataset  = UPCASE(dataset);
    variable = UPCASE(variable);
    type     = UPCASE(type);
  RUN;

  /* Step 020: every row needs a variable, a type C or N and a length */
  PROC SORT DATA=_mrs_010 OUT=_mrs_020;
    BY dataset variable;
  RUN;
  DATA _NULL_;
    SET _mrs_020 END=last;
    BY dataset variable;
    IF MISSING(variable) OR type NOT IN ("C" "N") OR MISSING(length) THEN nbad + 1;
    IF FIRST.variable AND NOT LAST.variable THEN ndup + 1;
    IF last THEN DO;
      CALL SYMPUTX("nbad", nbad, "L");
      CALL SYMPUTX("ndup", ndup, "L");
    END;
  RUN;
  %IF &nbad. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] &nbad. rows of &file. have no variable, no type C or N, or no length.;
    %GOTO finish;
  %END;
  %IF &ndup. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] &ndup. variables appear twice for the same data set in &file..;
    %GOTO finish;
  %END;

  PROC SORT DATA=_mrs_010 OUT=&out.;
    BY dataset order;
  RUN;
  DATA _NULL_;
    SET &out. END=last;
    BY dataset;
    LENGTH dslist $200;
    RETAIN dslist;
    IF FIRST.dataset THEN dslist = CATX(" ", dslist, dataset);
    IF last THEN DO;
      CALL SYMPUTX("nrow", _N_, "L");
      CALL SYMPUTX("dslist", dslist, "L");
    END;
  RUN;
  %PUT NOTE: [&macro.] &out.: &nrow. rows for &dslist. (version &mversion.);

  %finish:
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mrs_:;
    RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] Finished in %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &_starttime.), 0.01)) seconds.;
%MEND m_read_spec;

/*******************************************************************************
  Macro       : %m_get_attrib
  Version     : 1.0
  Purpose     : A function: return the ATTRIB text of one data set from the
                specification, e.g. AGE LENGTH=8 LABEL="Age" ...
                Write ATTRIB %m_get_attrib(spec=spec, ds=ADSL); in a DATA step.
  Parameters  :
    spec=     the specification data set made by %m_read_spec (required)
    ds=       the data set name in the specification, e.g. ADSL (required)
  Preconditions  : &spec. is sorted by dataset and order
  Postconditions : the text in specification order; nothing else
  Examples    :
    DATA adsl_final; ATTRIB %m_get_attrib(spec=spec, ds=ADSL); SET adsl; RUN;
    %PUT NOTE: %QSUBSTR(%m_get_attrib(spec=spec, ds=ADSL), 1, 150);
  Change log  :
    2026-11-02  1.0  first version
*******************************************************************************/
%MACRO m_get_attrib(spec=, ds=) / DES = 'Return the ATTRIB text of one data set';
  %LOCAL macro dsid rc result var type len lab fmt n;
  %LET macro = %UPCASE(&SYSMACRONAME.);
  %IF %SUPERQ(spec) = OR %SUPERQ(ds) = %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] spec= and ds= are required.;
    %RETURN;
  %END;
  %IF NOT %SYSFUNC(EXIST(&spec.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the data set &spec. does not exist.;
    %RETURN;
  %END;
  /* OPEN gives a number (the data set id); FETCH reads the next row into   */
  /* the id; GETVARC and GETVARN return a character or a numeric value of   */
  /* that row; CLOSE frees the data set. No DATA step runs: this is a        */
  /* function, its result is text.                                           */
  %LET dsid = %SYSFUNC(OPEN(&spec.(WHERE=(dataset = "%UPCASE(&ds.)"))));
  %LET n = 0;
  %DO %WHILE(%SYSFUNC(FETCH(&dsid.)) = 0);
    %LET n    = %EVAL(&n. + 1);
    %LET var  = %SYSFUNC(GETVARC(&dsid., %SYSFUNC(VARNUM(&dsid., variable))));
    %LET type = %SYSFUNC(GETVARC(&dsid., %SYSFUNC(VARNUM(&dsid., type))));
    %LET len  = %SYSFUNC(GETVARN(&dsid., %SYSFUNC(VARNUM(&dsid., length))));
    %LET lab  = %QSYSFUNC(STRIP(%QSYSFUNC(GETVARC(&dsid., %SYSFUNC(VARNUM(&dsid., label))))));
    %LET fmt  = %SYSFUNC(GETVARC(&dsid., %SYSFUNC(VARNUM(&dsid., format))));
    %IF &type. = C %THEN %LET len = $&len.;
    %LET result = &result. &var. LENGTH=&len. LABEL=%QSYSFUNC(QUOTE(%SUPERQ(lab)));
    %IF %SUPERQ(fmt) NE %THEN %LET result = &result. FORMAT=&fmt.;
  %END;
  %LET rc = %SYSFUNC(CLOSE(&dsid.));
  %IF &n. = 0 %THEN %PUT %STR(ERR)OR: [&macro.] &spec. has no rows for &ds..;
  %UNQUOTE(&result.)
%MEND m_get_attrib;

/*******************************************************************************
  Macro       : %m_finalize
  Version     : 1.1
  Purpose     : Make the final ADaM data set from the specification: the
                attributes, only the specification variables in their order,
                sorted by the key, with a data set label.
  Parameters  :
    data=     the working data set (required)
    spec=     the specification data set made by %m_read_spec (required)
    ds=       the data set name in the specification, e.g. ADSL (required)
    out=      the final data set (required)
    label=    the data set label (optional)
    debug=    N (default) deletes the work data sets _mfi_:; Y keeps them
  Checks      : a specification variable is not in &data. (ERR OR), a type
                differs (ERR OR), a value is longer than the specification
                length (ERR OR), the key is not unique (ERR OR); variables
                that are not in the specification are dropped (NOTE)
  Examples    :
    %m_finalize(data=adsl, spec=spec, ds=ADSL, out=adsl_final,
                label=Subject-Level Analysis Dataset)
  Change log  :
    2026-11-02  1.0  first version
    2026-11-02  1.1  debug= and the runtime NOTE (the checklist of 19.6)
*******************************************************************************/
%MACRO m_finalize(data=, spec=, ds=, out=, label=, debug=N) / DES = 'Finalize an ADaM data set from the specification';
  %LOCAL macro mversion p par missing wrongtype dropped shorter speclen maxlist maxlen i
         keyvars lastkey keep ndup nrow nvar oldchk toolong _starttime;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 1.1;
  %LET _starttime = %SYSFUNC(DATETIME());
  %LET ds       = %UPCASE(&ds.);

  /* Check the parameters: nothing runs when one check fails */
  %DO p = 1 %TO 4;
    %LET par = %SCAN(data spec ds out, &p.);
    %IF %SUPERQ(&par.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the parameter &par.= is required.;
      %RETURN;
    %END;
  %END;
  /* the data set name without its options: adsl(DROP=bmibl) is adsl */
  %LET par = %SCAN(&data., 1, %STR(%());
  %IF NOT %SYSFUNC(EXIST(&par.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the data set &par. does not exist.;
    %RETURN;
  %END;
  %IF NOT %SYSFUNC(EXIST(&spec.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the data set &spec. does not exist.;
    %RETURN;
  %END;

  /* Step 010: the specification of this data set, and the variables of the data */
  DATA _mfi_010;
    SET &spec.(WHERE=(dataset = "&ds."));
  RUN;
  PROC CONTENTS DATA=&data. OUT=_mfi_011(KEEP=name type length) NOPRINT;
  RUN;
  DATA _mfi_011;
    SET _mfi_011;
    name = UPCASE(name);
  RUN;

  /* Step 020: compare the two lists */
  PROC SQL NOPRINT;
    SELECT s.variable INTO :missing SEPARATED BY " " FROM _mfi_010 AS s
      WHERE s.variable NOT IN (SELECT name FROM _mfi_011);
    SELECT s.variable INTO :wrongtype SEPARATED BY " "
      FROM _mfi_010 AS s INNER JOIN _mfi_011 AS d ON s.variable = d.name
      WHERE (s.type = "C" AND d.type = 1) OR (s.type = "N" AND d.type = 2);
    SELECT name INTO :dropped SEPARATED BY " " FROM _mfi_011
      WHERE name NOT IN (SELECT variable FROM _mfi_010);
    SELECT variable INTO :keep SEPARATED BY " " FROM _mfi_010 ORDER BY order;
    SELECT variable INTO :keyvars SEPARATED BY " " FROM _mfi_010 WHERE NOT MISSING(key) ORDER BY key;
  QUIT;
  %IF %SUPERQ(missing) NE %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the specification of &ds. has variables that &data. does not have: &missing..;
    %GOTO finish;
  %END;
  %IF %SUPERQ(wrongtype) NE %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] these variables have another type than the specification: &wrongtype..;
    %GOTO finish;
  %END;
  %IF %SUPERQ(keyvars) = %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the specification of &ds. has no key.;
    %GOTO finish;
  %END;
  %IF %SUPERQ(dropped) NE %THEN
    %PUT NOTE: [&macro.] not in the specification, dropped: &dropped..;

  /* Step 030: a shorter length cuts values, so check every value BEFORE shortening */
  PROC SQL NOPRINT;
    SELECT d.name, CATS(s.length), CATS("MAX(LENGTHN(", d.name, "))")
      INTO :shorter SEPARATED BY " ", :speclen SEPARATED BY " ", :maxlist SEPARATED BY ", "
      FROM _mfi_011 AS d INNER JOIN _mfi_010 AS s ON d.name = s.variable
      WHERE d.type = 2 AND d.length > s.length;
  QUIT;
  %IF %SUPERQ(shorter) NE %THEN %DO;
    PROC SQL NOPRINT;
      SELECT CATX(" ", &maxlist.) INTO :maxlen TRIMMED FROM &data.;
    QUIT;
    %LET toolong = 0;
    %DO i = 1 %TO %SYSFUNC(COUNTW(&shorter.));
      %IF %SCAN(&maxlen., &i.) > %SCAN(&speclen., &i.) %THEN %DO;
        %PUT %STR(ERR)OR: [&macro.] %SCAN(&shorter., &i.): the longest value has %SCAN(&maxlen., &i.) characters, the specification allows %SCAN(&speclen., &i.).;
        %LET toolong = 1;
      %END;
    %END;
    %IF &toolong. %THEN %GOTO finish;
  %END;

  /* Step 040: sort by the key; the key must be unique */
  %LET lastkey = %SCAN(&keyvars., -1, %STR( ));
  PROC SORT DATA=&data. OUT=_mfi_040;
    BY &keyvars.;
  RUN;
  DATA _NULL_;
    SET _mfi_040 END=last;
    BY &keyvars.;
    IF NOT (FIRST.&lastkey. AND LAST.&lastkey.) THEN ndup + 1;
    IF last THEN CALL SYMPUTX("ndup", ndup);
  RUN;
  %IF &ndup. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the key &keyvars. is not unique: &ndup. records share a key.;
    %GOTO finish;
  %END;

  /* Step 050: ATTRIB before SET decides the attributes and the order.       */
  /* Step 030 proved that every value fits, so the WARNING about multiple   */
  /* lengths is expected: switch it off for this step only.                 */
  %LET oldchk = %SYSFUNC(GETOPTION(VARLENCHK));
  OPTIONS VARLENCHK=NOWARN;
  DATA &out.(%IF %SUPERQ(label) NE %THEN LABEL="&label."; KEEP=&keep.);
    ATTRIB %m_get_attrib(spec=_mfi_010, ds=&ds.);
    SET _mfi_040;
  RUN;
  OPTIONS VARLENCHK=&oldchk.;

  DATA _NULL_;
    IF 0 THEN SET &out. NOBS=nobs;
    CALL SYMPUTX("nrow", nobs, "L");
    STOP;
  RUN;
  %LET nvar = %SYSFUNC(COUNTW(&keep.));
  %PUT NOTE: [&macro.] &out.: &nrow. rows, &nvar. variables in specification order, key &keyvars. (version &mversion.);

  %finish:
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mfi_:;
    RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] Finished in %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &_starttime.), 0.01)) seconds.;
%MEND m_finalize;

/*******************************************************************************
  Macro       : %m_aseq
  Version     : 1.1
  Purpose     : Number the records of each subject in key order: ASEQ.
  Parameters  :
    data=     input data set (required)
    by=       the full key; the first variable is the subject (required)
    out=      output data set, sorted by the key, with ASEQ (required)
    debug=    N (default) deletes the work data sets _mas_:; Y keeps them
  Checks      : the key must be unique (ERR OR), or ASEQ means nothing
  Examples    :
    %m_aseq(data=adae, by=usubjid astdt aedecod aeseq, out=adae_seq)
  Change log  :
    2026-11-02  1.0  first version
    2026-11-02  1.1  debug= and the runtime NOTE (the checklist of 19.6)
*******************************************************************************/
%MACRO m_aseq(data=, by=, out=, debug=N) / DES = 'Derive ASEQ in key order';
  %LOCAL macro mversion _starttime p par subj lastkey ndup nrow maxseq;
  %LET macro      = %UPCASE(&SYSMACRONAME.);
  %LET mversion   = 1.1;
  %LET _starttime = %SYSFUNC(DATETIME());
  %DO p = 1 %TO 3;
    %LET par = %SCAN(data by out, &p.);
    %IF %SUPERQ(&par.) = %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] the parameter &par.= is required.;
      %RETURN;
    %END;
  %END;
  %IF NOT %SYSFUNC(EXIST(&data.)) %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the data set &data. does not exist.;
    %RETURN;
  %END;
  %LET subj    = %SCAN(&by., 1, %STR( ));
  %LET lastkey = %SCAN(&by., -1, %STR( ));

  /* Step 010: sort by the key and count records that share a key */
  PROC SORT DATA=&data. OUT=_mas_010;
    BY &by.;
  RUN;
  DATA _NULL_;
    SET _mas_010 END=last;
    BY &by.;
    IF NOT (FIRST.&lastkey. AND LAST.&lastkey.) THEN ndup + 1;
    IF last THEN CALL SYMPUTX("ndup", ndup);
  RUN;
  %IF &ndup. > 0 %THEN %DO;
    %PUT %STR(ERR)OR: [&macro.] the key &by. is not unique: &ndup. records share a key.;
    %GOTO finish;
  %END;

  /* Step 020: 1, 2, 3 ... per subject */
  DATA &out.;
    SET _mas_010;
    BY &subj.;
    IF FIRST.&subj. THEN aseq = 0;
    aseq + 1;
    LABEL aseq = "Analysis Sequence Number";
  RUN;
  DATA _NULL_;
    SET &out. END=last;
    RETAIN maxseq 0;
    maxseq = MAX(maxseq, aseq);
    IF last THEN DO;
      CALL SYMPUTX("nrow", _N_, "L");
      CALL SYMPUTX("maxseq", maxseq, "L");
    END;
  RUN;
  %PUT NOTE: [&macro.] &out.: &nrow. rows, ASEQ from 1 to at most &maxseq. per &subj. (version &mversion.);

  %finish:
  %IF %UPCASE(&debug.) NE Y %THEN %DO;
    PROC DATASETS LIBRARY=work NOLIST NOWARN;
      DELETE _mas_:;
    RUN; QUIT;
  %END;
  %PUT NOTE: [&macro.] Finished in %SYSFUNC(ROUND(%SYSEVALF(%SYSFUNC(DATETIME()) - &_starttime.), 0.01)) seconds.;
%MEND m_aseq;
