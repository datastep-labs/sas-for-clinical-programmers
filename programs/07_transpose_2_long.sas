/* Chapter 7: wide back to long */
PROC TRANSPOSE DATA=vswide(OBS=2) OUT=vslong(RENAME=(col1=aval)) NAME=paramcd;
  BY usubjid;
  VAR diabpbl pulsebl sysbpbl;
RUN;

PROC PRINT DATA=vslong NOOBS; RUN;
