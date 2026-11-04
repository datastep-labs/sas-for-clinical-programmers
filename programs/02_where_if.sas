/* Chapter 2: WHERE selects records before they enter the step, a subsetting IF after */
DATA old_where;
  SET refadm.adsl(KEEP=usubjid age);
  WHERE age > 80;
RUN;

DATA old_if;
  SET refadm.adsl(KEEP=usubjid age);
  IF age > 80;
RUN;

/* only a subsetting IF can test a variable that the step creates */
DATA old_months;
  SET refadm.adsl(KEEP=usubjid age);
  age_months = age * 12;
  IF age_months > 960;
RUN;
