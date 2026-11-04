/* Chapter 18: CALL EXECUTE and the timing trap */
%MACRO count_param(paramcd=);
  DATA _NULL_;
    SET refadm.advs(WHERE=(paramcd = "&paramcd.")) END=eof;
    IF eof THEN CALL SYMPUTX("n", _N_);
  RUN;
  %PUT NOTE: &paramcd. has &n. records;
%MEND count_param;

PROC SORT DATA=refadm.advs(KEEP=paramcd WHERE=(paramcd IN ("PULSE" "SYSBP"))) OUT=plist NODUPKEY;
  BY paramcd;
RUN;

%LET n = (not counted yet);

/* Trap: the macro runs while this DATA step runs, before the step that counts */
DATA _NULL_;
  SET plist;
  CALL EXECUTE(CATS('%count_param(paramcd=', paramcd, ')'));
RUN;

/* Fix: %NRSTR delays the call until the step has ended */
DATA _NULL_;
  SET plist;
  CALL EXECUTE(CATS('%NRSTR(%count_param(paramcd=', paramcd, '))'));
RUN;
