/* Chapter 18: DOSUBL runs code now and gives the result back */
DATA counts;
  SET plist;
  rc = DOSUBL(CATS('DATA _NULL_; SET refadm.advs(WHERE=(paramcd = "', paramcd,
                   '")) END=eof; IF eof THEN CALL SYMPUTX("n", _N_, "G"); RUN;'));
  n  = INPUT(SYMGET("n"), ?? BEST.);
RUN;

PROC PRINT DATA=counts NOOBS;
RUN;
