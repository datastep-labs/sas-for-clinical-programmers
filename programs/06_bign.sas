/* Chapter 6: big N per treatment into macro variables */
PROC SQL NOPRINT;
  SELECT trt01an, COUNT(DISTINCT usubjid)
    INTO :trt1-:trt3, :n1-:n3
    FROM refadm.adsl
    WHERE saffl = "Y"
    GROUP BY trt01an;
QUIT;

%PUT NOTE: &=trt1. &=n1. &=trt2. &=n2. &=trt3. &=n3.;
