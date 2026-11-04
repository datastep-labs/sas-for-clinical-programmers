/* Chapter 26: the same count, one subject counted once */
PROC SQL;
  CREATE TABLE sev_count AS
    SELECT trta, COUNT(DISTINCT usubjid) AS n_subj
      FROM refadm.adae
      WHERE trtemfl = "Y" AND aesev = "SEVERE"
      GROUP BY trta;
QUIT;
