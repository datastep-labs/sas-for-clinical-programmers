/* Chapter 18: one summary per parameter, driven by the data */
%MACRO by_param(data=);
  %LOCAL i n;
  /* one record per parameter, then one macro variable per value */
  PROC SORT DATA=&data.(KEEP=paramcd param) OUT=_bp_010 NODUPKEY;
    BY paramcd;
  RUN;
  DATA _NULL_;
    SET _bp_010 END=eof;
    CALL SYMPUTX(CATS("_pcd", _N_), paramcd, "L");
    CALL SYMPUTX(CATS("_plab", _N_), param, "L");
    IF eof THEN CALL SYMPUTX("n", _N_, "L");
  RUN;
  %DO i = 1 %TO &n.;
    TITLE "Baseline &&_plab&i.";
    PROC MEANS DATA=&data.(WHERE=(paramcd = "&&_pcd&i." AND ablfl = "Y")) N MEAN STD MAXDEC=1;
      CLASS trtpn;
      VAR aval;
    RUN;
  %END;
  TITLE;
%MEND by_param;

%by_param(data=refadm.advs)
