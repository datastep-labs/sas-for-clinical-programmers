/* Chapter 10: analysis windows by study day, the other way to assign a visit (needs ADVS from 10_1) */

/* Step 010: the windows as data: one row per planned visit */
/* target day 7 * week + 1; the limits lie halfway between two targets; a tie goes to the later visit */
DATA windows;
  LENGTH avisit $20;
  ARRAY wk{9} _TEMPORARY_ (2 4 6 8 12 16 20 24 26);
  DO i = 1 TO 9;
    avisitn  = wk{i};
    avisit   = CATX(" ", "Week", wk{i});
    awtarget = 7 * wk{i} + 1;
    IF i < 9 THEN awhi = CEIL((awtarget + 7 * wk{i + 1} + 1) / 2) - 1;
    ELSE          awhi = .;
    IF i = 1 THEN awlo = 2;
    OUTPUT;
    IF i < 9 THEN awlo = awhi + 1;
  END;
  DROP i;
RUN;

PROC PRINT DATA=windows NOOBS; VAR avisit avisitn awlo awtarget awhi; RUN;

/* Step 020: the post-baseline weights, with the visit they were collected at */
DATA post;
  SET advs(KEEP=usubjid vsseq visit ady aval avisitn);
  WHERE avisitn > 0;
  nominal = avisitn;
  DROP avisitn;
RUN;

/* Step 030: each record goes to the window that contains its study day */
/* the last window has no upper limit (awhi missing) */
PROC SQL;
  CREATE TABLE advs_win AS
    SELECT p.*, w.avisit, w.avisitn, w.awlo, w.awtarget, w.awhi, p.ady - w.awtarget AS awtdiff
      FROM post AS p LEFT JOIN windows AS w
           ON p.ady >= w.awlo AND (p.ady <= w.awhi OR MISSING(w.awhi))
      ORDER BY p.usubjid, p.ady, p.vsseq;
QUIT;

/* Step 040: how many weights land in another visit than the one they were collected at? */
DATA moved;
  SET advs_win;
  LENGTH result $20;
  IF      MISSING(avisitn)   THEN result = "outside all windows";
  ELSE IF avisitn = nominal  THEN result = "same visit";
  ELSE                            result = "other visit";
RUN;

PROC FREQ DATA=moved; TABLES result / NOCUM; RUN;

PROC PRINT DATA=advs_win(WHERE=(usubjid = "01-705-1292")) NOOBS;
  VAR usubjid visit ady nominal avisit awtarget awtdiff;
RUN;
