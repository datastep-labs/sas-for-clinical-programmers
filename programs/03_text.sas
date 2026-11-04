/* Chapter 3: clean text before you sort, merge or print it */
DATA text;
  LENGTH raw clean1 clean2 $40;
  raw    = "  Mild headache" || '0D0A'x || "after dosing ";
  clean1 = COMPRESS(raw, '0D0A'x);
  clean2 = COMPBL(STRIP(TRANSLATE(raw, "  ", '0D0A'x)));
  len_raw    = LENGTH(raw);
  len_clean2 = LENGTH(clean2);
  upper      = UPCASE(clean2);
  first8     = SUBSTR(clean2, 1, 8);
RUN;

PROC PRINT DATA=text NOOBS; VAR clean2 len_raw len_clean2 upper first8; RUN;
