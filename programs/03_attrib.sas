/* Chapter 3: ATTRIB sets length and label before the first use */
DATA fixed;
  ATTRIB agegrp LENGTH=$11 LABEL="Age group";
  SET refadm.adsl(OBS=3 KEEP=usubjid age);
  IF age < 65 THEN agegrp = "<65";
  ELSE             agegrp = "65 or older";
RUN;

PROC PRINT DATA=fixed NOOBS LABEL; RUN;
PROC CONTENTS DATA=fixed VARNUM; RUN;
