/* Chapter 6: ask SAS about your data */
PROC SQL;
  SELECT name, type, length, label
    FROM dictionary.columns
    WHERE libname = "REFADM" AND memname = "ADSL" AND name LIKE "TRT%";
QUIT;

PROC SQL NOPRINT;
  CREATE TABLE flags AS
    SELECT name, varnum
      FROM dictionary.columns
      WHERE libname = "REFADM" AND memname = "ADSL" AND name LIKE '%FL'
      ORDER BY varnum;
  SELECT name INTO :flvars SEPARATED BY " "
    FROM flags;
QUIT;

%PUT NOTE: &=flvars.;
