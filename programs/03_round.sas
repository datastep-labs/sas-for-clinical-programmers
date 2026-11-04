/* EXPECT: NOTE Missing values were generated */
/* Chapter 3: numbers. Two traps: decimal fractions, and + with a missing value */
DATA num;
  x           = 0.1 * 3;
  equal_raw   = (x = 0.3);
  equal_round = (ROUND(x, 1E-9) = 0.3);
  mean        = 147.32;
  mean_1      = ROUND(mean, 0.1);
  up          = ROUND(2.5);
  down        = ROUND(-2.5);
  p           = .;
  q           = 4;
  plus        = p + q;
  total       = SUM(p, q);
  PUTLOG x= equal_raw= equal_round= mean_1= up= down= plus= total=;
RUN;
