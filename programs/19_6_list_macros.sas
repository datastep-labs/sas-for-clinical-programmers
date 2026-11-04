/* Chapter 19: a tool about programs (design rule 12): list the macro definitions in a folder */

/*******************************************************************************
  Macro            : %m_list_macros
  Version          : 1.0
  Purpose          : Read every .sas file of a folder and list each %MACRO
                     statement with its file and line number: a table of
                     contents of a macro folder.
  Parameters       :
    dir=             the folder (default . = the folder of the program, as
                     DataStep Studio runs it)
    out=             the output data set: file, line, macro (default macros)
  Examples         :
    %m_list_macros()
    %m_list_macros(dir=%SYSFUNC(PATHNAME(work)), out=demo_macros)
  Preconditions    : &dir. exists and has .sas files
  Postconditions   : &out. has one row per %MACRO statement
  Validation level : review
  Change history   :
    2026-11-02  1.0  first version
*******************************************************************************/
%MACRO m_list_macros(dir=., out=macros) / DES = 'List the macro definitions in a folder';
  %LOCAL macro nrow;
  %LET macro = %UPCASE(&SYSMACRONAME.);
  DATA &out.(KEEP=file line macro);
    LENGTH _mlm_fn $512 file $128 macro $32;
    /* the wildcard reads every .sas file; EOV= is 1 on the first line of each next file */
    INFILE "&dir./*.sas" FILENAME=_mlm_fn EOV=_mlm_new TRUNCOVER LRECL=32767;
    INPUT;
    IF _N_ = 1 OR _mlm_new THEN DO;
      line     = 0;
      _mlm_new = 0;
    END;
    line + 1;
    file = SCAN(_mlm_fn, -1, "/\");
    /* single quotes: the macro processor does not look inside them */
    IF PRXMATCH('/^\s*%MACRO\s+\w/i', _INFILE_) THEN DO;
      macro = PRXCHANGE('s/^\s*%MACRO\s+(\w+).*/$1/i', 1, _INFILE_);
      OUTPUT;
    END;
  RUN;
  DATA _NULL_;
    IF 0 THEN SET &out. NOBS=nobs;
    CALL SYMPUTX("nrow", nobs, "L");
    STOP;
  RUN;
  %PUT NOTE: [&macro.] &out.: &nrow. macro definitions in &dir..;
%MEND m_list_macros;

/* A small demo folder: two program files in the WORK folder, three macros */
%LET demo = %SYSFUNC(PATHNAME(work));
DATA _NULL_;
  FILE "&demo./demo_a.sas";
  PUT '/* demo program A */';
  PUT '%MACRO alpha(data=);';
  PUT '%MEND alpha;';
  FILE "&demo./demo_b.sas";
  PUT '/* demo program B */';
  PUT '  %MACRO beta(out=) / DES = ''Beta'';';
  PUT '  %MEND beta;';
  PUT '%MACRO _gamma;';
  PUT '%MEND _gamma;';
RUN;

%m_list_macros(dir=&demo., out=demo_macros)
PROC PRINT DATA=demo_macros NOOBS;
RUN;
