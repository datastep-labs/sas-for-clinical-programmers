/* Chapter 15: a log check, the same idea as the Suspicious Log */
%MACRO logcheck(file=);
  DATA _lc;
    INFILE "&file." TRUNCOVER;
    INPUT line $CHAR256.;
    LENGTH kind $45;
    /* the message words are built from two parts, so this program's own source never matches */
    IF      line =: CATS("ERR", "OR")                              THEN kind = "ERROR";
    ELSE IF line =: CATS("WAR", "NING")                            THEN kind = "WARNING";
    ELSE IF INDEX(line, "is uninitialized")                        THEN kind = "NOTE: uninitialized";
    ELSE IF INDEX(line, "Missing values were generated")           THEN kind = "NOTE: missing values generated";
    ELSE IF INDEX(line, "repeats of BY values")                    THEN kind = "NOTE: repeats of BY values";
    ELSE IF INDEX(line, "remerging summary statistics")            THEN kind = "NOTE: remerging";
    ELSE IF INDEX(line, "values have been converted")              THEN kind = "NOTE: type conversion";
    ELSE IF INDEX(line, "Invalid data")                            THEN kind = "NOTE: invalid data";
    ELSE IF INDEX(line, "Division by zero")                        THEN kind = "NOTE: division by zero";
    IF NOT MISSING(kind);
  RUN;
  TITLE "Log check of %SCAN(&file., -1, /)";
  PROC FREQ DATA=_lc;
    TABLES kind / NOCUM NOPERCENT;
  RUN;
  TITLE;
%MEND logcheck;

/* Write the log of a step with problems to a file, then check that file */
FILENAME demolog "%SYSFUNC(PATHNAME(work))/demo.log";
PROC PRINTTO LOG=demolog NEW; RUN;

DATA demo;
  SET sdtm.dm(OBS=3);
  siteid_num = siteid + 0;
  bmi        = weight / height**2;
RUN;

PROC PRINTTO LOG=LOG; RUN;

%logcheck(file=%SYSFUNC(PATHNAME(work))/demo.log)
