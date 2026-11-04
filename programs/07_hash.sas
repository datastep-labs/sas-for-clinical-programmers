/* Chapter 7: three ways to look up TRTSDT from ADSL for every VS record */

/* Way 1: PROC SQL with a left join: no sort needed, SAS does the matching */
PROC SQL;
  CREATE TABLE vs_sql AS
    SELECT v.usubjid, v.vsseq, v.vstestcd, v.vsstresn, a.trtsdt
      FROM sdtm.vs AS v LEFT JOIN refadm.adsl AS a
           ON v.usubjid = a.usubjid
      ORDER BY v.usubjid, v.vsseq;
QUIT;

/* Way 2: a format built from ADSL: the key is the text USUBJID, the label the date as text */
DATA trtsdt_fmt;
  SET refadm.adsl(KEEP=usubjid trtsdt) END=last;
  LENGTH fmtname $8 type $1 start $40 label $12;
  fmtname = "trtsdt";
  type    = "C";
  start   = usubjid;
  label   = PUT(trtsdt, 8.);
  OUTPUT;
  /* subjects that are not in ADSL get a missing date */
  IF last THEN DO;
    hlo   = "O";
    label = ".";
    OUTPUT;
  END;
  KEEP fmtname type start label hlo;
RUN;
PROC FORMAT CNTLIN=trtsdt_fmt;
RUN;
DATA vs_fmt;
  SET sdtm.vs(KEEP=usubjid vsseq vstestcd vsstresn);
  trtsdt = INPUT(PUT(usubjid, $trtsdt.), 8.);
  FORMAT trtsdt DATE9.;
  LABEL  trtsdt = "Date of First Exposure to Treatment";
RUN;

/* Way 3: a hash object: ADSL is loaded into memory once, then each VS record asks it */
DATA vs_hash;
  IF _N_ = 1 THEN DO;
    IF 0 THEN SET refadm.adsl(KEEP=usubjid trtsdt);
    DECLARE HASH h(DATASET: "refadm.adsl(KEEP=usubjid trtsdt)");
    h.DEFINEKEY("usubjid");
    h.DEFINEDATA("trtsdt");
    h.DEFINEDONE();
  END;
  SET sdtm.vs(KEEP=usubjid vsseq vstestcd vsstresn);
  /* FIND returns 0 when the key is found; otherwise TRTSDT must be set to missing */
  IF h.FIND() NE 0 THEN CALL MISSING(trtsdt);
RUN;

PROC SQL NOPRINT;
  SELECT COUNT(*), NMISS(trtsdt) INTO :nrec TRIMMED, :nmiss TRIMMED FROM vs_hash;
QUIT;
%PUT NOTE: VS records &nrec., without TRTSDT &nmiss.;
