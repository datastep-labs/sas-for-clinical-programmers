/* Chapter 1: PROC SQL counts subjects, not records */
PROC SQL;
  SELECT trta, COUNT(*) AS records, COUNT(DISTINCT usubjid) AS subjects
    FROM refadm.adae
    WHERE trtemfl = "Y"
    GROUP BY trta;
QUIT;
