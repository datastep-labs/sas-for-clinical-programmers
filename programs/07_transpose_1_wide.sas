/* Chapter 7: long to wide, one record per subject */
PROC TRANSPOSE DATA=sdtm.vs(WHERE=(vsblfl = "Y" AND vstestcd IN ("SYSBP" "DIABP" "PULSE")
                                   AND vstpt = "AFTER LYING DOWN FOR 5 MINUTES"))
               OUT=vswide(DROP=_name_ _label_) SUFFIX=bl;
  BY usubjid;
  ID vstestcd;
  VAR vsstresn;
RUN;

PROC PRINT DATA=vswide(OBS=3) NOOBS; RUN;
