/* Chapter 7: formats in depth: ranges, OTHER, INVALUE, PICTURE and MULTILABEL */
PROC FORMAT;
  /* ranges: < excludes the end point; LOW does not catch a missing value, OTHER does */
  VALUE agegrp  LOW -< 65  = "<65"
                65 - 80    = "65-80"
                80 <- HIGH = ">80"
                OTHER      = "Missing";
  /* an informat reads text into a number */
  INVALUE sevn  "MILD"     = 1
                "MODERATE" = 2
                "SEVERE"   = 3
                OTHER      = .;
  /* a picture format writes a number into a template: 75.58 becomes (75.6%) */
  PICTURE pctf (ROUND)  LOW - HIGH = "009.9%)" (PREFIX="(");
  /* MULTILABEL: one value may belong to more than one group, for example a Total column */
  VALUE trtml (MULTILABEL NOTSORTED)
                0         = "Placebo"
                54        = "Xanomeline Low Dose"
                81        = "Xanomeline High Dose"
                54, 81    = "Xanomeline Total"
                0, 54, 81 = "Total";
RUN;

/* Step 010: PUT with the age format makes the age groups of ADSL */
DATA age_check;
  SET refadm.adsl(KEEP=usubjid age agegr1);
  LENGTH agegrp $7;
  agegrp = PUT(age, agegrp.);
RUN;
TITLE1 "AGEGR1 from ADSL against PUT(age, agegrp.)";
PROC FREQ DATA=age_check;
  TABLES agegr1 * agegrp / LIST NOCUM NOPERCENT;
RUN;

/* Step 020: INPUT with the informat gives a number that sorts by severity */
DATA ae_sev;
  SET refadm.adae(KEEP=usubjid aesev WHERE=(NOT MISSING(aesev)));
  aesevn = INPUT(aesev, sevn.);
RUN;
TITLE1 "AESEV and the number from the informat";
PROC FREQ DATA=ae_sev;
  TABLES aesevn * aesev / LIST NOCUM NOPERCENT;
RUN;

/* Step 030: the picture format */
DATA pct_demo;
  pct = 65 / 86 * 100;
  txt = PUT(pct, pctf.);
  PUTLOG "NOTE: " pct= txt=;
RUN;

/* Step 040: MULTILABEL needs MLF on the CLASS statement; PRELOADFMT ORDER=DATA keeps the order of the format */
TITLE1 "Age with a Xanomeline Total and a Total column";
PROC MEANS DATA=refadm.adsl N MEAN MAXDEC=1;
  WHERE saffl = "Y";
  CLASS trt01an / MLF PRELOADFMT ORDER=DATA;
  FORMAT trt01an trtml.;
  VAR age;
RUN;

/* Step 050: where SAS looks for formats, and what one format contains */
OPTIONS FMTSEARCH=(work);
TITLE1 "The format AGEGRP";
PROC FORMAT FMTLIB;
  SELECT agegrp;
RUN;
TITLE;
