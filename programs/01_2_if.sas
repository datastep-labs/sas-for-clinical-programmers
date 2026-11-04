/* Chapter 1: IF, THEN and ELSE make a new variable from an old one */
DATA adsl_age;
  LENGTH agegrp $11;
  SET refadm.adsl(KEEP=usubjid arm age);
  IF age >= 65 THEN agegrp = "65 or older";
  ELSE              agegrp = "under 65";
RUN;

PROC FREQ DATA=adsl_age;
  TABLES agegrp;
RUN;
