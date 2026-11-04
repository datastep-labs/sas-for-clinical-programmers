/* Chapter 14: the demographics table as an RTF file and a PDF file (needs DM_ROWS and DM_BIGN from 13_4) */

/* Step 010: one column per treatment, as in step 010 of %m_report */
PROC SORT DATA=dm_rows OUT=rtf_010; BY ord sub label; RUN;
PROC TRANSPOSE DATA=rtf_010 OUT=rtf_dm(DROP=_name_) PREFIX=c;
  BY ord sub label;
  ID col;
  VAR value;
RUN;

/* Step 020: the big N of each column as a macro variable: n0, n54, n81 */
DATA _NULL_;
  SET dm_bign;
  CALL SYMPUTX(CATS("n", col), bign);
RUN;

/* Step 030: the output files. The FILENAME tells the log where they are */
/* The output folder: the folder of the program if SAS may write there (DataStep Studio runs */
/* a program in its own folder and brings the files back), else your SAS home folder.        */
DATA _NULL_;
  LENGTH outdir $256;
  rc  = FILENAME("_probe", "_probe.txt");
  fid = FOPEN("_probe", "o");
  IF fid > 0 THEN DO;
    outdir = ".";
    rc = FCLOSE(fid);
    rc = FDELETE("_probe");
  END;
  ELSE outdir = SYSGET("HOME");
  rc = FILENAME("_probe");
  CALL SYMPUTX("outdir", outdir);
RUN;
FILENAME rtfout "&outdir./t_14_1_1_demog.rtf";
FILENAME pdfout "&outdir./t_14_1_1_demog.pdf";
%PUT NOTE: RTF file: %SYSFUNC(PATHNAME(rtfout));

/* Step 040: titles, footnotes and page x of y. ^ starts an ODS escape */
/* landscape with 1 inch margins: 11 - 2 = 9 inches for the table */
OPTIONS NODATE NONUMBER ORIENTATION=LANDSCAPE LEFTMARGIN=1IN RIGHTMARGIN=1IN TOPMARGIN=1IN BOTTOMMARGIN=1IN;
ODS ESCAPECHAR="^";
TITLE1    J=L "CDISCPILOT01" J=R "Page ^{thispage} of ^{lastpage}";
TITLE2    J=C "Table 14.1.1 Demographics";
TITLE3    J=C "Safety population";
FOOTNOTE1 J=L "N = subjects in the safety population. n (%) = subjects in the category, percent of N.";
FOOTNOTE2 J=L "Program: 14_3_rtf_demog.sas";

/* Step 050: one PROC REPORT, two files */
ODS LISTING CLOSE;
ODS RTF FILE=rtfout STYLE=Journal;
ODS PDF FILE=pdfout STYLE=Journal;
PROC REPORT DATA=rtf_dm NOWD SPLIT="|" MISSING
            STYLE(report)=[font_face="Courier New" font_size=9pt]
            STYLE(header)=[font_face="Courier New" font_size=9pt just=c]
            STYLE(column)=[font_face="Courier New" font_size=9pt];
  COLUMN ord sub label ("Treatment" c0 c54 c81);
  DEFINE ord   / ORDER NOPRINT;
  DEFINE sub   / ORDER NOPRINT;
  DEFINE label / DISPLAY " " STYLE(column)=[cellwidth=3.2in asis=on just=l];
  DEFINE c0    / DISPLAY "Placebo|(N=&n0.)"              STYLE(column)=[cellwidth=1.75in just=c];
  DEFINE c54   / DISPLAY "Xanomeline Low Dose|(N=&n54.)"  STYLE(column)=[cellwidth=1.75in just=c];
  DEFINE c81   / DISPLAY "Xanomeline High Dose|(N=&n81.)" STYLE(column)=[cellwidth=1.75in just=c];
  /* the widths add up to 3.2 + 3 x 1.75 = 8.45 inches: less than the 9 inches of the page */
  /* the heading line of each section in bold */
  COMPUTE label;
    IF sub = 0 THEN CALL DEFINE(_COL_, "style", "style=[font_weight=bold]");
  ENDCOMP;
  /* an empty line after each section */
  COMPUTE AFTER ord;
    LINE " ";
  ENDCOMP;
RUN;
ODS PDF CLOSE;
ODS RTF CLOSE;
ODS LISTING;
TITLE;
FOOTNOTE;
