/* Chapter 2: write a CSV file, then read it back with INFILE (needs WINDOWS from 02_read_1) */
FILENAME wincsv "%SYSGET(HOME)/sasbook/windows.csv";

/* write: one header line, then one line per record, values separated by commas */
DATA _NULL_;
  SET windows;
  FILE wincsv DSD;
  IF _N_ = 1 THEN PUT "avisit,avisitn,awlo,awtarget,awhi";
  PUT avisit avisitn awlo awtarget awhi;
RUN;

/* read: DSD splits at the commas, FIRSTOBS=2 skips the header line */
DATA windows_csv;
  LENGTH avisit $8;
  INFILE wincsv DSD FIRSTOBS=2 TRUNCOVER;
  INPUT avisit $ avisitn awlo awtarget awhi;
RUN;

FILENAME wincsv CLEAR;
