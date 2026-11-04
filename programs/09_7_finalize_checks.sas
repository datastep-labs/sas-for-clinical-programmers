/* EXPECT: ERROR [M_FINALIZE] */
/* EXPECT: ERROR [M_ASEQ] */
/* Chapter 9: the checks of %m_finalize and %m_aseq, each one fired on purpose (needs 09_1, 09_5 and 09_6) */

/* Check 1: a value is longer than the specification allows */
DATA adsl_long;
  SET adsl;
  IF _N_ = 1 THEN race = "AMERICAN INDIAN OR ALASKA NATIVE, OTHER";
RUN;
%m_finalize(data=adsl_long, spec=spec, ds=ADSL, out=adsl_x1)

/* Check 2: a variable of the specification is not in the data */
%m_finalize(data=adsl(DROP=bmibl), spec=spec, ds=ADSL, out=adsl_x2)

/* Check 3: a key that is not unique: SITEID alone does not identify a subject */
%m_aseq(data=adsl, by=siteid, out=adsl_x3)
