/* Chapter 5: inner, left and full join of the same two tables */
PROC SQL;
  TITLE "Inner join";
  SELECT dm.usubjid, dm.age, ae.aedecod
    FROM dm INNER JOIN ae
    ON dm.usubjid = ae.usubjid;

  TITLE "Left join";
  SELECT dm.usubjid, dm.age, ae.aedecod
    FROM dm LEFT JOIN ae
    ON dm.usubjid = ae.usubjid;

  TITLE "Full join";
  SELECT COALESCE(dm.usubjid, ae.usubjid) AS usubjid, dm.age, ae.aedecod
    FROM dm FULL JOIN ae
    ON dm.usubjid = ae.usubjid;
QUIT;
TITLE;
