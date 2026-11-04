/* Chapter 16: a check program tests your assumptions before you derive */
PROC SQL;
  TITLE "Check 1: Randomised subjects without any EX record";
  SELECT COUNT(*) AS n_subjects
    FROM sdtm.dm
    WHERE armcd NE "Scrnfail" AND usubjid NOT IN (SELECT usubjid FROM sdtm.ex);

  TITLE "Check 2: EX records without an end date";
  SELECT COUNT(*) AS n_records
    FROM sdtm.ex
    WHERE MISSING(exendtc);

  TITLE "Check 3: EX records that end before they start";
  SELECT COUNT(*) AS n_records
    FROM sdtm.ex
    WHERE NOT MISSING(exendtc) AND exendtc < exstdtc;

  TITLE "Check 4: DM subjects with more than one record";
  SELECT COUNT(*) AS n_subjects
    FROM (SELECT usubjid FROM sdtm.dm GROUP BY usubjid HAVING COUNT(*) > 1);

  TITLE "Check 5: Subjects whose RFXSTDTC is not their first EX start";
  SELECT COUNT(*) AS n_subjects
    FROM sdtm.dm AS d,
         (SELECT usubjid, MIN(exstdtc) AS first_ex FROM sdtm.ex GROUP BY usubjid) AS e
    WHERE d.usubjid = e.usubjid AND d.rfxstdtc NE e.first_ex;
QUIT;
TITLE;
