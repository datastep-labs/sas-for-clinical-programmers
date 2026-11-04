/* Book setup: download the CDISC pilot study once and assign two libraries */
%LET book = %SYSGET(HOME)/sasbook;
%LET src  = https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data;

OPTIONS DLCREATEDIR;
/* DLCREATEDIR creates one folder level only, so create the parent first */
LIBNAME book "&book.";
LIBNAME sdtm   "&book./sdtm";
LIBNAME refadm "&book./refadam";
LIBNAME xptdir "&book./xpt";
LIBNAME xptdir CLEAR;
LIBNAME book CLEAR;

%MACRO getxpt(kind, mem, lib);
  %LOCAL xpt;
  %LET xpt = &book./xpt/&mem..xpt;
  %IF NOT %SYSFUNC(FILEEXIST(&xpt.)) %THEN %DO;
    FILENAME dl "&xpt.";
    PROC HTTP URL="&src./&kind./cdiscpilot01/&mem..xpt" METHOD="GET" OUT=dl; RUN;
    FILENAME dl CLEAR;
  %END;
  LIBNAME inxpt XPORT "&xpt.";
  PROC COPY IN=inxpt OUT=&lib. MEMTYPE=DATA; RUN;
  LIBNAME inxpt CLEAR;
%MEND getxpt;

%MACRO getall;
  %LOCAL i m;
  %LET sdtmlist = dm ae cm ds ex lb mh sv vs suppdm;
  %LET adamlist = adsl adae adlbc advs adtte;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&sdtmlist.));
    %LET m = %SCAN(&sdtmlist., &i.);
    %getxpt(sdtm, &m., sdtm)
  %END;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&adamlist.));
    %LET m = %SCAN(&adamlist., &i.);
    %getxpt(adam, &m., refadm)
  %END;
%MEND getall;
%getall
