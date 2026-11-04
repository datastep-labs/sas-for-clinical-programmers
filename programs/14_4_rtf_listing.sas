/* Chapter 14: the listing of serious adverse events as an RTF file and a PDF file (needs SAE from 14_1) */

/* Step 010: a page variable, a new page for each treatment, and a counter for the total line */
DATA rtf_sae;
  SET sae;
  BY trtan;
  RETAIN pg 0;
  IF FIRST.trtan THEN pg + 1;
  one = 1;
RUN;

/* Step 020: the output files */
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
FILENAME rtfout "&outdir./l_16_2_7_sae.rtf";
FILENAME pdfout "&outdir./l_16_2_7_sae.pdf";
%PUT NOTE: RTF file: %SYSFUNC(PATHNAME(rtfout));

/* Step 030: titles and footnotes, page x of y */
/* landscape with 1 inch margins: 9 inches for the listing */
OPTIONS NODATE NONUMBER ORIENTATION=LANDSCAPE LEFTMARGIN=1IN RIGHTMARGIN=1IN TOPMARGIN=1IN BOTTOMMARGIN=1IN;
ODS ESCAPECHAR="^";
TITLE1    J=L "CDISCPILOT01" J=R "Page ^{thispage} of ^{lastpage}";
TITLE2    J=C "Listing 16.2.7 Serious adverse events";
TITLE3    J=C "Safety population";
FOOTNOTE1 J=L "Start and end are the analysis dates ASTDT and AENDT. An empty end date: the event had not ended.";
FOOTNOTE2 J=L "Program: 14_4_rtf_listing.sas";

/* Step 040: the report */
ODS LISTING CLOSE;
ODS RTF FILE=rtfout STYLE=Journal;
ODS PDF FILE=pdfout STYLE=Journal;
PROC REPORT DATA=rtf_sae NOWD SPLIT="|" MISSING
            STYLE(report)=[font_face="Courier New" font_size=9pt]
            STYLE(header)=[font_face="Courier New" font_size=9pt just=l]
            STYLE(column)=[font_face="Courier New" font_size=9pt];
  COLUMN pg trtan trta usubjid aedecod astdt aendt aesev aeout one;
  DEFINE pg      / ORDER NOPRINT;
  DEFINE trtan   / ORDER NOPRINT;
  DEFINE trta    / ORDER   "Treatment"      STYLE(column)=[cellwidth=1.6in];
  DEFINE usubjid / ORDER   "Subject"        STYLE(column)=[cellwidth=1.0in];
  DEFINE aedecod / DISPLAY "Preferred term" STYLE(column)=[cellwidth=2.0in];
  DEFINE astdt   / DISPLAY "Start"          FORMAT=DATE9. STYLE(column)=[cellwidth=0.85in];
  DEFINE aendt   / DISPLAY "End"            FORMAT=DATE9. STYLE(column)=[cellwidth=0.85in];
  DEFINE aesev   / DISPLAY "Severity"       STYLE(column)=[cellwidth=0.75in];
  DEFINE aeout   / DISPLAY "Outcome"        STYLE(column)=[cellwidth=1.5in];
  DEFINE one     / ANALYSIS SUM NOPRINT;
  /* the widths add up to 8.55 inches: less than the 9 inches of the page */
  /* a new page for each value of pg */
  BREAK AFTER pg / PAGE;
  /* an empty line after each subject */
  COMPUTE AFTER usubjid;
    LINE " ";
  ENDCOMP;
  /* one line at the end of the report: the number of events listed */
  COMPUTE AFTER;
    LINE "Number of serious adverse events listed: " one.sum 3.;
  ENDCOMP;
RUN;
ODS PDF CLOSE;
ODS RTF CLOSE;
ODS LISTING;
TITLE;
FOOTNOTE;
