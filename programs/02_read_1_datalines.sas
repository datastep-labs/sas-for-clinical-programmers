/* Chapter 2: data written in the program. The analysis windows of chapter 10.3 */
DATA windows;
  LENGTH avisit $8;
  INPUT avisitn awlo awtarget awhi;
  avisit = CATX(" ", "Week", avisitn);
  DATALINES;
 2   2  15  21
 4  22  29  35
 6  36  43  49
 8  50  57  70
12  71  85  98
16  99 113 126
20 127 141 154
24 155 169 175
26 176 183   .
;
RUN;

PROC PRINT DATA=windows NOOBS;
RUN;
