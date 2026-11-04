/* Chapter 2: a format groups values without changing them */
PROC FORMAT;
  VALUE agegr LOW -< 65 = "<65"
              65  -< 81 = "65-80"
              81 - HIGH = ">80";
RUN;

PROC FREQ DATA=dm_rand;
  TABLES age / NOCUM;
  FORMAT age agegr.;
RUN;
