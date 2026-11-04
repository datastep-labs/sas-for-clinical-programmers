/* EXPECT: WARNING Apparent symbolic reference WHEN not resolved */
/* Chapter 17: macro code runs before the DATA step runs */
%SYMDEL when / NOWARN;

DATA _NULL_;
  CALL SYMPUTX("when", "set while the step runs");
  PUT "inside the step: &when.";
RUN;

%PUT NOTE: after the step: &=when.;
