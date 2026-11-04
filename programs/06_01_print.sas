/* Chapter 6: look at a data set with PROC CONTENTS and PROC PRINT */

/* the variables: name, type, length, format and label, in data set order */
TITLE1 "ADSL: the first ten variables";
/* ODS SELECT keeps two of the tables: the data set facts and the variables */
ODS SELECT Attributes Position;
PROC CONTENTS DATA=refadm.adsl(KEEP=studyid--trt01an) VARNUM;
RUN;

/* five records, with labels as column headers */
TITLE1 "ADSL: the first five subjects of the safety population";
FOOTNOTE1 "Source: refadm.adsl";
PROC PRINT DATA=refadm.adsl(OBS=5) LABEL NOOBS;
  WHERE saffl = "Y";
  ID usubjid;
  VAR trt01a age sex race;
RUN;

/* switch the titles and footnotes off again */
TITLE;
FOOTNOTE;
