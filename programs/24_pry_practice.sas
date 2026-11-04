/* Chapter 24: a macro to practise %pry, one subset per severity */
%MACRO by_sev(data=refadm.adae, sevs=MILD MODERATE SEVERE);
  %LOCAL i sev nsub;
  %DO i = 1 %TO %SYSFUNC(COUNTW(&sevs., %STR( )));
    %LET sev = %SCAN(&sevs., &i., %STR( ));
    DATA _sev;
      SET &data.;
      WHERE trtemfl = "Y" AND aesev = "&sev.";
    RUN;
    /* replace this comment with %pry(when=&i. = 3) to stop here */
    PROC SQL NOPRINT;
      SELECT COUNT(DISTINCT usubjid) INTO :nsub TRIMMED FROM _sev;
    QUIT;
    %PUT NOTE: &sev.: &nsub. subjects with a treatment-emergent AE;
  %END;
%MEND by_sev;

%by_sev()
