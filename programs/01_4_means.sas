/* Chapter 1: summary statistics per arm */
PROC MEANS DATA=refadm.adsl N MEAN STD MIN MAX MAXDEC=1;
  CLASS arm;
  VAR age;
RUN;
