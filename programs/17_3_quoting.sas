/* Chapter 17: quoting functions protect special characters */
%LET code = %STR(TITLE "Demography"; FOOTNOTE "Safety population";);
%PUT NOTE: &=code.;

%LET amp = %NRSTR(R&D department);
%PUT NOTE: &=amp.;

DATA _NULL_;
  CALL SYMPUTX("site", "O'Brien Clinic");
RUN;

%MACRO show(text);
  %PUT NOTE: show received [&text.];
%MEND show;

%show(%BQUOTE(&site.))
%PUT NOTE: SUPERQ gives %SUPERQ(site);
