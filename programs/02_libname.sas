/* Chapter 2: a permanent data set. LIBNAME gives a folder a short name */
OPTIONS DLCREATEDIR;
LIBNAME mylib "%SYSGET(HOME)/sasbook/mylib";

DATA mylib.dm_rand;
  SET sdtm.dm(KEEP=usubjid siteid age sex armcd arm);
  WHERE armcd NE "Scrnfail";
RUN;

PROC CONTENTS DATA=mylib.dm_rand SHORT;
RUN;
