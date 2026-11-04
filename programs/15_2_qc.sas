/* Chapter 15: an independent QC version, written with PROC SQL */
PROC SQL;
  CREATE TABLE qc AS
    SELECT d.usubjid, d.age,
           CASE WHEN d.age < 65  THEN "<65"
                WHEN d.age <= 80 THEN "65-80"
                WHEN d.age > 80  THEN ">80"
                ELSE "" END                               AS agegr1 LENGTH=5,
           MIN(INPUT(e.exstdtc, E8601DA.))                AS trtsdt FORMAT=DATE9.,
           MAX(CASE WHEN NOT MISSING(e.exendtc)
                    THEN INPUT(e.exendtc, E8601DA.) ELSE . END) AS trtedt FORMAT=DATE9.,
           CASE WHEN CALCULATED trtedt NE . AND CALCULATED trtsdt NE .
                THEN CALCULATED trtedt - CALCULATED trtsdt + 1
                ELSE . END                                AS trtdurd
      FROM sdtm.dm(WHERE=(armcd NE "Scrnfail")) AS d
           LEFT JOIN sdtm.ex AS e
           ON d.usubjid = e.usubjid
      GROUP BY d.usubjid, d.age
      ORDER BY d.usubjid;
QUIT;
