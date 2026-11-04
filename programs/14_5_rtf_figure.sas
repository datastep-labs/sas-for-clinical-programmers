/* Chapter 14: the weight figure as an RTF file and a PDF file (needs CHG_PLOT from 14_2) */

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
FILENAME rtfout "&outdir./f_14_2_1_weight.rtf";
FILENAME pdfout "&outdir./f_14_2_1_weight.pdf";
%PUT NOTE: RTF file: %SYSFUNC(PATHNAME(rtfout));

OPTIONS NODATE NONUMBER ORIENTATION=LANDSCAPE LEFTMARGIN=1IN RIGHTMARGIN=1IN TOPMARGIN=1IN BOTTOMMARGIN=1IN;
ODS ESCAPECHAR="^";
TITLE1    J=L "CDISCPILOT01" J=R "Page ^{thispage} of ^{lastpage}";
TITLE2    J=C "Figure 14.2.1 Mean change from baseline in weight (kg)";
TITLE3    J=C "Safety population, mean and standard error";
FOOTNOTE1 J=L "Program: 14_5_rtf_figure.sas";

/* NOGTITLE NOGFOOTNOTE: the titles stay text on the page, not part of the picture, so Page x of y works. */
/* BODYTITLE: in RTF the titles go into the page above the graph, not into the page header.             */
ODS LISTING CLOSE;
ODS GRAPHICS ON / WIDTH=22CM HEIGHT=11CM;
ODS RTF FILE=rtfout STYLE=Journal BODYTITLE NOGTITLE NOGFOOTNOTE;
ODS PDF FILE=pdfout STYLE=Journal NOGTITLE NOGFOOTNOTE;
PROC SGPLOT DATA=chg_plot NOAUTOLEGEND;
  SERIES  X=avisitn Y=mean / GROUP=trtp MARKERS NAME="lines";
  SCATTER X=avisitn Y=mean / GROUP=trtp YERRORLOWER=lo YERRORUPPER=hi;
  REFLINE 0 / AXIS=Y;
  XAXIS LABEL="Week" VALUES=(2 4 6 8 12 16 20 24 26);
  YAXIS LABEL="Change from baseline (kg)";
  KEYLEGEND "lines" / TITLE="";
RUN;
ODS PDF CLOSE;
ODS RTF CLOSE;
ODS LISTING;
TITLE;
FOOTNOTE;
