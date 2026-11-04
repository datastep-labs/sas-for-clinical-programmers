/* Chapter 18: lists of values from the data */

/* Step 010: one record per parameter */
PROC SORT DATA=refadm.advs(KEEP=paramcd param) OUT=param_list NODUPKEY;
  BY paramcd;
RUN;

/* Step 020: the whole list in one macro variable, and one macro variable per value */
DATA _NULL_;
  SET param_list END=eof;
  LENGTH params $200;
  RETAIN params;
  params = CATX(" ", params, paramcd);
  CALL SYMPUTX(CATS("pcd", _N_), paramcd);
  CALL SYMPUTX(CATS("plab", _N_), param);
  IF eof THEN DO;
    CALL SYMPUTX("params", params);
    CALL SYMPUTX("nparam", _N_);
  END;
RUN;
%PUT NOTE: &=params. &=nparam.;
%PUT NOTE: &=pcd1. &=plab1.;

/* CALL SYMPUTX: a value computed in a DATA step */
DATA _NULL_;
  SET refadm.adsl END=eof;
  IF saffl = "Y" THEN nsaf + 1;
  IF eof THEN CALL SYMPUTX("nsaf", nsaf);
RUN;
%PUT NOTE: &=nsaf.;
