/* Chapter 6: the shape of a query */
PROC SQL;
  SELECT trt01a, COUNT(*) AS n
    FROM refadm.adsl
    WHERE saffl = "Y"
    GROUP BY trt01a;
QUIT;
