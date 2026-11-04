/* Chapter 2: three NOTEs a log check must catch */
/* EXPECT: NOTE Character values have been converted to numeric */
/* EXPECT: NOTE Variable height is uninitialized */
/* EXPECT: NOTE Variable weight is uninitialized */
/* EXPECT: NOTE Missing values were generated */
DATA log_demo;
  SET dm_rand(OBS=3);
  age_months = age * 12;
  siteid_num = siteid + 0;
  bmi        = weight / height**2;
RUN;
