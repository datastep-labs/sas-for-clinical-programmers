/* Study setup: the study-level macro variables that programs and study macros use as defaults.   */
/* Run it once per session, after 00_libs.sas. Change a value here, and every macro that uses it  */
/* as a default follows. Chapter 19.6 explains the idea (design rule 5).                          */
%LET study    = CDISCPILOT01;
%LET saf_cond = saffl = "Y";
%LET itt_cond = ittfl = "Y";
%LET trt      = trt01an;
%LET arms     = 0 54 81;
%LET ref_arm  = 0;

%PUT NOTE: [STUDY] &study.: safety population &saf_cond., treatment &trt. (&arms.), reference arm &ref_arm..;
