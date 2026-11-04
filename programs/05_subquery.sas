/* Chapter 5: subqueries */
PROC SQL;
  TITLE "Subjects of DM with at least one AE";
  SELECT usubjid, age
    FROM dm
    WHERE usubjid IN (SELECT usubjid FROM ae);

  TITLE "Subjects with a TEAE, as a share of the safety population";
  SELECT COUNT(DISTINCT usubjid)                                  AS n_teae,
         (SELECT COUNT(*) FROM refadm.adsl WHERE saffl = "Y")     AS bign,
         CALCULATED n_teae / CALCULATED bign * 100                AS pct FORMAT=5.1
    FROM refadm.adae
    WHERE trtemfl = "Y";
QUIT;
TITLE;
