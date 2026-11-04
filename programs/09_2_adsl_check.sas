/* Chapter 9: look at the data before you change a rule */
PROC PRINT DATA=sdtm.ex NOOBS;
  WHERE usubjid IN ("01-704-1233" "01-705-1018");
  VAR usubjid exseq extrt exstdtc exendtc;
RUN;
