/* Chapter 6: subjects with at least one TEAE, by treatment */
PROC SQL;
  CREATE TABLE teae_n AS
    SELECT a.trt01an, a.trt01a,
           COUNT(DISTINCT a.usubjid)                 AS bign,
           COUNT(DISTINCT b.usubjid)                 AS n_teae,
           CALCULATED n_teae / CALCULATED bign * 100 AS pct FORMAT=5.1
      FROM refadm.adsl(WHERE=(saffl = "Y")) AS a
           LEFT JOIN refadm.adae(WHERE=(trtemfl = "Y")) AS b
           ON a.usubjid = b.usubjid
      GROUP BY a.trt01an, a.trt01a
      ORDER BY a.trt01an;
QUIT;

PROC PRINT DATA=teae_n NOOBS; RUN;
