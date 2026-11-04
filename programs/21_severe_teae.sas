/* Chapter 21: check what the data viewer showed, severe treatment-emergent AEs */
PROC SQL;
  SELECT trta, COUNT(*) AS n_rec, COUNT(DISTINCT usubjid) AS n_subj
    FROM refadm.adae
    WHERE trtemfl = "Y" AND aesev = "SEVERE"
    GROUP BY trta;
QUIT;
