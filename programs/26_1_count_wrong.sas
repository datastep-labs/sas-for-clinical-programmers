/* Chapter 26: a count that is too high */
PROC SQL;
  CREATE TABLE sev_count AS
    SELECT trta, COUNT(*) AS n_subj
      FROM refadm.adae
      WHERE trtemfl = "Y" AND aesev = "SEVERE"
      GROUP BY trta;
QUIT;
