/* Chapter 19: a small test harness for the macro */
%MACRO tc(id, desc);
  %PUT ===== TEST &id. &desc.;
%MEND tc;

FILENAME tlog "%SYSFUNC(PATHNAME(work))/tests.log";
PROC PRINTTO LOG=tlog NEW; RUN;

%tc(T01, subjects with a TEAE by treatment)
%count_subj(data=refadm.adae, by=trtan, where=%STR(trtemfl = "Y"), out=t01)
%tc(T02, subjects by treatment and sex)
%count_subj(data=refadm.adsl, by=trt01pn sex, out=t02)
%tc(E01, a data set that does not exist)
%count_subj(data=work.nothere, by=trtan)
%tc(E02, no DATA= parameter)
%count_subj(by=trtan)

PROC PRINTTO LOG=LOG; RUN;

/* Scan the log: one record per test start and per message */
DATA scan(KEEP=test kind);
  INFILE tlog TRUNCOVER;
  INPUT line $CHAR200.;
  LENGTH test $8 kind $7;
  RETAIN test;
  /* the message words are built from two parts, so this program's own source never matches */
  IF      line =: "===== TEST"      THEN DO;
    test = SCAN(line, 3, " ");
    kind = "start";
  END;
  ELSE IF line =: CATS("ERR", "OR")   THEN kind = "error";
  ELSE IF line =: CATS("WAR", "NING") THEN kind = "warning";
  IF NOT MISSING(kind) THEN OUTPUT;
RUN;

/* A test passes with no message; an E test passes with exactly one error */
PROC SORT DATA=scan;
  BY test;
RUN;
DATA result(KEEP=test errors warnings result);
  SET scan;
  BY test;
  IF FIRST.test THEN DO;
    errors   = 0;
    warnings = 0;
  END;
  errors   + (kind = "error");
  warnings + (kind = "warning");
  IF LAST.test;
  IF warnings = 0 AND ((test =: "E" AND errors = 1) OR (test =: "T" AND errors = 0)) THEN result = "pass";
  ELSE result = "FAIL";
RUN;
PROC PRINT DATA=result NOOBS;
RUN;
