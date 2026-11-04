/* Chapter 13: the AE overview by hand, one small data set per row */

/* Step 010: the big N of each treatment, from ADSL (one record per subject), into n0 n54 n81 */
PROC FREQ DATA=refadm.adsl(WHERE=(saffl = "Y")) NOPRINT;
  TABLES trt01an / OUT=ov_bign;
RUN;
DATA _NULL_;
  SET ov_bign;
  CALL SYMPUTX(CATS("n", trt01an), count);
RUN;

/* Step 020: one data set per row: the subjects with such an event, one record each */
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y"))
          OUT=ov_any NODUPKEY; BY trtan usubjid; RUN;
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y" AND aerel IN ("POSSIBLE" "PROBABLE")))
          OUT=ov_rel NODUPKEY; BY trtan usubjid; RUN;
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y" AND aeser = "Y"))
          OUT=ov_ser NODUPKEY; BY trtan usubjid; RUN;
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y" AND aesev = "SEVERE"))
          OUT=ov_sev NODUPKEY; BY trtan usubjid; RUN;
PROC SORT DATA=refadm.adae(WHERE=(saffl = "Y" AND trtemfl = "Y" AND aesdth = "Y"))
          OUT=ov_dth NODUPKEY; BY trtan usubjid; RUN;

/* Step 030: stack the rows, then count the subjects of each row and treatment */
DATA ov_030;
  LENGTH label $60;
  SET ov_any(IN=in1) ov_rel(IN=in2) ov_ser(IN=in3) ov_sev(IN=in4) ov_dth(IN=in5);
  IF      in1 THEN DO; sub = 1; label = "Subjects with at least one TEAE";        END;
  ELSE IF in2 THEN DO; sub = 2; label = "Subjects with a related TEAE";           END;
  ELSE IF in3 THEN DO; sub = 3; label = "Subjects with a serious TEAE";           END;
  ELSE IF in4 THEN DO; sub = 4; label = "Subjects with a severe TEAE";            END;
  ELSE IF in5 THEN DO; sub = 5; label = "Subjects with a TEAE that led to death"; END;
  KEEP sub label trtan usubjid;
RUN;
PROC FREQ DATA=ov_030 NOPRINT;
  TABLES sub * label * trtan / OUT=ov_cnt;
RUN;

/* Step 040: one column per treatment; a missing count means nobody, so the cell is 0 */
PROC TRANSPOSE DATA=ov_cnt OUT=ov_wide(DROP=_name_ _label_) PREFIX=n;
  BY sub label;
  ID trtan;
  VAR count;
RUN;
DATA ov_layout;
  LENGTH c0 c54 c81 $20;
  SET ov_wide;
  ARRAY n{3} n0 n54 n81;
  ARRAY c{3} $ c0 c54 c81;
  ARRAY bign{3} _TEMPORARY_ (&n0. &n54. &n81.);
  DO i = 1 TO 3;
    IF MISSING(n{i}) THEN c{i} = "0";
    ELSE c{i} = CATX(" ", PUT(n{i}, 4.), CATS("(", PUT(n{i} / bign{i} * 100, 5.1), ")"));
  END;
  DROP i n0 n54 n81;
RUN;

OPTIONS LS=132 PS=60 NOCENTER;
TITLE1 "Table 14.3.0 Overview of treatment emergent adverse events (safety population)";
PROC REPORT DATA=ov_layout NOWD HEADLINE SPLIT="|";
  COLUMN sub label c0 c54 c81;
  DEFINE sub   / ORDER NOPRINT;
  DEFINE label / DISPLAY " " WIDTH=40;
  DEFINE c0    / DISPLAY "Placebo|(N=&n0.)"              WIDTH=20 CENTER;
  DEFINE c54   / DISPLAY "Xanomeline Low Dose|(N=&n54.)"  WIDTH=20 CENTER;
  DEFINE c81   / DISPLAY "Xanomeline High Dose|(N=&n81.)" WIDTH=20 CENTER;
RUN;
TITLE;
