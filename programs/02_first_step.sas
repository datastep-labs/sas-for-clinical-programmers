/* Chapter 2: your first DATA step */
DATA dm_rand;
  SET sdtm.dm(KEEP=usubjid siteid age sex race armcd arm rfstdtc rfendtc);
  WHERE armcd NE "Scrnfail";
RUN;
