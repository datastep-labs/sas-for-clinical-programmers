/* Chapter 6: CASE, and the set operators UNION, INTERSECT and EXCEPT */
PROC SQL;
  /* CASE: a new column from a rule, as IF-THEN-ELSE in a DATA step */
  CREATE TABLE agecat AS
    SELECT usubjid, age,
           CASE WHEN age < 65  THEN "<65"
                WHEN age <= 80 THEN "65-80"
                ELSE ">80"
           END AS agecat LENGTH=5
      FROM refadm.adsl
      WHERE saffl = "Y";
  TITLE1 "Age groups made with CASE";
  SELECT agecat, COUNT(*) AS n
    FROM agecat
    GROUP BY agecat;

  /* one row per subject in each list */
  CREATE TABLE ae_subj AS SELECT DISTINCT usubjid FROM sdtm.ae;
  CREATE TABLE cm_subj AS SELECT DISTINCT usubjid FROM sdtm.cm;

  TITLE1 "Subjects with an AE, a concomitant medication, or both";
  SELECT "AE or CM (UNION)"       AS question LENGTH=30,
         COUNT(*) AS subjects
    FROM (SELECT usubjid FROM ae_subj UNION SELECT usubjid FROM cm_subj)
  OUTER UNION CORRESPONDING
  SELECT "AE and CM (INTERSECT)"  AS question,
         COUNT(*) AS subjects
    FROM (SELECT usubjid FROM ae_subj INTERSECT SELECT usubjid FROM cm_subj)
  OUTER UNION CORRESPONDING
  SELECT "AE but no CM (EXCEPT)"  AS question,
         COUNT(*) AS subjects
    FROM (SELECT usubjid FROM ae_subj EXCEPT SELECT usubjid FROM cm_subj);
QUIT;
TITLE;
