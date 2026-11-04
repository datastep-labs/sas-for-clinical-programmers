/* Chapter 18: a variable specification from the metadata, the core of define.xml (needs ADSL from 09_1) */

/* Step 010: the specification: one row per variable of the reference ADSL */
PROC CONTENTS DATA=refadm.adsl OUT=spec_010(KEEP=varnum name type length label format) NOPRINT;
RUN;

DATA spec_adsl;
  LENGTH variable $32;
  SET spec_010;
  variable = UPCASE(name);
  DROP name;
RUN;

PROC SORT DATA=spec_adsl;
  BY varnum;
RUN;

TITLE "The variable specification of ADSL (first 8 rows)";
PROC PRINT DATA=spec_adsl(OBS=8) NOOBS;
  VAR varnum variable type length label format;
RUN;
TITLE;

/* Step 020: a macro that checks a data set against the specification */
%MACRO spec_check(data=, spec=, label=);
  PROC CONTENTS DATA=&data. OUT=_sc_010(KEEP=name length label) NOPRINT;
  RUN;
  PROC SQL NOPRINT;
    SELECT COUNT(*), SUM(o.label NE s.label), SUM(o.length NE s.length)
      INTO :n_both TRIMMED, :n_label TRIMMED, :n_length TRIMMED
      FROM _sc_010 AS o INNER JOIN &spec. AS s ON UPCASE(o.name) = s.variable;
  QUIT;
  %PUT NOTE: &label.: &n_both. variables in both, &n_label. other labels, &n_length. other lengths;
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _sc_:;
  RUN; QUIT;
%MEND spec_check;

%spec_check(data=adsl, spec=spec_adsl, label=Before)

/* Step 030: the specification writes the ATTRIB statement for the shared variables */
PROC CONTENTS DATA=adsl OUT=our_vars(KEEP=name) NOPRINT;
RUN;

PROC SQL NOPRINT;
  SELECT CATX(" ", s.variable,
              CATS("LENGTH=", IFC(s.type = 2, "$", ""), s.length),
              CATS("LABEL=", QUOTE(TRIM(s.label))))
    INTO :attrib SEPARATED BY " "
    FROM spec_adsl AS s
    WHERE s.variable IN (SELECT UPCASE(name) FROM our_vars);
QUIT;
/* %QSUBSTR, not %SUBSTR: the cut can fall inside a quoted label, and an unquoted half quote would swallow the rest of the program */
%PUT NOTE: ATTRIB starts with: %QSUBSTR(%SUPERQ(attrib), 1, 90);

/* Step 035: a shorter length cuts values: check first that every value fits */
PROC CONTENTS DATA=adsl OUT=our_len(KEEP=name length) NOPRINT;
RUN;

PROC SQL NOPRINT;
  SELECT CATS("MAX(LENGTH(", o.name, "))"), CATS(s.length), o.name
    INTO :maxlist SEPARATED BY ", ", :speclen SEPARATED BY " ", :shorter SEPARATED BY " "
    FROM our_len AS o INNER JOIN spec_adsl AS s ON UPCASE(o.name) = s.variable
    WHERE o.length > s.length;
  SELECT CATX(" ", &maxlist.) INTO :maxlen TRIMMED FROM adsl;
QUIT;
%PUT NOTE: shorter in the specification: &shorter.;
%PUT NOTE: specification lengths &speclen., longest values &maxlen.;

/* Step 040: apply it: ATTRIB before SET decides the attributes.                 */
/* The values fit (step 035), so the WARNING about multiple lengths is expected: */
/* switch it off for this step only, and back on after it.                      */
OPTIONS VARLENCHK=NOWARN;
DATA adsl_spec;
  ATTRIB &attrib.;
  SET adsl;
RUN;
OPTIONS VARLENCHK=WARN;

%spec_check(data=adsl_spec, spec=spec_adsl, label=After)
