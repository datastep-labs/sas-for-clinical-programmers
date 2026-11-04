/* EXPECT: WARNING Apparent invocation of macro FL not resolved */
/* Chapter 6: a percent sign in double quotes calls the macro processor */
PROC SQL NOPRINT;
  SELECT name INTO :flvars SEPARATED BY " "
    FROM dictionary.columns
    WHERE libname = "REFADM" AND memname = "ADSL" AND name LIKE "%FL";
QUIT;
