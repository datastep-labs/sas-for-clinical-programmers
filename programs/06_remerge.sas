/* EXPECT: NOTE The query requires remerging summary statistics back with the original data */
/* Chapter 6: a summary next to detail rows makes SAS remerge */
PROC SQL;
  CREATE TABLE remerge AS
    SELECT usubjid, age, MEAN(age) AS mean_age
      FROM refadm.adsl;
QUIT;
